class CreateRemoteNodes < ActiveRecord::Migration
  def change
    create_table :remote_nodes do |t|
      t.integer :user_id
      t.integer :deployment_id
      t.string  :name
      t.text    :description

      t.timestamps
    end

    change_table :remote_nodes do |t|
      t.index :user_id
      t.index :deployment_id
    end
  end
end
