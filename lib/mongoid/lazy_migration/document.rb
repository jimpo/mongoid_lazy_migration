require 'mongoid/lazy_migration/errors'

module Mongoid::LazyMigration::Document
  include Mongoid::LazyMigration::Errors

  def ensure_migration
    self.migration_state = :done if new_record?

    if migration_state != :done
      @migrating = true
      if self.class.migration_lock.nil?
        perform_migration
      else
        perform_locked_migration
      end
      @migrating = false
    end
  end

  ###
  # For atomic migrations, save() will be performed with the
  # following additional selector (see atomic_selector):
  #   :migration_state => { "$ne" => :done }
  # This guarantee that we never commit more than one migration on a
  # document, even though we are not taking a lock.
  #
  def atomic_selector
    return super unless @migrating && self.class.migration_lock.nil?

    if @running_migrate_block
      raise AtomicMigrationError.new(<<EOS
You cannot save during an atomic migration,
You are only allowed to set the document fields
The document will be commited once the migration is complete.
If you need to get fancy, like creating associations, use :lock => true
EOS
      )
    end

    super.merge('migration_state' => { "$ne" => :done })
  end

  def run_callbacks(*args, &block)
    return super unless @migrating

    yield if block_given?
  end

  private
  def perform_locked_migration
    lock = self.class.migration_lock
    lock = lock.call(self) if lock.respond_to? :call
    lock.lock
    reload  # Other process that had the lock may have changed this document
    perform_migration if migration_state != :done
  ensure
    lock.unlock
  end

  def perform_migration
    @running_migrate_block = true
    instance_eval(&self.class.migrate_block)
    @running_migrate_block = false

    self.migration_state = :done
    save(:validate => false)
  end
end
