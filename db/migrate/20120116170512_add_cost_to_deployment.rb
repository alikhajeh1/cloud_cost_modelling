class AddCostToDeployment < ActiveRecord::Migration
  def change
    add_column :deployments, :cost, :float
  end
end
