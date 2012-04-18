class Scraper::Rackspace
  # Rackspace server and database types share the same details
  @@server_type_details = {
      "256"   => {:name => '256MB RAM', :cpu_architecture => 'X64', :local_disk_size => 10, :memory => 0.25},
      "512"   => {:name => '512MB RAM', :cpu_architecture => 'X64', :local_disk_size => 20, :memory => 0.5},
      "1024"  => {:name => '1,024MB RAM', :cpu_architecture => 'X64', :local_disk_size => 40, :memory => 1},
      "2048"  => {:name => '2,048MB RAM', :cpu_architecture => 'X64', :local_disk_size => 80, :memory => 2},
      "4096"  => {:name => '4,096MB RAM', :cpu_architecture => 'X64', :local_disk_size => 160, :memory => 4},
      "8192"  => {:name => '8,192MB RAM', :cpu_architecture => 'X64', :local_disk_size => 320, :memory => 8},
      "15872" => {:name => '15,872MB RAM', :cpu_architecture => 'X64', :local_disk_size => 620, :memory => 15.5},
      "30720" => {:name => '30,720MB RAM', :cpu_architecture => 'X64', :local_disk_size => 1200, :memory => 30}
  }

  @@costs = {
      # From http://www.rackspace.com/script/serverscalc.js and Rackspace USA cloud site
      'USA' => {
          'Linux' => {
              '256'  => 0.015,
              '512'  => 0.03,
              '1024' => 0.06,
              '2048' => 0.12,
              '4096' => 0.24,
              '8192' => 0.48,
              '15872'=> 0.96,
              '30720'=> 1.80
          },
          'Windows' => {
              '1024' => 0.08,
              '2048' => 0.16,
              '4096' => 0.32,
              '8192' => 0.58,
              '15872'=> 1.08,
              '30720'=> 2.16
          },
          'SQL Server 2008 R2 Web Edition' => {
              '2048'  => 0.06 + 0.16,
              '4096'  => 0.06 + 0.32,
              '8192'  => 0.06 + 0.58,
              '15872' => 0.06 + 1.08,
              '30720' => 0.09 + 2.16
          },
          'SQL Server 2008 R2 Standard Edition' => {
              '2048'  => 0.72 + 0.16,
              '4096'  => 0.72 + 0.32,
              '8192'  => 0.72 + 0.58,
              '15872' => 0.72 + 1.08,
              '30720' => 1.08 + 2.16
          },
          'storage_size' => 0.15,
          'data_out'	=> 0.18
      },
      # From http://c3084972.r72.cf0.rackcdn.com/calc_servers.js and Rackspace UK cloud site
      'UK' => {
          'Linux' => {
              '256'   => 0.01,
              '512'   => 0.02,
              '1024'  => 0.04,
              '2048'  => 0.08,
              '4096'  => 0.16,
              '8192'  => 0.32,
              '15872' => 0.64,
              '30720' => 1.20
          },
          'Windows' => {
              '1024'  => 0.052,
              '2048'  => 0.104,
              '4096'  => 0.208,
              '8192'  => 0.416,
              '15872' => 0.832,
              '30720' => 1.58
          },
          'SQL Server 2008 R2 Web Edition' => {
              '2048'  => 0.04 + 0.104,
              '4096'  => 0.04 + 0.208,
              '8192'  => 0.04 + 0.416,
              '15872' => 0.04 + 0.832,
              '30720' => 0.04 + 1.58
          },
          'SQL Server 2008 R2 Standard Edition' => {
              '2048'  => 0.45 + 0.104,
              '4096'  => 0.45 + 0.208,
              '8192'  => 0.45 + 0.416,
              '15872' => 0.45 + 0.832,
              '30720' => 0.45 + 1.58
          },
          'storage_size' => 0.11,
          'data_out' => 0.12
      }
  }

  def self.scrape
    raise AppExceptions::ScraperError.new("The Rackspace cloud provider already exists in the DB. " +
                                          "This scraper only supports adding new records for Rackspace for now.") if CloudProvider.find_by_name('Rackspace')
    old_count = Scraper::Helper.get_db_table_count

    rackspace = CloudProvider.create!(:name => 'Rackspace')
    rackspace.update_attributes(:website => 'http://www.rackspace.com')

    cloud = Cloud.new(:name => 'Rackspace USA', :location => 'Chicago and Dallas, USA', :billing_currency => 'USD')
    cloud.cloud_provider = rackspace
    cloud.save!
    self.add_cloud_resources(cloud, 'USA')

    cloud = Cloud.new(:name => 'Rackspace UK', :location => 'UK', :billing_currency => 'GBP')
    cloud.cloud_provider = rackspace
    cloud.save!
    self.add_cloud_resources(cloud, 'UK')

    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 1,
                                                     'Cloud' => 2,
                                                     'ServerType' => 14,
                                                     'StorageType' => 1,
                                                     'DatabaseType' => 10,
                                                     'CloudCostStructure' => 52,
                                                     'CloudCostTier' => 52,
                                                     'CloudCostScheme' => 100})
  end

  def self.add_cloud_resources(cloud, costs_key)
    # data_out
    data_out_ccs = CloudCostStructure.create!(:name => 'data_out', :units => 'per.1.gbs')
    data_out_tier = CloudCostTier.new(:cost => @@costs[costs_key]['data_out'])
    data_out_tier.cloud_cost_structure = data_out_ccs
    data_out_tier.save!


    # Create StorageType if necessary
    params = {:name => 'Cloud Files'}
    storage_type = StorageType.where(params).first
    storage_type ||= StorageType.create!(params)


    # Add storage_size cost
    storage_ccs = CloudCostStructure.create!(:name => 'storage_size', :units => 'per.1.gbs.per.1.months')
    storage_tier = CloudCostTier.new(:cost => @@costs[costs_key]['storage_size'])
    storage_tier.cloud_cost_structure = storage_ccs
    storage_tier.save!
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud
    cloud_cost_scheme.cloud_resource_type = storage_type
    cloud_cost_scheme.cloud_cost_structure = storage_ccs
    cloud_cost_scheme.save!

    # Add data_out costs to storage
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud
    cloud_cost_scheme.cloud_resource_type = storage_type
    cloud_cost_scheme.cloud_cost_structure = data_out_ccs
    cloud_cost_scheme.save!


    # Add server_types
    ['Linux', 'Windows'].each do |os|
      @@costs[costs_key][os].each do |server_type, cost|
        # Create ServerType if necessary
        params = @@server_type_details[server_type].merge(:operating_system => os)
        server_type = ServerType.where(params).first
        server_type ||= ServerType.create!(params)

        # Add instance_hour cost
        server_ccs = CloudCostStructure.create!(:name => 'instance_hour', :units => 'per.1.hours')
        server_tier = CloudCostTier.new(:cost => cost)
        server_tier.cloud_cost_structure = server_ccs
        server_tier.save!
        cloud_cost_scheme = CloudCostScheme.new()
        cloud_cost_scheme.cloud = cloud
        cloud_cost_scheme.cloud_resource_type = server_type
        cloud_cost_scheme.cloud_cost_structure = server_ccs
        cloud_cost_scheme.save!

        # Add data_out costs to server
        cloud_cost_scheme = CloudCostScheme.new()
        cloud_cost_scheme.cloud = cloud
        cloud_cost_scheme.cloud_resource_type = server_type
        cloud_cost_scheme.cloud_cost_structure = data_out_ccs
        cloud_cost_scheme.save!
      end
    end

    # Add database_types
    ['SQL Server 2008 R2 Web Edition', 'SQL Server 2008 R2 Standard Edition'].each do |software|
      @@costs[costs_key][software].each do |database_type, cost|
        # Create DatabaseType if necessary
        params = @@server_type_details[database_type].merge(:operating_system => 'Windows', :software => software)
        database_type = DatabaseType.where(params).first
        database_type ||= DatabaseType.create!(params)

        # Add instance_hour cost
        database_ccs = CloudCostStructure.create!(:name => 'instance_hour', :units => 'per.1.hours')
        database_tier = CloudCostTier.new(:cost => cost)
        database_tier.cloud_cost_structure = database_ccs
        database_tier.save!
        cloud_cost_scheme = CloudCostScheme.new()
        cloud_cost_scheme.cloud = cloud
        cloud_cost_scheme.cloud_resource_type = database_type
        cloud_cost_scheme.cloud_cost_structure = database_ccs
        cloud_cost_scheme.save!

        # Add data_out costs to database
        cloud_cost_scheme = CloudCostScheme.new()
        cloud_cost_scheme.cloud = cloud
        cloud_cost_scheme.cloud_resource_type = database_type
        cloud_cost_scheme.cloud_cost_structure = data_out_ccs
        cloud_cost_scheme.save!
      end
    end

  end
end