class PatternMap < ActiveRecord::Base
  belongs_to :user

  belongs_to :pattern
  belongs_to :patternable, :polymorphic => true
  acts_as_list scope: [:patternable_id, :patternable_type, :patternable_attribute]

  validates :position, :allow_nil => true, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0}

end