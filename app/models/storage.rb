class Storage < ActiveRecord::Base
  belongs_to :user
  belongs_to :deployment
  belongs_to :cloud
  belongs_to :storage_type

  has_many :data_chunks

  include ModelMixins::PatternMixin
  include ModelMixins::DataLinkMixin

  validates :user_id, :cloud_id, :storage_type_id, :deployment_id, :name, :presence => true
  validates :storage_size_monthly_baseline, :read_request_monthly_baseline,
            :write_request_monthly_baseline, :numericality => { :greater_than_or_equal_to => 0 }
  validates :quantity_monthly_baseline, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }

  attr_accessible :name, :description, :storage_size_monthly_baseline, :read_request_monthly_baseline,
                  :write_request_monthly_baseline, :quantity_monthly_baseline

  after_initialize :set_defaults

  def deep_clone(options={})
    Storage.transaction do
      new_storage = self.dup(:include => [:pattern_maps], :use_dictionary => true)
      new_storage.name = options[:name] || "Copy of #{new_storage.name}"
      new_storage.save!(:validate => false)
      new_storage
    end
  end

  def display_class
    "Storage"
  end

  private
  def set_defaults
    if new_record?
      self.storage_size_monthly_baseline  ||= 0
      self.read_request_monthly_baseline  ||= 0
      self.write_request_monthly_baseline ||= 0
      self.quantity_monthly_baseline      ||= 1
    end
  end

end
