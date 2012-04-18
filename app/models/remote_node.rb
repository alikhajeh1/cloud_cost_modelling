class RemoteNode < ActiveRecord::Base
  belongs_to :user
  belongs_to :deployment

  include ModelMixins::DataLinkMixin

  validates :user_id, :deployment_id, :name, :presence => true

  attr_accessible :name, :description

  def display_class
    "Remote Node"
  end
end
