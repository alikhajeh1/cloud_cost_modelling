class Pattern < ActiveRecord::Base

  belongs_to :user # If it does not belong to user, then it's being used by cloud_cost_structure or another model
  has_many :rules, :dependent => :destroy, :order => :position
  has_many :pattern_maps, :dependent => :destroy
  has_many :applications, :through => :pattern_maps, :source => :patternable, :source_type => 'Application'
  has_many :data_chunks, :through => :pattern_maps, :source => :patternable, :source_type => 'DataChunk'
  has_many :servers, :through => :pattern_maps, :source => :patternable, :source_type => 'Server'
  has_many :storages, :through => :pattern_maps, :source => :patternable, :source_type => 'Storage'
  has_many :database_resources, :through => :pattern_maps, :source => :patternable, :source_type => 'DatabaseResource'
  has_many :data_links, :through => :pattern_maps, :source => :patternable, :source_type => 'DataLink'
  has_many :additional_costs, :through => :pattern_maps, :source => :patternable, :source_type => 'AdditionalCost'
  has_many :cloud_cost_structures, :through => :pattern_maps, :source => :patternable, :source_type => 'CloudCostStructure'

  validates :name, :presence => true

  scope :no_users, where(:user_id => nil)

  attr_accessible :name, :description

  USER_PATTERNABLE_MODELS = ['Application', 'DataChunk', 'Server', 'Storage', 'DatabaseResource', 'DataLink', 'AdditionalCost']

  def used_by
    PatternMap.find_all_by_pattern_id(self.id)
  end

  def deep_clone(options={})
    Pattern.transaction do
      new_pattern = self.dup(:include => [:rules])
      new_pattern.name = options[:name] || "Copy of #{new_pattern.name}"
      new_pattern.save!(:validate => false)
      new_pattern
    end
  end
end

