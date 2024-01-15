require 'spec_helper'
require 'capybara/rspec'

shared_examples_for "an apartment elevator" do

  feature "single request" do
    scenario "should switch the db" do
      expect(ActiveRecord::Base.connection.schema_search_path).not_to eq(%{"#{database1}"})

      visit(domain1)
      expect(ActiveRecord::Base.connection.schema_search_path).to eq(%{"#{database1}"})
    end
  end

  feature "simultaneous requests" do

    let!(:c1_user_count) { api.process(database1){ (2 + rand(2)).times{ User.create } } }
    let!(:c2_user_count) { api.process(database2){ (c1_user_count + 2).times{ User.create } } }

    scenario "should fetch the correct user count for each session based on the elevator processor" do
      Capybara.using_session('user1') do
        visit(domain1)
      end
    
      Capybara.using_session('user2') do
        visit(domain2)
        expect(User.count).to eq(c2_user_count)
      end
    
      Capybara.using_session('user1') do
        visit(domain1)
        expect(User.count).to eq(c1_user_count)
      end
    end
  end
end
