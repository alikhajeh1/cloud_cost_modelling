class CreateDeployments < ActiveRecord::Migration
  def change
    create_table :deployments do |t|
      t.integer  :user_id
      t.string   :name
      t.text     :description

      t.timestamps
    end

    change_table :deployments do |t|
      t.index :user_id
    end
  end
end
