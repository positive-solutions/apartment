require 'spec_helper'

describe Apartment do

  describe "#config" do

    let(:excluded_models){ [Company] }

    it "yields the Apartment object" do
      Apartment.configure do |config|
        config.excluded_models = []
        expect(config).to eq(Apartment)
      end
    end

    it "sets excluded models" do
      Apartment.configure do |config|
        config.excluded_models = excluded_models
      end
      expect(Apartment.excluded_models).to eq(excluded_models)
    end

    it "sets use_schemas" do
      Apartment.configure do |config|
        config.excluded_models = []
        config.use_schemas = false
      end
      expect(Apartment.use_schemas).to be_falsey
    end

    it "sets seed_after_create" do
      Apartment.configure do |config|
        config.excluded_models = []
        config.seed_after_create = true
      end
      expect(Apartment.seed_after_create).to be_truthy
    end

    context "databases" do
      it "returns object if it doesn't respond_to call" do
        database_names = ['users', 'companies']

        Apartment.configure do |config|
          config.excluded_models = []
          config.database_names = database_names
        end
        expect(Apartment.database_names).to eq(database_names)
      end

      it "should invoke the proc if appropriate" do
        database_names = lambda{ ['users', 'users'] }
        expect(database_names).to receive(:call)

        Apartment.configure do |config|
          config.excluded_models = []
          config.database_names = database_names
        end
        Apartment.database_names
      end

      it "should return the invoked proc if appropriate" do
        dbs = lambda{ Company.all }

        Apartment.configure do |config|
          config.excluded_models = []
          config.database_names = dbs
        end

        expect(Apartment.database_names).to eq(Company.all)
      end
    end

  end
end