require 'bundler' rescue 'You must `gem install bundler` and `bundle install` to run rake tasks'
Bundler.setup
Bundler::GemHelper.install_tasks

require "rspec"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec => %w{ db:copy_credentials db:test:prepare }) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
  # spec.rspec_opts = '--order rand:16996'
end

namespace :spec do

  [:tasks, :unit, :adapters, :integration].each do |type|
    RSpec::Core::RakeTask.new(type => :spec) do |spec|
      spec.pattern = "spec/#{type}/**/*_spec.rb"
    end
  end

end

task :default => :spec

namespace :db do
  namespace :test do
    task :prepare => %w{postgres:drop_db postgres:build_db}
  end

  desc "copy sample database credential files over if real files don't exist"
  task :copy_credentials do
    require 'fileutils'
    apartment_db_file = 'spec/config/database.yml'
    rails_db_file = 'spec/dummy/config/database.yml'

    FileUtils.copy(apartment_db_file + '.sample', apartment_db_file, :verbose => true) unless File.exists?(apartment_db_file)
    FileUtils.copy(rails_db_file + '.sample', rails_db_file, :verbose => true)         unless File.exists?(rails_db_file)
  end
end

namespace :postgres do
  require 'active_record'
  require "#{File.join(File.dirname(__FILE__), 'spec', 'support', 'config')}"

  desc 'Build the PostgreSQL test databases'
  task :build_db do
    %x{ createdb -E UTF8 #{pg_config['database']} -U#{pg_config['username']} } rescue "test db already exists"
    ActiveRecord::Base.establish_connection pg_config
    ActiveRecord::Migration.migrate('spec/dummy/db/migrate')
  end

  desc "drop the PostgreSQL test database"
  task :drop_db do
    puts "dropping database #{pg_config['database']}"
    %x{ dropdb #{pg_config['database']} -U#{pg_config['username']} }
  end

end

# TODO clean this up
def config
  Apartment::Test.config['connections']
end

def pg_config
  config['postgresql']
end