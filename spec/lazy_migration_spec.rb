require 'spec_helper'
require 'support/models'

describe Mongoid::LazyMigration::Document, "models_to_migrate" do
  it "returns the list of models performing a lazy migration" do
    expect(Mongoid::LazyMigration.models_to_migrate)
      .to include(ModelLock, ModelAtomic)
  end
end
