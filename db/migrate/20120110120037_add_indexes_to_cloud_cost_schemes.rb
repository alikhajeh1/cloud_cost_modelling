class AddIndexesToCloudCostSchemes < ActiveRecord::Migration
  def change
    change_table :cloud_cost_schemes do |t|
      t.index :cloud_id
      t.index :cloud_resource_type_id
      t.index :cloud_cost_structure_id
    end
  end
end
