class CreatePatternMaps < ActiveRecord::Migration
  def change
    create_table :pattern_maps do |t|
      t.integer :user_id
      t.references :patternable, :polymorphic => true
      t.string :patternable_attribute, :null => false
      t.integer :pattern_id, :null => false

      t.timestamps
    end

    add_index :pattern_maps, [:user_id, :patternable_id, :patternable_type, :patternable_attribute, :pattern_id], :unique => true, :name => 'index_pattern_maps_unique'
  end
end
