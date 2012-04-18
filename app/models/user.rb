class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :timeoutable, :lockable,
         :recoverable, :rememberable, :trackable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :company, :timezone, :currency, :comment, :homepage
  attr_accessor :comment, :homepage # fake attributes used for spam trapping, comment is a honeypot, homepage is a timestamp
  validates :comment, :length => {:is => 0, :message => ' '}
  validate :check_homepage
  validates :first_name, :last_name, :company, :presence => true
  validates_format_of :currency, :with => /\A[A-Z]{3}\z/
  validate :check_currency

  has_many :reports
  has_many :patterns
  has_many :pattern_maps
  has_many :rules
  has_many :deployments
  has_many :applications
  has_many :data_chunks
  has_many :servers
  has_many :storages
  has_many :database_resources
  has_many :remote_nodes
  has_many :data_links
  has_many :additional_costs


  after_initialize :set_defaults

  def initialize_new_user
    if sign_in_count == 1 && (Time.now < (current_sign_in_at + 10.seconds))
      user_initializer = InitializeUser.new(self)
      user_initializer.create_example_deployment
    end
  end

  private
  def check_homepage
    # Spam check: make sure it took at least 5 seconds to fill in the user registration form
    begin
      errors.add(:homepage, ' ') if self.homepage && Time.parse(self.homepage) > Time.now - 5.seconds
    rescue
      errors.add(:homepage, ' ')
    end
  end

  def check_currency
    begin
      1.to_money(:USD).exchange_to(self.currency)
    rescue Money::Bank::UnknownRate, Money::Currency::UnknownCurrency
      errors.add(:currency, 'is not supported by Google Currency (which we use for exchange rates)')
    end
  end

  def set_defaults
    if new_record?
      self.timezone ||= "UTC"
      self.currency ||= "USD"
    end
  end
end


