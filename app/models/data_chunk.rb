class DataChunk < ActiveRecord::Base
  belongs_to :user
  belongs_to :deployment
  belongs_to :storage

  include ModelMixins::PatternMixin
  include ModelMixins::DataLinkMixin

  # storage_id should always be present but deployment.deep_clone fails so we'll enforce it in the UI
  validates :user_id, :deployment_id, :name, :presence => true
  validates :storage_size_monthly_baseline, :read_request_monthly_baseline,
            :write_request_monthly_baseline, :numericality => {:greater_than_or_equal_to => 0}
  validate :check_storage

  attr_accessible :name, :description, :storage_size_monthly_baseline, :read_request_monthly_baseline,
                  :write_request_monthly_baseline, :storage_id

  after_initialize :set_defaults

  def deep_clone(options={})
    DataChunk.transaction do
      new_data_chunk = self.dup(:include => [:pattern_maps], :use_dictionary => true)
      new_data_chunk.name = options[:name] || "Copy of #{new_data_chunk.name}"
      new_data_chunk.save!(:validate => false)
      new_data_chunk
    end
  end

  private
  def check_storage
    errors.add(:storage, 'must be in the same deployment as the application data') if self.storage_id && !self.deployment.storages.exists?(self.storage_id)
  end

  def set_defaults
    if new_record?
      self.storage_size_monthly_baseline  ||= 0
      self.read_request_monthly_baseline  ||= 0
      self.write_request_monthly_baseline ||= 0
    end
  end

end