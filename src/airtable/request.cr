require "http/headers"
require "http/params"

module Airtable
  class Request
    {% for method in ["get", "post", "put", "patch", "delete"] %}
      private def self.{{method.id}}_api(uri : URI, headers : HTTP::Headers, data : String|Nil = nil)
        Airtable.debug {{method}}, uri.to_s, data
        unless data.nil?
          headers.add("Content-Type", "application/json")
          response = HTTP::Client.{{method.id}}(uri.to_s, headers, data.as(String))
        else
          response = HTTP::Client.{{method.id}}(uri.to_s, headers)
        end
        if response.status_code == 404
          raise RecordNotFound.new
        end
        Airtable.debug response.body
        return response.body
      end
    {% end %}

    def self.list(table : String, source : DataSource = :cache, **api_params)
      api_params_hash = {} of String => String
      api_params.map { |k, v| api_params_hash[k.to_s] = v.to_s }
      api_params_hash["maxRecords"] = "20" unless api_params.has_key?("maxRecords")
      api_params_hash["view"] = "Grid view" unless api_params.has_key?("view")

      uri = Airtable.config.base_uri.dup
      uri.path += table
      uri.query = HTTP::Params.encode(api_params_hash)

      channel = Channel(String).new

      if source.cache?
        spawn do
          json = Airtable.config.cache.get(uri.to_s)
          if json.nil? && !source.backend? # if all, api is called in other fiber below
            begin
              json = self.get_api(uri, Airtable.config.headers)
            rescue RecordNotFound
              # If not found, don't add to cache but return to channel straight away
              channel.send(%{{"records": []}})
            end
            Airtable.config.cache.set(uri.to_s, json.to_s)
          end
          unless json.nil?
            Airtable.config.cache.refresh(uri.to_s)
            channel.send(json)
          end
        end
      end

      if source.backend?
        spawn do
          json = self.get_api(uri, Airtable.config.headers)
          Airtable.config.cache.set(uri.to_s, json.to_s)
          channel.send(json)
        end
      end

      json = channel.receive
      return json
    end

    def self.show(table : String, id : String, source : DataSource = :cache)
      uri = Airtable.config.base_uri.dup
      uri.path += "%s/%s" % [table, id]

      channel = Channel(String).new

      if source.cache?
        spawn do
          json = Airtable.config.cache.get(uri.to_s)
          if json.nil? && !source.backend? # if all, api is called in other fiber below
            begin
              json = self.get_api(uri, Airtable.config.headers)
            rescue RecordNotFound
              # If not found, don't add to cache but return to channel straight away
              channel.send(%{{"records": []}})
            end
            Airtable.config.cache.set(uri.to_s, json.to_s)
          end
          unless json.nil?
            Airtable.config.cache.refresh(uri.to_s)
            channel.send(json)
          end
        end
      end

      if source.backend?
        spawn do
          json = self.get_api(uri, Airtable.config.headers)
          Airtable.config.cache.set(uri.to_s, json.to_s)
          channel.send(json)
        end
      end

      return channel.receive
    end

    def self.create(table : String, data : String)
      uri = Airtable.config.base_uri.dup
      uri.path += table

      json = self.post_api(uri, Airtable.config.headers, data)
      return json
    end

    # update a single record
    def self.update(table : String, id : String, data : String)
      uri = Airtable.config.base_uri.dup
      uri.path += "%s/%s" % [table, id]
      json = self.patch_api(uri, Airtable.config.headers, data)
      Airtable.config.cache.set(uri.to_s, json.to_s)
      return json
    end

    # update a list of records
    def self.update(table : String, data : String)
      uri = Airtable.config.base_uri.dup
      uri.path += table
      json = self.patch_api(uri, Airtable.config.headers, data)
      Airtable.config.cache.set(uri.to_s, json.to_s)
      return json
    end
  end
end
