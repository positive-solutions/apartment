module Apartment
  module Migrator
    extend self

    # Migrate to latest
    def migrate(database)
      Database.process(database) do
        ActiveRecord::Base.connection.migration_context.migrate(ENV["VERSION"] ? ENV["VERSION"].to_i : nil) do |migration|
          ENV["SCOPE"].blank? || (ENV["SCOPE"] == migration.scope)
        end
      end
    end

    # Migrate up/down to a specific version
    def run(direction, database, version)
      Database.process(database) do
        if Rails::VERSION::MAJOR >= 7
          ActiveRecord::Base.connection.migration_context.run(direction, version: version)
        else
          ActiveRecord::Base.connection.migration_context.run(direction, version)
        end
      end
    end

    # rollback latest migration `step` number of times
    def rollback(database, step = 1)
      Database.process(database) do
        ActiveRecord::Base.connection.migration_context.rollback(step)
      end
    end
  end
end