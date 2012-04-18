require 'spec_helper'

describe CloudResourceType do

  it "should be invalid without a name" do
    cloud_resource_type = CloudResourceType.new()
    cloud_resource_type.should have(1).error_on(:name)
    cloud_resource_type.errors.count.should == 1
    cloud_resource_type.should_not be_valid
  end

  context "tests for cpu_values_string method" do
    it "Should return an empty string - no cpu, speed or architecture" do
      server_type = ServerType.new()
      server_type.cpu_values_string.should == ''
    end

    it "Should return an architecture type only - no cpu or speed" do
      server_type = ServerType.new(:cpu_architecture => 'X86')
      server_type.cpu_values_string.should == 'X86 architecture'
    end

    it "Should return a CPU count only - no speed or architecture" do
      server_type = ServerType.new(:cpu_count => 2)
      server_type.cpu_values_string.should == '2 x CPU'
    end

    it "Should return CPU speed only - no count or architecture" do
      server_type = ServerType.new(:cpu_speed => 1)
      server_type.cpu_values_string.should == '1.0 GHz'
    end

    it "Should return CPU count and speed - no architecture" do
      server_type = ServerType.new(:cpu_speed => 1, :cpu_count => 3)
      server_type.cpu_values_string.should == '3 x 1.0 GHz'
    end

    it "Should return CPU count, speed and architecture" do
      server_type = ServerType.make!()
      server_type.cpu_values_string.should == '1 x 1.0 GHz (X86)'
    end
  end

  context "tests for hdd_values_string method" do
    it "Should return an empty string - no local storage" do
      server_type = ServerType.new()
      server_type.hdd_values_string.should == ''
    end

    it "Should return the local storage size only - no local disk count" do
      server_type = ServerType.new(:local_disk_size => 22)
      server_type.hdd_values_string.should == '22.0 GB'
    end

    it "Should return the local storage count only - no local disk size" do
      server_type = ServerType.new(:local_disk_count => 3)
      server_type.hdd_values_string.should == '3 x HDD'
    end

    it "Should return the local disk string - size and count" do
      server_type = ServerType.make!()
      server_type.hdd_values_string.should == '1 x 160.0 GB'
    end
  end

  context "tests for display_string method" do
    it "should display string correctly for a server type" do
      server_type = ServerType.make!
      server_type.display_string.should == 'On Demand Standard Small, CPU: 1 x 1.0 GHz (X86), RAM: 1.7 GB, HDD: 1 x 160.0 GB, Linux'
    end

    it "should display string correctly for a storage type" do
      storage_type = StorageType.new(:name => 'Expandable storage',
                                     :description => 'Extend your storage',
                                     :local_disk_count => 2,
                                     :local_disk_size => 40,
                                     :cpu_count => 1,
                                     :operating_system => 'Windows')
      storage_type.display_string.should == 'Expandable storage, Extend your storage, HDD: 2 x 40.0 GB'
    end

    it "should display string correctly for a database type" do
      database_type = DatabaseType.make!
      database_type.display_string.should == 'On Demand Standard Small, MySQL, CPU: 1 x 1.0 GHz (X64), RAM: 1.7 GB'
    end
  end

  it "should test all_cloud_resource_types method" do
    cloud_provider = CloudProvider.make!
    cloud = Cloud.make!(:name => 'TestCloud', :cloud_provider => cloud_provider)
    server_type = ServerType.make!
    cost_structure = CloudCostStructure.make!
    CloudCostScheme.make!(:cloud => cloud, :cloud_resource_type => server_type, :cloud_cost_structure => cost_structure)

    ServerType.all_cloud_resource_types.include?(
        ['TestCloud On Demand Standard Small, CPU: 1 x 1.0 GHz (X86), RAM: 1.7 GB, HDD: 1 x 160.0 GB, Linux', "#{cloud.id}:#{server_type.id}"]).should == true
  end

end