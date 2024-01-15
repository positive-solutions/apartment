require 'spec_helper'

describe Apartment::Migrator do

  let(:config){ Apartment::Test.config['connections']['postgresql'].symbolize_keys }
  let(:schema_name){ Apartment::Test.next_db }
  let(:version){ 20110613152810 }     # note this is brittle!  I've literally just taken the version of the one migration I made...  don't change this version

  before do
    ActiveRecord::Base.establish_connection config
    allow(Apartment::Database).to receive(:config).and_return config
    @original_schema = ActiveRecord::Base.connection.schema_search_path
    # Necessary because the JDBC adapter returns $user in the search path
    @original_schema.gsub!(/"\$user",/, '') if defined?(JRUBY_VERSION)

    Apartment.configure do |config|
      config.use_schemas = true
      config.excluded_models = []
      config.database_names = [schema_name]
    end

    Apartment::Database.create schema_name
    migrations_path = Rails.root.join(ActiveRecord::Migration.migrations_paths.first)
    allow(ActiveRecord::Migration).to receive(:migrations_paths).and_return([migrations_path])
  end

  after do
    Apartment::Test.drop_schema(schema_name)
  end

  context "postgresql" do

    context "using schemas" do

      describe "#migrate" do
        it "should connect to new db, then reset when done" do
          expect(ActiveRecord::Base.connection).to receive(:schema_search_path=).with(%{"#{schema_name}"}).once
          expect(ActiveRecord::Base.connection).to receive(:schema_search_path=).with(%{"#{@original_schema}"}).once
          Apartment::Migrator.migrate(schema_name)
        end

        it "should migrate db" do
          expect(ActiveRecord::MigrationContext).to receive_message_chain(:new, :migrate)
          Apartment::Migrator.migrate(schema_name)
        end
      end

      describe "#run" do
        context "up" do

          it "should connect to new db, then reset when done" do
            expect(ActiveRecord::Base.connection).to receive(:schema_search_path=).with(%{"#{schema_name}"}).once
            expect(ActiveRecord::Base.connection).to receive(:schema_search_path=).with(%{"#{@original_schema}"}).once
            p version
            Apartment::Migrator.run(:up, schema_name, version)
          end

          it "should migrate to a version" do
            expect(ActiveRecord::MigrationContext).to receive_message_chain(:new, :run).with(:up, version)
            Apartment::Migrator.run(:up, schema_name, version)
          end
        end

        describe "down" do

          it "should connect to new db, then reset when done" do
            expect(ActiveRecord::Base.connection).to receive(:schema_search_path=).with(%{"#{schema_name}"}).once
            expect(ActiveRecord::Base.connection).to receive(:schema_search_path=).with(%{"#{@original_schema}"}).once
            p version
            Apartment::Migrator.run(:down, schema_name, version)
          end

          it "should migrate to a version" do
            expect(ActiveRecord::MigrationContext).to receive_message_chain(:new, :run).with(:down, version)
            Apartment::Migrator.run(:down, schema_name, version)
          end
        end
      end

      describe "#rollback" do
        let(:steps){ 3 }

        it "should rollback the db" do
          expect(ActiveRecord::MigrationContext).to receive_message_chain(:new, :rollback).with(steps)
          Apartment::Migrator.rollback(schema_name, steps)
        end
      end
    end
  end

end