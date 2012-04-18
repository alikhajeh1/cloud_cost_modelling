class CreateAdditionalCostsDeployments < ActiveRecord::Migration
  def change
    create_table :additional_costs_deployments, :id => false do |t|
      t.integer :additional_cost_id
      t.integer :deployment_id

      t.timestamps
    end

    change_table :additional_costs_deployments do |t|
      t.index :additional_cost_id
      t.index :deployment_id
    end

  end
end
