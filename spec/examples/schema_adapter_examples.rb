require 'spec_helper'

shared_examples_for "a schema based apartment adapter" do
  include Apartment::Spec::AdapterRequirements

  let(:schema1){ db1 }
  let(:schema2){ db2 }
  let(:public_schema){ default_database }

  describe "#init" do

    before do
      Apartment.configure do |config|
        config.excluded_models = ["Company"]
      end
    end

    it "should process model exclusions" do
      Apartment::Database.init

      expect(Company.table_name).to eq("public.companies")
    end

    context "with a default_schema", :default_schema => true do

      it "should set the proper table_name on excluded_models" do
        Apartment::Database.init

        expect(Company.table_name).to eq("#{default_schema}.companies")
      end
    end
  end

  #
  #   Creates happen already in our before_filter
  #
  describe "#create" do

    it "should load schema.rb to new schema" do
      connection.schema_search_path = schema1
      expect(connection.tables).to include('companies')
    end

    it "should yield to block if passed and reset" do
      subject.drop(schema2) # so we don't get errors on creation

      @count = 0  # set our variable so its visible in and outside of blocks

      subject.create(schema2) do
        @count = User.count
        expect(connection.schema_search_path).to start_with %{"#{schema2}"}
        User.create
      end

      expect(connection.schema_search_path).not_to start_with %{"#{schema2}"}

      subject.process(schema2){ expect(User.count).to eq(@count + 1) }
    end

    context "numeric database names" do
      let(:db) { "1234" }
      it "should allow them" do
        expect {
          subject.create(db)
        }.not_to raise_error
        expect(database_names).to include(db.to_s)
      end

      after{ subject.drop(db) }
    end

  end

  describe "#drop" do
    it "should raise an error for unknown database" do
      expect {
        subject.drop "unknown_database"
      }.to raise_error(Apartment::SchemaNotFound)
    end

    context "numeric database names" do
      let(:db){ "1234" }

      it "should be able to drop them" do
        subject.create(db)
        expect {
          subject.drop(db)
        }.not_to raise_error
        expect(database_names).not_to include(db.to_s)
      end

      after { subject.drop(db) rescue nil }
    end
  end

  describe "#process" do
    it "should connect" do
      subject.process(schema1) do
        expect(connection.schema_search_path).to start_with %{"#{schema1}"}
      end
    end

    it "should reset" do
      subject.process(schema1)
      expect(connection.schema_search_path).to start_with %{"#{public_schema}"}
    end
  end

  describe "#reset" do
    it "should reset connection" do
      subject.switch(schema1)
      subject.reset
      expect(connection.schema_search_path).to start_with %{"#{public_schema}"}
    end

    context "with default_schema", :default_schema => true do
      it "should reset to the default schema" do
        subject.switch(schema1)
        subject.reset
        expect(connection.schema_search_path).to start_with %{"#{default_schema}"}
      end
    end

    context "persistent_schemas", :persistent_schemas => true do
      before do
        subject.switch(schema1)
        subject.reset
      end

      it "maintains the persistent schemas in the schema_search_path" do
        expect(connection.schema_search_path).to end_with persistent_schemas.map { |schema| %{"#{schema}"} }.join(', ')
      end

      context "with default_schema", :default_schema => true do
        it "prioritizes the switched schema to front of schema_search_path" do
          subject.reset # need to re-call this as the default_schema wasn't set at the time that the above reset ran
          expect(connection.schema_search_path).to start_with %{"#{default_schema}"}
        end
      end
    end
  end

  describe "#switch" do
    it "should connect to new schema" do
      subject.switch(schema1)
      expect(connection.schema_search_path).to start_with %{"#{schema1}"}
    end

    it "should reset connection if database is nil" do
      subject.switch
      expect(connection.schema_search_path).to eq %{"#{public_schema}"}
    end

    it "should raise an error if schema is invalid" do
      expect {
        subject.switch 'unknown_schema'
      }.to raise_error(Apartment::SchemaNotFound)
    end

    context "numeric databases" do
      let(:db){ "1234" }

      it "should connect to them" do
        subject.create(db)
        expect {
          subject.switch(db)
        }.not_to raise_error

        expect(connection.schema_search_path).to start_with %{"#{db.to_s}"}
      end

      after{ subject.drop(db) }
    end

    describe "with default_schema specified", :default_schema => true do
      before do
        subject.switch(schema1)
      end

      it "should switch out the default schema rather than public" do
        expect(connection.schema_search_path).not_to include default_schema
      end

      it "should still switch to the switched schema" do
        expect(connection.schema_search_path).to start_with %{"#{schema1}"}
      end
    end

    context "persistent_schemas", :persistent_schemas => true do

      before{ subject.switch(schema1) }

      it "maintains the persistent schemas in the schema_search_path" do
        expect(connection.schema_search_path).to end_with persistent_schemas.map { |schema| %{"#{schema}"} }.join(', ')
      end

      it "prioritizes the switched schema to front of schema_search_path" do
        expect(connection.schema_search_path).to start_with %{"#{schema1}"}
      end
    end
  end

  describe "#current_database" do
    it "should return the current schema name" do
      subject.switch(schema1)
      expect(subject.current_database).to eq schema1
      expect(subject.current).to eq schema1
    end

    context "persistent_schemas", :persistent_schemas => true do
      it "should exlude persistent_schemas" do
        subject.switch(schema1)
        expect(subject.current_database).to eq schema1
        expect(subject.current).to eq schema1
      end
    end
  end
end
