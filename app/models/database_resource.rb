class DatabaseResource < ActiveRecord::Base
  belongs_to :user
  belongs_to :deployment
  belongs_to :cloud
  belongs_to :database_type

  include ModelMixins::PatternMixin
  include ModelMixins::DataLinkMixin

  validates :user_id, :cloud_id, :database_type_id, :deployment_id, :name, :presence => true
  validates :storage_size_monthly_baseline, :transaction_monthly_baseline, :numericality => { :greater_than_or_equal_to => 0 }
  validates :instance_hour_monthly_baseline, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 744 }
  validates :quantity_monthly_baseline, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }

  attr_accessible :name, :description, :storage_size_monthly_baseline, :instance_hour_monthly_baseline,
                  :transaction_monthly_baseline, :quantity_monthly_baseline

  after_initialize :set_defaults

  def deep_clone(options={})
    DatabaseResource.transaction do
      new_database = self.dup(:include => [:pattern_maps], :use_dictionary => true)
      new_database.name = options[:name] || "Copy of #{new_database.name}"
      new_database.save!(:validate => false)
      new_database
    end
  end

  def display_class
    "Database"
  end

  private
  def set_defaults
    if new_record?
      self.storage_size_monthly_baseline  ||= 0
      self.instance_hour_monthly_baseline ||= 0
      self.transaction_monthly_baseline   ||= 0
      self.quantity_monthly_baseline      ||= 1
    end
  end

end
