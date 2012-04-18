class CreateCloudCostSchemes < ActiveRecord::Migration
  def change
    create_table :cloud_cost_schemes do |t|
      t.integer :cloud_id, :null => false
      t.integer :cloud_resource_type_id, :null => false
      t.integer :cloud_cost_structure_id, :null => false
      t.timestamps
    end

    add_index :cloud_cost_schemes, [:cloud_id, :cloud_resource_type_id, :cloud_cost_structure_id], :unique => true, :name => 'index_cloud_cost_structure_unique'
  end
end
