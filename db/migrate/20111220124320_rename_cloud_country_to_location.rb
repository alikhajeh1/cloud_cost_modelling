class RenameCloudCountryToLocation < ActiveRecord::Migration
  def change
    rename_column :clouds, :country, :location
  end
end
