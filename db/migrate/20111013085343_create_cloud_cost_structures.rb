class CreateCloudCostStructures < ActiveRecord::Migration
  def change
    create_table :cloud_cost_structures do |t|
      t.string   :name
      t.text     :description
      t.string   :units
      t.datetime :valid_until
      t.decimal  :recurring_costs_monthly_baseline, :precision => 30, :scale => 10

      t.timestamps
    end
  end
end
