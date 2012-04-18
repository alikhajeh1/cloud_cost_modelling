class CreateCloudProviders < ActiveRecord::Migration
  def change
    create_table :cloud_providers do |t|
      t.string :name
      t.text   :description
      t.string :website

      t.timestamps
    end
  end
end
