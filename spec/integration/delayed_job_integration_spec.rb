require 'spec_helper'
require 'delayed_job'
require 'delayed_job_active_record'

describe Apartment::Delayed do
  unless defined?(JRUBY_VERSION)

    # See apartment.yml file in dummy app config

    let(:config) { Apartment::Test.config['connections']['postgresql'].symbolize_keys }
    let(:database) { Apartment::Test.next_db }
    let(:database2) { Apartment::Test.next_db }

    before do
      ActiveRecord::Base.establish_connection config
      Apartment::Test.load_schema   # load the Rails schema in the public db schema
      allow(Apartment::Database).to receive(:config).and_return(config)   # Use postgresql database config for this test

      Apartment.configure do |config|
        config.use_schemas = true
      end

      Apartment::Database.create database
      Apartment::Database.create database2
    end

    after do
      Apartment::Test.drop_schema database
      Apartment::Test.drop_schema database2
      Apartment.reset
    end

    describe Apartment::Delayed::Requirements do

      before do
        Apartment::Database.switch database
        User.send(:include, Apartment::Delayed::Requirements)
        User.create
      end

      it "should initialize a database attribute on a class" do
        user = User.first
        expect(user.database).to eq(database)
      end

      context 'when there are defined callbacks' do
        before do
          User.class_eval do
            after_find :set_name

            def set_name
              self.name = "Some Name"
            end
          end
        end

        after do
          User.class_eval do
            reset_callbacks :find
          end
        end

        it "should not overwrite any previous after_initialize declarations" do
          user = User.first
          expect(user.database).to eq(database)
          expect(user.name).to eq("Some Name")
        end
      end

      it "should set the db on a new record before it saves" do
        user = User.create
        expect(user.database).to eq(database)
      end

      context "serialization" do
        it "should serialize the proper database attribute" do
          user_yaml = User.first.to_yaml
          Apartment::Database.switch database2
          user = YAML.unsafe_load(user_yaml)
          expect(user["database"]).to eq(database)
        end
      end
    end

    describe Apartment::Delayed::Job::Hooks do

      let(:worker) { Delayed::Worker.new }
      let(:job) { Delayed::Job.enqueue User.new }

      it "should switch to previous db" do
        Apartment::Database.switch database
        worker.run(job)

        expect(Apartment::Database.current_database).to eq(database)
      end
    end

  end
end