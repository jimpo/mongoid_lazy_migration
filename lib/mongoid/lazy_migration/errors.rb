module Mongoid::LazyMigration
  module Errors
    class CleanupError < StandardError; end

    class AtomicMigrationError < StandardError; end
  end
end
