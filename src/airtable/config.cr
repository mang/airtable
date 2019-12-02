require "uri"
require "cache_hash"

module Airtable
  class Config
    INSTANCE = Config.new

    property base_uri = URI.new("https", "api.airtable.com"),
      cache = CacheHash(String).new(30.days),
      api_key : String?,
      base_name : String?,
      api_version = "v0",
      debug = ENV["DEBUG"]?

    def headers
      HTTP::Headers{
        "Accept"        => "application/json",
        "Authorization" => "Bearer %s" % @api_key,
      }
    end

    def api_key=(@api_key)
      @api_key
    end

    def base_uri
      @base_uri.path = "%s/%s/" % [@api_version, @base_name]
      @base_uri
    end
  end

  def self.config
    yield Config::INSTANCE
  end

  def self.config
    Config::INSTANCE
  end

  def self.debug(*messages)
    if Airtable.config.debug
      messages.each_with_index do |message, i|
        if i == 0
          print "=== Airtable ==> "
        else
          print "--- Airtable --> "
        end
        pp message
      end
    end
  end
end
