require 'active_support'
require 'active_support/concern'
require 'active_support/core_ext'
require 'set'

module Mongoid
  module LazyMigration
    require 'mongoid/lazy_migration/version'
    require 'mongoid/lazy_migration/document'
    require 'mongoid/lazy_migration/tasks'
    require 'mongoid/lazy_migration/lock'

    extend ActiveSupport::Concern
    extend Tasks

    mattr_reader :models_to_migrate
    @@models_to_migrate = Set.new

    module ClassMethods
      def migration(options = {}, &block)
        include Mongoid::LazyMigration::Document

        field :migration_state, :type => Symbol
        after_initialize :ensure_migration,
          :unless => -> { @migrating || !__selected_fields.nil? }

        cattr_accessor :migrate_block, :migration_lock
        self.migrate_block = block
        self.migration_lock = options[:lock]
        if migration_lock == true
          # Use Mongoid lock as default lock
          self.migration_lock = ->(document) do
            Mongoid::LazyMigration::Lock.new(document)
          end
        end

        Mongoid::LazyMigration.models_to_migrate << self
      end
    end

  end
end

require "mongoid/lazy_migration/railtie" if defined?(Rails)
