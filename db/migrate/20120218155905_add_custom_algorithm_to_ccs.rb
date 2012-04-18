class AddCustomAlgorithmToCcs < ActiveRecord::Migration
  class CloudCostStructure < ActiveRecord::Base
  end

  def change
    add_column :cloud_cost_structures, :custom_algorithm, :string
    CloudCostStructure.reset_column_information

    # Add new custom algorithm value to SQL Azure DatabaseTypes
    ['Pay-As-You-Go Web Edition (upto 5 GB)', 'Pay-As-You-Go Business Edition (upto 150 GB)'].each do |db_type_name|
      db_type = DatabaseType.find_by_name(db_type_name)
      db_type.cloud_cost_structures.find_all_by_name('storage_size').each {
          |ccs| ccs.update_attributes!(:custom_algorithm => 'sql_azure') } if db_type
    end
  end
end
