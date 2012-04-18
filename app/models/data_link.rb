class DataLink < ActiveRecord::Base
  DATA_LINKABLE_MODELS = ['Server', 'Storage', 'DatabaseResource', 'RemoteNode']

  belongs_to :user
  belongs_to :deployment

  belongs_to :sourcable, :polymorphic => true
  belongs_to :targetable, :polymorphic => true

  include ModelMixins::PatternMixin

  # sourcable_id and targetable_id should always be present but deployment.deep_clone fails so we'll enforce it in the UI
  validates :user_id, :deployment_id, :presence => true
  validates :source_to_target_monthly_baseline, :target_to_source_monthly_baseline, :numericality => { :greater_than_or_equal_to => 0 }
  validate :check_data_link

  attr_accessible :name, :description, :source_to_target_monthly_baseline, :target_to_source_monthly_baseline
  after_initialize :set_defaults

  def deep_clone(options={})
    DataLink.transaction do
      new_data_link = self.dup(:include => [:pattern_maps], :use_dictionary => true)
      new_data_link.name = options[:name] || "Copy of #{new_data_link.name}"
      new_data_link.save!(:validate => false)
      new_data_link
    end
  end

  # Needed for best_in_place
  def sourcable_type_id
    "#{self.sourcable_type}:#{self.sourcable_id}"
  end

  # Needed for best_in_place
  def targetable_type_id
    "#{self.targetable_type}:#{self.targetable_id}"
  end

  private
  def check_data_link
    # The following 2 validation checks result in unnecessary DB calls during the controller's UPDATE but let's leave them in,
    # otherwise someone can accidentally create an invalid DataLink through rails console or in another model
    errors.add(:sourcable, 'must be in the same deployment as this data link') if self.sourcable && self.deployment != self.sourcable.deployment
    errors.add(:targetable, 'must be in the same deployment as this data link') if self.targetable && self.deployment != self.targetable.deployment
    errors.add(:sourcable, 'source and destination cannot be the same') if self.sourcable == self.targetable
  end

  def set_defaults
    if new_record?
      self.source_to_target_monthly_baseline ||= 0
      self.target_to_source_monthly_baseline ||= 0
    end
  end
end
