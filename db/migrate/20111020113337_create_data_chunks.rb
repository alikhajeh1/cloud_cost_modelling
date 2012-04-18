class CreateDataChunks < ActiveRecord::Migration
  def change
    create_table :data_chunks do |t|
      t.integer  :user_id
      t.integer  :deployment_id
      t.integer  :storage_id
      t.string   :name
      t.text     :description
      t.float    :size_monthly_baseline
      t.float    :read_requests_monthly_baseline
      t.float    :write_requests_monthly_baseline

      t.timestamps
    end

    change_table :data_chunks do |t|
      t.index :user_id
      t.index :deployment_id
      t.index :storage_id
    end
  end
end
