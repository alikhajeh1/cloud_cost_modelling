class CloudCostTier < ActiveRecord::Base
  belongs_to :cloud_cost_structure

  validates :cloud_cost_structure_id, :presence => true
  validates :upto, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0}, :allow_nil => true
  validates :cost, :numericality => {:greater_than_or_equal_to => 0}

  attr_accessible :name, :description, :upto, :cost
end
