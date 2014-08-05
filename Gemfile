source 'https://rubygems.org'
gemspec

ENV['MONGOID_VERSION'] ||= "3.0"

group :test do
  gem 'rake'
  gem 'mongoid', "~> #{ENV['MONGOID_VERSION']}"
  gem 'rspec'
  gem 'ruby-progressbar'
  gem 'mocha', :require => false
end
