if defined?(ActiveRecord)
  class ActiveRecord::Base
    # @override
    # serialize to YAML
    def encode_with(coder)
      coder["attributes"] = @attributes
      coder["database"] =   @database unless @database.nil?
      coder.tag = ['!ruby/ActiveRecord', self.class.name].join(':')
    end
  end
end

# TODO (Shay Rubinshtein): I'm not even sure that this monkey patch is needed.
# I really have no idea what it does - I just went ahead modernized the original patch
module Psych
  module Visitors
    class ToRuby
      module ClassAndDb
        def visit_Mapping(object)
          case object.tag
          when /^!ruby\/ActiveRecord:(.+)$/
            klass = resolve_class($1)
            payload = Hash[*object.children.map { |c| accept c }]
            id = payload["attributes"][klass.primary_key]
            begin
              Apartment::Database.process(payload['database']) do
                klass.unscoped.find(id)
              end
            rescue ActiveRecord::RecordNotFound
              raise Delayed::DeserializationError
            end
          when /^!ruby\/Mongoid:(.+)$/
            klass = resolve_class($1)
            payload = Hash[*object.children.map { |c| accept c }]
            begin
              klass.find(payload["attributes"]["_id"])
            rescue Mongoid::Errors::DocumentNotFound
              raise Delayed::DeserializationError
            end
          when /^!ruby\/DataMapper:(.+)$/
            klass = resolve_class($1)
            payload = Hash[*object.children.map { |c| accept c }]
            begin
              primary_keys = klass.properties.select { |p| p.key? }
              key_names = primary_keys.map { |p| p.name.to_s }
              klass.get!(*key_names.map { |k| payload["attributes"][k] })
            rescue DataMapper::ObjectNotFoundError
              raise Delayed::DeserializationError
            end
          else
            super
          end
        end
      end

      prepend ClassAndDb
    end
  end
end