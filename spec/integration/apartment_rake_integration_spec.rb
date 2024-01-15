require 'spec_helper'
require 'rake'

describe "apartment rake tasks" do

  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    Dummy::Application.load_tasks

    load "rails/tasks/misc.rake"
  end

  after do
    Rake.application = nil
  end

  before do
    Apartment.configure do |config|
      config.excluded_models = ["Company"]
      config.database_names = lambda{ Company.all.collect(&:database) }
    end

    Company.table_name = 'public.companies'
  end

  context "with x number of databases" do

    let(:x){ 1 + rand(5) }    
    let(:db_names){ x.times.map{ Apartment::Test.next_db } }
    let!(:company_count){ Company.count + db_names.length }

    before do
      db_names.collect do |db_name|
        Apartment::Database.create(db_name)
        Company.create(database: db_name)
      end
    end

    after do
      db_names.each{ |db| Apartment::Database.drop(db) }
      Company.delete_all
    end

    describe "#migrate" do
      it "should migrate all databases" do
        expect(Apartment::Migrator).to receive(:migrate).exactly(company_count).times

        @rake['apartment:migrate'].invoke
      end
    end

    describe "#rollback" do
      it "should rollback all dbs" do
        db_names.each do |name|
          expect(Apartment::Migrator).to receive(:rollback).with(name, anything)
        end

        @rake['apartment:rollback'].invoke
        @rake['apartment:migrate'].invoke
      end
    end

    describe "apartment:seed" do
      it "should seed all databases" do
        expect(Apartment::Database).to receive(:seed).exactly(company_count).times

        @rake['apartment:seed'].invoke
      end
    end

  end
end