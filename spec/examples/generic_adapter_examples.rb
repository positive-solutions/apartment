require 'spec_helper'

shared_examples_for "a generic apartment adapter" do
  include Apartment::Spec::AdapterRequirements

  before {
    Apartment.prepend_environment = false
    Apartment.append_environment = false
  }

  #
  #   Creates happen already in our before_filter
  #
  describe "#create" do

    it "creates the new databases" do
      expect(database_names).to include(db1)
      expect(database_names).to include(db2)
    end

    it "loads schema.rb to new schema" do
      subject.process(db1) do
        expect(connection.tables).to include('companies')
      end
    end

    it "should yield to block if passed and reset" do
      subject.drop(db2) # so we don't get errors on creation

      @count = 0  # set our variable so its visible in and outside of blocks

      subject.create(db2) do
        @count = User.count
        expect(subject.current_database).to eq(db2)
        User.create
      end

      expect(subject.current_database).not_to eq(db2)

      subject.process(db2){ expect(User.count).to eq(@count + 1) }
    end
    end

    describe "#drop" do
      it "should remove the db" do
        subject.drop db1
        expect(database_names).not_to include(db1)
      end
    end

    describe "#process" do
      it "should connect" do
        subject.process(db1) do
          expect(subject.current_database).to eq(db1)
        end
      end

      it "should reset" do
        subject.process(db1)
        expect(subject.current_database).to eq(default_database)
      end

      it "should not throw exception if current_database is no longer accessible" do
        subject.switch(db2)

        expect {
          subject.process(db1){ subject.drop(db2) }
        }.not_to raise_error
      end
    end

    describe "#reset" do
      it "should reset connection" do
        subject.switch(db1)
        subject.reset
        expect(subject.current_database).to eq(default_database)
      end
    end

    describe "#switch" do
      it "should connect to new db" do
        subject.switch(db1)
        expect(subject.current_database).to eq(db1)
      end

      it "should reset connection if database is nil" do
        subject.switch
        expect(subject.current_database).to eq(default_database)
      end

      it "should raise an error if database is invalid" do
        expect {
          subject.switch 'unknown_database'
        }.to raise_error(Apartment::ApartmentError)
      end
    end

    describe "#current_database" do
      it "should return the current db name" do
        subject.switch(db1)
        expect(subject.current_database).to eq(db1)
        expect(subject.current).to eq(db1)
      end
    end
end