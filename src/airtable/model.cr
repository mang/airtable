module Airtable
  abstract class Model
    macro def_wrappers(table)

      class List
        JSON.mapping(
          records: {type: Array({{@type.name}}::Record), default: [] of {{@type.name}}::Record}
        )

        def self.new(**params)
          {{@type.name}}::List.from_json(%(#{params.to_json}))
        end

        # update all records in list.
        # Airtable has a limit of 10 items per request, so if there are more
        # than 10, split it on multiple requests
        def update

          updated_list = {{@type.name}}::List.new

          i = 0
          while i < (self.records.size / 10).ceil
            seq_beginning = (i * 10) + 0
            seq_end = (i * 10) + 9

            split_list = {{@type.name}}::List.from_json(
              %({"records": #{self.records[seq_beginning..seq_end].to_json}})
            )
            json = Airtable::Request.update({{table}}, split_list.to_json)
            result_list = {{@type.name}}::List.from_json(json)

            # merge back all split parts
            updated_list.records += result_list.records

            i += 1
          end

          return updated_list
        end

      end

      class Record
        JSON.mapping(
          id: String?,
          fields: {type: {{@type.name}}, default: {{@type.name}}.new},
          createdTime: Time?
        )

        def self.new(**params)
          {{@type.name}}::Record.from_json(%(#{params.to_json}))
        end

        def save
          @id ? update : create
        end

        def create
          record = {{@type.name}}::Record.from_json(%({"fields": #{self.fields.to_json}}))
          json = Airtable::Request.create({{table}}, record.to_json)
          return {{@type.name}}::Record.from_json(json)
        end

        def update
          record = {{@type.name}}::Record.from_json(%({"fields": #{self.fields.to_json}}))
          json = Airtable::Request.update({{table}}, @id.as(String), record.to_json)
          return {{@type.name}}::Record.from_json(json)
        end

        def self.update(**params)
          record = {{@type.name}}::Record.from_json(%(#{params.to_json}))
          return record.update
        end

        def delete
          return false unless @id
          {{@type.name}}.delete(@id.to_s)
        end

      end

      def self.create(**params)
        record = {{@type.name}}::Record.from_json(%({"fields": #{params.to_json}}))
        return record.create
      end

      def create
        record = {{@type.name}}::Record.from_json(%({"fields": #{self.to_json}}))
        record.create
      end

      def self.list(source : Airtable::DataSource = :cache, **api_params)
        json = Airtable::Request.list({{table}}, source, **api_params)
        return {{@type.name}}::List.from_json(json).records
      end

      def self.show(id, source : Airtable::DataSource = :cache)
        json = Airtable::Request.show({{table}}, id, source)
        return {{@type.name}}::Record.from_json(json)
      end

      def self.delete(id)
        Airtable::Request.delete({{table}}, id)
      end

      def self.new(**params)
        {{@type.name}}.from_json(%(#{params.to_json}))
      end

    end
  end
end
