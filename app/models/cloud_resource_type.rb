class CloudResourceType < ActiveRecord::Base
  has_many :cloud_cost_schemes
  has_many :clouds, :through => :cloud_cost_schemes
  has_many :cloud_cost_structures, :through => :cloud_cost_schemes

  validates :name, :presence => true

  attr_accessible :name, :description, :cpu_architecture, :cpu_speed, :cpu_count,
                  :local_disk_count, :local_disk_size, :memory, :operating_system, :software

  # Method to return all CloudResourceTypes and their clouds.
  # This method is used by the individual CloudResourceTypes to return a list of options for user to pick
  def self.join_with_clouds(cloud_resource_type=nil, cloud=nil)
    cloud_hash = cloud ? {:id => cloud.id} : {}
    cloud_resource_type_hash = cloud_resource_type ? {:type => cloud_resource_type.to_s} : {}
    CloudResourceType.all(:conditions => {:clouds => cloud_hash}.merge(cloud_resource_type_hash),
                          :include => [:clouds])
  end

  # Method to return a string concatenating the CPU information of the resource
  def cpu_values_string
    return "#{self.cpu_architecture} architecture" if !self.cpu_speed && self.cpu_architecture
    cpu_string = "#{self.cpu_speed} GHz" if self.cpu_speed
    cpu_string ||= ""
    cpu_string.insert(0, "#{self.cpu_count} x ") if self.cpu_count
    cpu_string << "CPU" if !self.cpu_speed && self.cpu_count
    cpu_string << " (#{self.cpu_architecture})" if self.cpu_architecture
    cpu_string
  end

  # Method to return a string concatenating the local storage of the resource
  def hdd_values_string
     hdd_string = "#{self.local_disk_size} GB" if self.local_disk_size
     hdd_string ||= ""
     hdd_string.insert(0, "#{self.local_disk_count} x ") if self.local_disk_count
     hdd_string << "HDD" if !self.local_disk_size && self.local_disk_count
     hdd_string
  end

  # Method to return a sorted list of the resources available and its cloud id.
  def self.all_cloud_resource_types
    cloud_resource_types = []
    Cloud.all.each do |cloud|
      CloudResourceType.join_with_clouds(self, cloud).each do |resource|
        cloud_resource_types << ["#{cloud.name} #{resource.display_string}", "#{cloud.id}:#{resource.id}"]
      end
    end
    cloud_resource_types.sort!
  end

  # Method to return a string for the cloud resource type with its properties
  def display_string
    display = [self.name]
    display << self.description if self.description && self.type == 'StorageType'
    display << self.software if self.software && self.type == 'DatabaseType'
    cpu = self.cpu_values_string
    display << "CPU: #{cpu}" unless cpu.blank? || self.type == 'StorageType'
    display << "RAM: #{self.memory} GB" if self.memory && self.type != 'StorageType'
    hdd = self.hdd_values_string
    display << "HDD: #{hdd}" unless hdd.blank?
    display << self.operating_system if self.operating_system && self.type != 'StorageType'
    display.join(', ')
  end

end
