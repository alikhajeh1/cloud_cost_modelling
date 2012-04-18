class AdditionalCost < ActiveRecord::Base
  belongs_to :user

  has_and_belongs_to_many :deployments

  include ModelMixins::PatternMixin

  validates :user_id, :name, :presence => true
  validates :cost_monthly_baseline, :numericality => {:greater_than_or_equal_to => 0}

  attr_accessible :name, :description, :cost_monthly_baseline

  after_initialize :set_defaults

  def deep_clone(options={})
    AdditionalCost.transaction do
      new_additional_cost = self.dup(:include => [:pattern_maps], :use_dictionary => true)
      new_additional_cost.name = options[:name] || "Copy of #{new_additional_cost.name}"
      new_additional_cost.save!(:validate => false)
      self.deployments.each {|d| new_additional_cost.deployments << d}
      new_additional_cost
    end
  end

  private
  def set_defaults
    if new_record?
      self.cost_monthly_baseline ||= 0
    end
  end

end
