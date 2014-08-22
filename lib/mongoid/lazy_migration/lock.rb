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
  end

  class Mongoid3Lock < Lock
    def do_lock
      result = @document.class
        .with(safe: true)
        .where(@document.atomic_selector)
        .where(@lock_field => nil)
        .find_and_modify('$set' => { @lock_field => @owner })
      return !!result
    end

    def unlock
      @document.unset(@lock_field)
    end
  end

  # TODO(but probably not): Add Mongoid2Lock
end
