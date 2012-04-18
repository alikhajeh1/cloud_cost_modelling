class RemoveCloudProviderUsers < ActiveRecord::Migration
  def change
    drop_table :cloud_provider_users
  end
end
