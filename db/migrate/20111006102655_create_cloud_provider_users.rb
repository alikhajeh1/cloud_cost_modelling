# This table has been deleted.

class CreateCloudProviderUsers < ActiveRecord::Migration
  def change
    create_table :cloud_provider_users do |t|
      t.integer :user_id
      t.integer :cloud_provider_id

      t.timestamps
    end

    change_table :cloud_provider_users do |t|
      t.index :user_id
      t.index :cloud_provider_id
    end
  end
end
