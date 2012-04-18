class Cloud < ActiveRecord::Base
  belongs_to :cloud_provider
  has_many :cloud_cost_schemes
  has_many :cloud_resource_types, :through => :cloud_cost_schemes
  has_many :cloud_cost_structures, :through => :cloud_cost_schemes

  has_many :servers
  has_many :storages
  has_many :database_resources

  validates :cloud_provider_id, :name, :presence => true
  validates_format_of :billing_currency, :with => /\A[A-Z]{3}\z/
  validate :check_billing_currency

  attr_accessible :name, :description, :billing_currency, :location
  after_initialize :set_defaults

  private
  def set_defaults
    if new_record?
      self.billing_currency ||= "USD"
    end
  end

  def check_billing_currency
    begin
      1.to_money(:USD).exchange_to(self.billing_currency)
    rescue Money::Bank::UnknownRate, Money::Currency::UnknownCurrency
      errors.add(:billing_currency, 'is not supported by Google Currency (which we use for exchange rates)')
    end
  end
end
