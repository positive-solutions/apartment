require 'spec_helper'

describe Apartment::Database do
  context "using postgresql" do

    # See apartment.yml file in dummy app config

    let(:config){ Apartment::Test.config['connections']['postgresql'].symbolize_keys }
    let(:database){ Apartment::Test.next_db }
    let(:database2){ Apartment::Test.next_db }

    before do
      Apartment.use_schemas = true
      ActiveRecord::Base.establish_connection config
      Apartment::Test.load_schema   # load the Rails schema in the public db schema
      allow(subject).to receive(:config).and_return config   # Use postgresql database config for this test
    end

    describe "#adapter" do
      before do
        subject.reload!
      end

      it "should load postgresql adapter" do
        subject.adapter
        expect(Apartment::Adapters::PostgresqlAdapter).to be_a(Class)
      end

      it "should raise exception with invalid adapter specified" do
        allow(subject).to receive(:config).and_return config.merge(:adapter => 'unknown')

        expect {
          Apartment::Database.adapter
        }.to raise_error
      end

      context "threadsafety" do
        before { subject.create database }

        it 'has a threadsafe adapter' do
          subject.switch(database)
          thread = Thread.new { expect(subject.current_database).to eq(Apartment.default_schema) }
          thread.join
          expect(subject.current_database).to eq(database)
        end
      end
    end

    context "with schemas" do

      before do
        Apartment.configure do |config|
          config.excluded_models = []
          config.use_schemas = true
          config.seed_after_create = true
        end
        subject.create database
      end

      after{ subject.drop database }

      describe "#create" do
        it "should seed data" do
          subject.switch database
          expect(User.count).to be > 0
        end
      end

      describe "#switch" do

        let(:x){ rand(3) }

        context "creating models" do

          before{ subject.create database2 }
          after{ subject.drop database2 }

          it "should create a model instance in the current schema" do
            subject.switch database2
            db2_count = User.count + x.times{ User.create }

            subject.switch database
            db_count = User.count + x.times{ User.create }

            subject.switch database2
            expect(User.count).to eq(db2_count)

            subject.switch database
            expect(User.count).to eq(db_count)
          end
        end

        context "with excluded models" do

          before do
            Apartment.configure do |config|
              config.excluded_models = ["Company"]
            end
            subject.init
          end

          it "should create excluded models in public schema" do
            subject.reset # ensure we're on public schema
            count = Company.count + x.times{ Company.create }

            subject.switch database
            x.times{ Company.create }
            expect(Company.count).to eq(count + x)
            subject.reset
            expect(Company.count).to eq(count + x)
          end
        end

      end

    end

  end
end