class AddPositionToPatternMaps < ActiveRecord::Migration
  def change
    add_column :pattern_maps, :position, :integer
  end
end
