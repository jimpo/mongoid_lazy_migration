require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)

require 'mongoid'

HOST = ENV['MONGOID_SPEC_HOST'] || 'localhost'
PORT = ENV['MONGOID_SPEC_PORT'] || '27017'
DATABASE = 'mongoid_lazy_migration_test'

Mongoid.configure do |config|
  config.load_configuration(
    sessions: {
      default: {
        database: DATABASE,
        hosts: ["#{HOST}:#{PORT}"]
      }
    }
  )
end

RSpec.configure do |config|
  config.before(:each) do
    Mongoid.purge!
  end
end
