class CreateServers < ActiveRecord::Migration
  def change
    create_table :servers do |t|
      t.integer  :user_id
      t.integer  :deployment_id
      t.integer  :cloud_id
      t.integer  :server_type_id
      t.string   :name
      t.text     :description
      t.float    :instance_hours_monthly_baseline
      t.integer  :quantity_baseline

      t.timestamps
    end

    change_table :servers do |t|
      t.index :user_id
      t.index :deployment_id
      t.index :cloud_id
      t.index :server_type_id
    end
  end
end
