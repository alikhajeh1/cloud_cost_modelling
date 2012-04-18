class RenameAddiCostsColumnCosts < ActiveRecord::Migration
  def change
    rename_column :additional_costs, :cost_baseline, :cost_monthly_baseline
  end
end
