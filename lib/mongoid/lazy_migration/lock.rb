module Mongoid::LazyMigration
  class Lock
    DEFAULT_LOCK_FIELD = "migration_in_progress"
    DEFAULT_SLEEP = 125

    def initialize(
        document, lock_field: DEFAULT_LOCK_FIELD, sleep_in_ms: DEFAULT_SLEEP)
      @document = document
      @lock_field = lock_field
      @owner = rand 1000000000
      @sleep_in_ms = sleep_in_ms
    end

    def with_timeout(timeout)
      expire = Time.now + timeout.to_f
      sleep_in_sec = @sleep_in_ms / 1000.to_f()
      while Time.now + sleep_in_sec < expire
        return true if yield
        sleep sleep_in_sec
      end
    end

    def lock(timeout = 10)
      with_timeout(timeout) { do_lock }
    end

    def do_lock
      result = @document.class
        .where(@document.atomic_selector)
        .where(@lock_field => nil)
        .set(@lock_field => @owner)
      result.modified_count
    end

    def unlock
      result = @document.class
        .where(@document.atomic_selector)
        .where(@lock_field => @owner)
        .unset(@lock_field)
      result.modified_count
    end
  end
end
