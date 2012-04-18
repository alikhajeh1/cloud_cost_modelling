class CloudCostScheme < ActiveRecord::Base
  belongs_to :cloud
  belongs_to :cloud_resource_type
  belongs_to :cloud_cost_structure

  validates :cloud_id, :cloud_resource_type_id, :cloud_cost_structure_id, :presence => true

end
