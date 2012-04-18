class CreateCloudCostTiers < ActiveRecord::Migration
  def change
    create_table :cloud_cost_tiers do |t|
      t.integer :cloud_cost_structure_id
      t.string  :name
      t.text    :description
      t.integer :upto
      t.decimal :cost, :precision => 30, :scale => 10

      t.timestamps
    end

    change_table :cloud_cost_tiers do |t|
      t.index :cloud_cost_structure_id
    end
  end
end
