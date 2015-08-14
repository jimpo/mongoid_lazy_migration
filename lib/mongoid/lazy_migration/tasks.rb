require 'ruby-progressbar'
require 'mongoid/lazy_migration/errors'

module Mongoid::LazyMigration::Tasks
  include Mongoid::LazyMigration::Errors

  def migrate(criteria=nil, output=STDOUT)
    criterias =
      if criteria.nil?
        Mongoid::LazyMigration.models_to_migrate
      else
        [criteria]
      end
    criterias.each do |criteria|
      to_migrate = criteria.where(:migration_state.ne => :done)
      progress = ProgressBar.create(
        title: to_migrate.klass.to_s,
        total: to_migrate.count,
        output: output
      )
      to_migrate.each { progress.increment }
      progress.finish
    end
    true
  end

  def cleanup(model)
    if model.in? Mongoid::LazyMigration.models_to_migrate
      raise CleanupError.new(
        "Remove the migration from your model before cleaning up the database")
    end

    selector = { :migration_state => { "$exists" => true }}
    changes  = {"$unset" => { :migration_state => 1}}
    safety   = { :safe => true, :multi => true }
    multi    = { :multi => true }

    model.with(safety).where(selector).query.update(changes, multi)
  end
end
