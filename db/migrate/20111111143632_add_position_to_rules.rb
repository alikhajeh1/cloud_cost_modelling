class AddPositionToRules < ActiveRecord::Migration
  def change
    add_column :rules, :position, :integer
  end
end
