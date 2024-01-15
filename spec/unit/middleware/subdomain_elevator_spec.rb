require 'spec_helper'

describe Apartment::Elevators::Subdomain do

  describe "#parse_database_name" do
    it "parses subdomain" do
      request = ActionDispatch::Request.new('HTTP_HOST' => 'foo.bar.com')
      elevator = Apartment::Elevators::Subdomain.new(nil)
      expect(elevator.parse_database_name(request)).to eq('foo')
    end

    it "returns nil when no subdomain" do
      request = ActionDispatch::Request.new('HTTP_HOST' => 'bar.com')
      elevator = Apartment::Elevators::Subdomain.new(nil)
      expect(elevator.parse_database_name(request)).to be_nil
    end

  end

end