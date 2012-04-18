class CloudProvider < ActiveRecord::Base
  has_many :clouds, :dependent => :destroy

  validates :name, :presence => true

  attr_accessible :name, :description, :website
end
