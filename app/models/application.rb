class Application < ActiveRecord::Base
  belongs_to :user
  belongs_to :deployment
  belongs_to :server

  include ModelMixins::PatternMixin
  include ModelMixins::DataLinkMixin

  # server_id should always be present but deployment.deep_clone fails so we'll enforce it in the UI
  validates :user_id, :deployment_id, :name, :presence => true
  validates :instance_hour_monthly_baseline, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 744 }
  validate :check_server

  attr_accessible :name, :description, :instance_hour_monthly_baseline, :server_id

  after_initialize :set_defaults

  def deep_clone(options={})
    Application.transaction do
      new_application = self.dup(:include => [:pattern_maps], :use_dictionary => true)
      new_application.name = options[:name] || "Copy of #{new_application.name}"
      new_application.save!(:validate => false)
      new_application
    end
  end

  private
  def check_server
    errors.add(:server, 'must be in the same deployment as the application') if self.server_id && !self.deployment.servers.exists?(self.server_id)
  end

  def set_defaults
    if new_record?
      self.instance_hour_monthly_baseline ||= 0
    end
  end
end