require 'spec_helper'
require 'support/models'

describe Mongoid::LazyMigration, ".migrate" do
  let!(:pendings_lock)   { 5.times { ModelLock.collection.insert({})} }
  let!(:pendings_atomic) { 5.times { ModelAtomic.collection.insert({})} }
  let(:progressbar_output) { StringIO.new }

  it "migrates all the models by default" do
    expect(ModelLock.where(:migrated => true).count).to eq(0)
    expect(ModelAtomic.where(:migrated => true).count).to eq(0)
    Mongoid::LazyMigration.migrate(nil, progressbar_output)
    expect(ModelLock.where(:migrated => true).count).to eq(5)
    expect(ModelAtomic.where(:migrated => true).count).to eq(5)
  end

  it "migrates all the documents of a specific class" do
    expect(ModelLock.where(:migrated => true).count).to eq(0)
    Mongoid::LazyMigration.migrate(ModelLock, progressbar_output)
    expect(ModelLock.where(:migrated => true).count).to eq(5)

    expect(ModelAtomic.where(:migrated => true).count).to eq(0)
  end

  it "supports a criteria" do
    expect(ModelLock.where(:migrated => true).count).to eq(0)
    Mongoid::LazyMigration.migrate(ModelLock.limit(2), progressbar_output)
    expect(ModelLock.where(:migrated => true).count).to eq(2)
  end
end

describe Mongoid::LazyMigration, ".cleanup" do
  let!(:done1) { ModelNoMigration.collection.insert(:migration_state => :done) }
  let!(:done2) { ModelNoMigration.collection.insert(:migration_state => :done) }

  it "cleans up all the documents of a specific class" do
    Mongoid::LazyMigration.cleanup(ModelNoMigration)
    expect(ModelNoMigration.where(:migration_state => nil).count).to eq(2)
  end

  it "chokes if any documents are still being processed" do
    ModelNoMigration.collection.insert(:migration_state => :processing)
    expect { Mongoid::LazyMigration.cleanup(ModelNoMigration) }.to raise_error
    expect(ModelNoMigration.where(:migration_state => nil).count).to eq(0)
  end

  it "chokes if the migration is still defined" do
    expect { Mongoid::LazyMigration.cleanup(ModelAtomic) }.to raise_error
  end
end
