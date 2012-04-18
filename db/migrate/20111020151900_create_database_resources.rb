class CreateDatabaseResources < ActiveRecord::Migration
  def change
    create_table :database_resources do |t|
      t.integer  :user_id
      t.integer  :deployment_id
      t.integer  :cloud_id
      t.integer  :database_type_id
      t.string   :name
      t.text     :description
      t.float    :instance_hours_monthly_baseline
      t.float    :size_monthly_baseline
      t.float    :transactions_monthly_baseline
      t.integer  :quantity_baseline

      t.timestamps
    end

    change_table :database_resources do |t|
      t.index :user_id
      t.index :deployment_id
      t.index :cloud_id
      t.index :database_type_id
    end
  end
end
