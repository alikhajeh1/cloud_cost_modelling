class Deployment < ActiveRecord::Base
  belongs_to :user

  has_many :applications, :dependent => :destroy
  has_many :data_chunks, :dependent => :destroy
  has_many :servers, :dependent => :destroy
  has_many :storages, :dependent => :destroy
  has_many :database_resources, :dependent => :destroy
  has_many :remote_nodes, :dependent => :destroy
  has_many :data_links, :dependent => :destroy
  has_one :report, :as => :reportable, :dependent => :destroy

  has_and_belongs_to_many :additional_costs

  validates :user_id, :name, :presence => true

  attr_accessible :name, :description
  after_initialize :set_defaults

  def deep_clone(options={})
    Deployment.transaction do
      new_deployment = self.dup(:include => [
        {:data_links => [:pattern_maps, :sourcable, :targetable]},
        {:servers => [:pattern_maps, :applications]},
        {:storages => [:pattern_maps, :data_chunks]},
        {:applications => [:pattern_maps, :server]},
        {:data_chunks => [:pattern_maps, :storage]},
        {:database_resources => :pattern_maps}, :remote_nodes],
        :use_dictionary => true)
      new_deployment.name = options[:name] || "Copy of #{new_deployment.name}"
      new_deployment.save!(:validate => false)
      self.additional_costs.each {|ac| new_deployment.additional_costs << ac}
      new_deployment
    end
  end

  def get_resources_for_data_link
    self.servers + self.storages + self.database_resources + self.remote_nodes
  end

  private
  def set_defaults
    if new_record?
      self.cost ||= 0.00
    end
  end
end
