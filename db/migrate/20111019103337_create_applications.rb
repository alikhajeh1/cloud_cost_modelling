class CreateApplications < ActiveRecord::Migration
  def change
    create_table :applications do |t|
      t.integer  :user_id
      t.integer  :deployment_id
      t.integer  :server_id
      t.string   :name
      t.text     :description
      t.float    :instance_hours_monthly_baseline

      t.timestamps
    end

    change_table :applications do |t|
      t.index :user_id
      t.index :deployment_id
      t.index :server_id
    end
  end
end
