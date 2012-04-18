class CreateClouds < ActiveRecord::Migration
  def change
    create_table :clouds do |t|
      t.integer :cloud_provider_id
      t.string  :name
      t.text    :description
      t.string  :billing_currency
      t.string  :country

      t.timestamps
    end

    change_table :clouds do |t|
      t.index :cloud_provider_id
    end
  end
end
