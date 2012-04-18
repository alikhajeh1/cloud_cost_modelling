class Server < ActiveRecord::Base
  belongs_to :user
  belongs_to :deployment
  belongs_to :cloud
  belongs_to :server_type

  has_many :applications

  include ModelMixins::PatternMixin
  include ModelMixins::DataLinkMixin

  validates :user_id, :deployment_id, :server_type_id, :cloud_id, :name, :presence => true
  validates :instance_hour_monthly_baseline, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 744 }
  validates :quantity_monthly_baseline, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }

  attr_accessible :name, :description, :instance_hour_monthly_baseline, :quantity_monthly_baseline

  after_initialize :set_defaults

  def deep_clone(options={})
    Server.transaction do
      new_server = self.dup(:include => [:pattern_maps], :use_dictionary => true)
      new_server.name = options[:name] || "Copy of #{new_server.name}"
      new_server.save!(:validate => false)
      new_server
    end
  end

  def display_class
    "Server"
  end

  private
  def set_defaults
    if new_record?
      self.instance_hour_monthly_baseline ||= 0
      self.quantity_monthly_baseline      ||= 1
    end
  end

end
