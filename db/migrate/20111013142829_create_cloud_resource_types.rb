class CreateCloudResourceTypes < ActiveRecord::Migration
  def change
    create_table :cloud_resource_types do |t|
      t.string  :type
      t.string  :name
      t.text    :description
      t.string  :cpu_architecture
      t.float   :cpu_speed
      t.integer :cpu_count
      t.integer :local_disk_count
      t.float   :local_disk_size
      t.float   :memory
      t.string  :operating_system
      t.string  :software

      t.timestamps
    end

    change_table :cloud_resource_types do |t|
      t.index :name
    end
  end
end
