class CloudCostStructure < ActiveRecord::Base
  has_many :cloud_cost_tiers, :dependent => :destroy

  has_many :cloud_cost_schemes
  has_many :clouds, :through => :cloud_cost_schemes
  has_many :cloud_resource_types, :through => :cloud_cost_schemes

  include ModelMixins::PatternMixin

  validates :name, :presence => true
  validates_format_of :units, :with => /\A(per\.\d+\.\w+|per\.\d+\.\w+\.per\.\d+\.\w+)\z/i
  validates :recurring_costs_monthly_baseline, :numericality => {:greater_than_or_equal_to => 0}
  validates :custom_algorithm, :inclusion => {:in => %w(sql_azure)}, :allow_nil => true

  attr_accessible :name, :description, :units, :valid_until, :recurring_costs_monthly_baseline, :custom_algorithm

  after_initialize :set_defaults

  # Method to return a concatenated string of the tier prices
  def tier_prices_string (unit_label = '')
    tiers = self.cloud_cost_tiers.order("upto ASC")
    return "#{tiers.first.cost.to_s}" if tiers.length == 1

    tier_prices_string = "From 0#{unit_label}"

    tiers.each do |t|
      if t.upto == nil
        tier_prices_string << " and above: #{t.cost.to_s}"
      else
        tier_prices_string << " up to #{t.upto.to_s}#{unit_label}: #{t.cost.to_s},"
      end
    end
    return tier_prices_string
  end

  private
  def set_defaults
    if new_record?
      self.recurring_costs_monthly_baseline ||= 0
    end
  end
end
