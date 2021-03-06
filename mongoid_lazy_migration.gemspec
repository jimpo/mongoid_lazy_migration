# encoding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)

require 'mongoid/lazy_migration/version'

Gem::Specification.new do |s|
  s.name        = "mongoid_lazy_migration"
  s.version     =  Mongoid::LazyMigration::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nicolas Viennot"]
  s.email       = ["nicolas@viennot.biz"]
  s.homepage    = "http://github.com/nviennot/mongoid_lazy_migration"
  s.summary     = "Mongoid lazy migration toolkit"
  s.description = "Migrate your documents lazily in atomic, or locked fashion to avoid downtime"

  s.add_dependency("mongoid", "~> 5.0")
  s.add_dependency("activesupport", "~> 4.0")
  s.add_dependency("ruby-progressbar", "~> 1.5")

  s.files        = Dir["lib/**/*"] + ['README.md']
  s.require_path = 'lib'
  s.has_rdoc     = false
end
