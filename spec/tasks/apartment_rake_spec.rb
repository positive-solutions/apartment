require 'spec_helper'
require 'rake'

describe "apartment rake tasks" do

  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    load 'tasks/apartment.rake'
    # stub out rails tasks
    Rake::Task.define_task('db:migrate')
    Rake::Task.define_task('db:seed')
    Rake::Task.define_task('db:rollback')
    Rake::Task.define_task('db:migrate:up')
    Rake::Task.define_task('db:migrate:down')
    Rake::Task.define_task('db:migrate:redo')
  end

  after do
    Rake.application = nil
    ENV['VERSION'] = nil    # linux users reported env variable carrying on between tests
  end

  let(:version){ '1234' }

  context 'database migration' do

    let(:database_names){ 3.times.map{ Apartment::Test.next_db } }
    let(:db_count){ database_names.length }

    before do
      allow(Apartment).to receive(:database_names).and_return(database_names)
    end

    describe "apartment:migrate" do
      before do
        allow(ActiveRecord::Migrator).to receive(:migrate)   # don't care about this
      end

      it "should migrate public and all multi-tenant dbs" do
        expect(Apartment::Migrator).to receive(:migrate).exactly(db_count).times
        @rake['apartment:migrate'].invoke
      end
    end

    describe "apartment:migrate:up" do

      context "without a version" do
        before do
          ENV['VERSION'] = nil
        end

        it "requires a version to migrate to" do
          expect {
            @rake['apartment:migrate:up'].invoke
          }.to raise_error("VERSION is required")
        end
      end

      context "with version" do

        before do
          ENV['VERSION'] = version
        end

        it "migrates up to a specific version" do
          expect(Apartment::Migrator).to receive(:run).with(:up, anything, version.to_i).exactly(db_count).times
          @rake['apartment:migrate:up'].invoke
        end
      end
    end

    describe "apartment:migrate:down" do

      context "without a version" do
        before do
          ENV['VERSION'] = nil
        end

        it "requires a version to migrate to" do
          expect {
            @rake['apartment:migrate:down'].invoke
          }.to raise_error("VERSION is required")
        end
      end

      context "with version" do

        before do
          ENV['VERSION'] = version
        end

        it "migrates up to a specific version" do
          expect(Apartment::Migrator).to receive(:run).with(:down, anything, version.to_i).exactly(db_count).times
          @rake['apartment:migrate:down'].invoke
        end
      end
    end

    describe "apartment:rollback" do

      let(:step){ '3' }

      it "should rollback dbs" do
        expect(Apartment::Migrator).to receive(:rollback).exactly(db_count).times
        @rake['apartment:rollback'].invoke
      end

      it "should rollback dbs STEP amt" do
        expect(Apartment::Migrator).to receive(:rollback).with(anything, step.to_i).exactly(db_count).times
        ENV['STEP'] = step
        @rake['apartment:rollback'].invoke
      end
    end

  end

end