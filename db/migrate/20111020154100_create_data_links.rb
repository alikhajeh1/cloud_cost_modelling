class CreateDataLinks < ActiveRecord::Migration
  def change
    create_table :data_links do |t|
      t.integer    :user_id
      t.integer    :deployment_id
      t.string     :name
      t.text       :description
      t.references :sourcable, :polymorphic => true
      t.references :targetable, :polymorphic => true
      t.float      :source_to_target_monthly_baseline
      t.float      :target_to_source_monthly_baseline

      t.timestamps
    end

    change_table :data_links do |t|
      t.index :user_id
      t.index :deployment_id
      t.index [:sourcable_id, :sourcable_type]
      t.index [:targetable_id, :targetable_type]
    end
  end
end
