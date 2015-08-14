require 'spec_helper'
require 'support/models'

describe Mongoid::LazyMigration::Document do
  describe ".migration" do
    def insert_raw(type, fields={})
      id = BSON::ObjectId.new
      type.collection.insert({:_id => id}.merge(fields))
      id
    end

    it "does not run any save/update callbacks" do
      class ModelCallbacks
        include Mongoid::Document
        include Mongoid::LazyMigration
        cattr_accessor :callback_called
        @@callback_called = 0

        field :some_field
        migration {}

        before_save   { self.class.callback_called += 1 }
        after_save    { self.class.callback_called += 1 }
        before_update { self.class.callback_called += 1 }
        after_update  { self.class.callback_called += 1 }
      end
      Mongoid::LazyMigration.models_to_migrate.delete(ModelCallbacks)

      id = insert_raw(ModelCallbacks)
      model = ModelCallbacks.find(id)
      expect(ModelCallbacks.callback_called).to eq(0)

      model.some_field = "bacon"
      model.save
      expect(ModelCallbacks.callback_called).to eq(4)
    end

    it "does not validate" do
      class ModelValidate
        include Mongoid::Document
        include Mongoid::LazyMigration
        cattr_accessor :migration_count
        @@migration_count = 0

        field :some_field
        validates_presence_of :some_field
        migration do
          self.class.migration_count += 1
        end
      end
      Mongoid::LazyMigration.models_to_migrate.delete(ModelValidate)

      id = insert_raw(ModelValidate)
      ModelValidate.find(id)
      ModelValidate.find(id)
      expect(ModelValidate.migration_count).to eq(1)
    end

    it "does not allow saving during the migration" do
      class ModelInvalid
        include Mongoid::Document
        include Mongoid::LazyMigration
        field :some_field
        migration do
          self.some_field = "bacon"
          self.save
        end
      end
      Mongoid::LazyMigration.models_to_migrate.delete(ModelInvalid)

      id = insert_raw(ModelInvalid)
      expect { ModelInvalid.find(id) }
        .to raise_error(Mongoid::LazyMigration::Errors::AtomicMigrationError)
    end

    it "doesn't migrate pending models when subset of fields are selected" do
      expect_any_instance_of(ModelAtomic).to_not receive(:ensure_migration)
      pending = insert_raw(ModelAtomic)
      ModelAtomic.only(:id).find(pending)
    end

    describe "locked migration" do
      let(:pending)    { insert_raw(ModelLock) }
      let(:processing) { insert_raw(ModelLock, :migration_state => :processing) }
      let(:done)       { insert_raw(ModelLock, :migration_state => :done) }

      it "migrates pending models on fetch" do
        expect(ModelLock.find(pending).migrated).to be_truthy
      end

      it "doesn't migrate done models on fetch" do
        expect(ModelLock.find(done).migrated).to be_falsy
      end

      it "doesn't update the updated_at field during the migration" do
        model = ModelLock.find(pending)
        expect(model.updated_at).to be_nil
        model.some_field = "bacon"
        model.save
        expect(model.updated_at).not_to be_nil
      end

      # I don't know how to test this. Please help.
      it "busy waits when a model has a migration in process"
      it "never lets two migrations happen at the same time on the same model"
    end

    describe "atomic migration" do
      let(:pending)    { insert_raw(ModelAtomic) }
      let(:processing) { insert_raw(ModelAtomic, :migration_state => :processing) }
      let(:done)       { insert_raw(ModelAtomic, :migration_state => :done) }

      it "migrates pending models on fetch" do
        expect(ModelAtomic.find(pending).migrated).to be_truthy
      end

      it "doesn't migrate done models on fetch" do
        expect(ModelAtomic.find(done).migrated).to be_falsy
      end

      # I don't know how to test this. Please help.
      it "never lets two migrations to be commit to the database for the same model"
    end
  end

  describe "#atomic_selector" do
    it 'returns the original selector when not doing a migration' do
      m = ModelAtomic.create
      expect(m.atomic_selector).to eq("_id" => m._id)
    end
  end
end
