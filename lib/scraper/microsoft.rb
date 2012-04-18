class Scraper::Microsoft
  @@microsoft = nil

  @@clouds = {
      'north_europe'     => {:name => 'Azure North Europe', :location => 'Dublin, Ireland'},
      'western_europe'   => {:name => 'Azure Western Europe', :location => 'Amsterdam, Netherlands'},
      'north_central_us' => {:name => 'Azure North Central US', :location => 'Chicago, IL, USA'},
      'south_central_us' => {:name => 'Azure South Central US', :location => 'San Antonio, TX, USA'},
      'east_asia'        => {:name => 'Azure East Asia', :location => 'Hong King, China'},
      'southeast_asia'   => {:name => 'Azure Southeast Asia', :location => 'Singapore'}
  }

  @@server_type_details = {
      "extra_small" => {:name => 'Extra Small', :cpu_speed => 1.0, :cpu_architecture => 'X64', :local_disk_size => 20, :memory => 0.75},
      "small"       => {:name => 'Small', :cpu_speed => 1.6, :cpu_count => 1, :cpu_architecture => 'X64', :local_disk_size => 225, :memory => 1.75},
      "medium"      => {:name => 'Medium', :cpu_speed => 1.6, :cpu_count => 2, :cpu_architecture => 'X64', :local_disk_size => 490, :memory => 3.5},
      "large"       => {:name => 'Large', :cpu_speed => 1.6, :cpu_count => 4, :cpu_architecture => 'X64', :local_disk_size => 1000, :memory => 7},
      "extra_large" => {:name => 'Extra Large', :cpu_speed => 1.6, :cpu_count => 8, :cpu_architecture => 'X64', :local_disk_size => 2048, :memory => 14}
  }

  @@storage_type_details = {
      'blob'        => {:name => 'BLOB Storage', :description => 'Binary Large Object storage'},
      'table'       => {:name => 'Table Storage', :description => 'NoSQL data store'},
      'queue'       => {:name => 'Queue Storage', :description => 'Message queue store'},
      'azure_drive' => {:name => 'Windows Azure Drive', :description => 'Mountable virtual HD'},
  }

  @@database_type_details = {
      "web_edition" => {:name => 'Web Edition (upto 5 GB)', :software => 'SQL Azure'},
      "business_edition" => {:name => 'Business Edition (upto 150 GB)', :software => 'SQL Azure'}
  }

  # Following cost details from http://www.windowsazure.com/en-us/pricing/details/
  # Standard pay-as-you-go costs
  @@payg_costs = {
      'extra_small'      => 0.04,
      'small'            => 0.12,
      'medium'           => 0.24,
      'large'            => 0.48,
      'extra_large'      => 0.96,
      'storage'          => {
          'storage_size' => {:cost => 0.14, :units => 'per.1.gbs.per.1.months'},
          'read_request' => {:cost => 0.01, :units => 'per.10000.requests'},
          'write_request'=> {:cost => 0.01, :units => 'per.10000.requests'}},
      'web_edition'      => {
          'storage_size' => {:units => 'per.1.gbs.per.1.months', :tiers => [
              {:upto => 5, :cost => 9.99},
              {:cost => 0}]}}, # The max size is 5GB on web edition, which can be enforced with tiers
      'business_edition' => {
          'storage_size' => {:units => 'per.10.gbs.per.1.months', :tiers => [
              {:upto => 50, :cost => 99.99},
              {:cost => 0}]}}, # They charge a max of 499.99 on business edition, so we can represent that with tiers
      'data_out'         => {
          'north_europe'     => 0.12,
          'western_europe'   => 0.12,
          'north_central_us' => 0.12,
          'south_central_us' => 0.12,
          'east_asia'        => 0.19,
          'southeast_asia'   => 0.19}
  }

  def self.scrape
    if CloudProvider.find_by_name('Microsoft')
      update_prices
    else
      initial_scrape
      update_prices
    end
  end

  def self.update_prices
    old_count = Scraper::Helper.get_db_table_count

    ['Pay-As-You-Go Web Edition (upto 5 GB)', 'Pay-As-You-Go Business Edition (upto 150 GB)'].each do |db_type_name|
      db_type = DatabaseType.find_by_name(db_type_name)
      db_type.cloud_cost_structures.where(:name => 'storage_size', :valid_until => nil).each do |ccs|
        new_ccs = ccs.dup
        new_ccs.units = 'per.1.gbs.per.1.months' # Old pricing scheme had per.10gb for business edition
        new_ccs.save!
        # Invalidate old prices
        ccs.update_attributes!(:valid_until => Time.now)

        if db_type_name == 'Pay-As-You-Go Web Edition (upto 5 GB)'
          tiers = [{:upto => 1, :cost => 9.99},
                   {:upto => 5, :cost => 3.996},
                   {:cost => 0}]
        else
          tiers = [{:upto => 1, :cost => 9.99},
                   {:upto => 10, :cost => 3.996},
                   {:upto => 50, :cost => 1.998},
                   {:upto => 150, :cost => 0.999},
                   {:cost => 0}]
        end

        tiers.each do |tier|
          database_tier = CloudCostTier.new(tier)
          database_tier.cloud_cost_structure = new_ccs
          database_tier.save!
        end

        cloud_cost_scheme = CloudCostScheme.new()
        cloud_cost_scheme.cloud = ccs.clouds.first
        cloud_cost_scheme.cloud_resource_type = ccs.cloud_resource_types.first
        cloud_cost_scheme.cloud_cost_structure = new_ccs
        cloud_cost_scheme.save!
      end
    end

    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 0,
                                                     'Cloud' => 0,
                                                     'ServerType' => 0,
                                                     'StorageType' => 0,
                                                     'DatabaseType' => 0,
                                                     'CloudCostStructure' => 12,
                                                     'CloudCostTier' => 48,
                                                     'CloudCostScheme' => 12})
  end

  def self.initial_scrape
    old_count = Scraper::Helper.get_db_table_count

    @@microsoft = CloudProvider.create!(:name => 'Microsoft')
    @@microsoft.update_attributes(:website => 'http://www.windowsazure.com')

    @@clouds.keys.each {|cloud| add_cloud_resources(cloud, 'Pay-As-You-Go')}

    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 1,
                                                     'Cloud' => 6,
                                                     'ServerType' => 5,
                                                     'StorageType' => 4,
                                                     'DatabaseType' => 2,
                                                     'CloudCostStructure' => 120,
                                                     'CloudCostTier' => 132,
                                                     'CloudCostScheme' => 180})
  end

  def self.add_cloud_resources(cloud_key, resource_name_prefix)
    cloud = Cloud.new(@@clouds[cloud_key].merge(:billing_currency => 'USD'))
    cloud.cloud_provider = @@microsoft
    cloud.save!

    # data_out
    data_out_ccs = CloudCostStructure.create!(:name => 'data_out', :units => 'per.1.gbs')
    data_out_tier = CloudCostTier.new(:cost => @@payg_costs['data_out'][cloud_key])
    data_out_tier.cloud_cost_structure = data_out_ccs
    data_out_tier.save!

    # Add StorageTypes
    @@storage_type_details.each do |storage_type_key, storage_type_params|
      # Create StorageType if necessary
      storage_type_name = "#{resource_name_prefix} #{storage_type_params[:name]}"
      params = storage_type_params.merge(:name => storage_type_name)
      storage_type = StorageType.where(params).first
      storage_type ||= StorageType.create!(params)

      # Add storage costs
      @@payg_costs['storage'].each do |k, v|
        storage_ccs = CloudCostStructure.create!(:name => k, :units => v[:units])
        storage_tier = CloudCostTier.new(:cost => v[:cost])
        storage_tier.cloud_cost_structure = storage_ccs
        storage_tier.save!
        cloud_cost_scheme = CloudCostScheme.new()
        cloud_cost_scheme.cloud = cloud
        cloud_cost_scheme.cloud_resource_type = storage_type
        cloud_cost_scheme.cloud_cost_structure = storage_ccs
        cloud_cost_scheme.save!
      end

      # Add data_out costs to storage
      cloud_cost_scheme = CloudCostScheme.new()
      cloud_cost_scheme.cloud = cloud
      cloud_cost_scheme.cloud_resource_type = storage_type
      cloud_cost_scheme.cloud_cost_structure = data_out_ccs
      cloud_cost_scheme.save!
    end

    # Add ServerTypes
    @@server_type_details.each do |server_type_key, server_type_params|
      # Create ServerType if necessary
      server_type_name = "#{resource_name_prefix} #{server_type_params[:name]}"
      params = server_type_params.merge(:name => server_type_name)
      server_type = ServerType.where(params).first
      server_type ||= ServerType.create!(params)

      # Add instance_hour cost
      server_ccs = CloudCostStructure.create!(:name => 'instance_hour', :units => 'per.1.hours')
      server_tier = CloudCostTier.new(:cost => @@payg_costs[server_type_key])
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

    # Add DatabaseTypes
    @@database_type_details.each do |database_type_key, database_type_params|
      # Create DatabaseType if necessary
      database_type_name = "#{resource_name_prefix} #{database_type_params[:name]}"
      params = database_type_params.merge(:name => database_type_name)
      database_type = DatabaseType.where(params).first
      database_type ||= DatabaseType.create!(params)

      # Add database costs
      @@payg_costs[database_type_key].each do |k, v|
        database_ccs = CloudCostStructure.create!(:name => k, :units => v[:units])

        if v[:tiers]
          v[:tiers].each do |tier|
            database_tier = CloudCostTier.new(tier)
            database_tier.cloud_cost_structure = database_ccs
            database_tier.save!
          end
        else
          database_tier = CloudCostTier.new(:cost => v[:cost])
          database_tier.cloud_cost_structure = database_ccs
          database_tier.save!
        end

        cloud_cost_scheme = CloudCostScheme.new()
        cloud_cost_scheme.cloud = cloud
        cloud_cost_scheme.cloud_resource_type = database_type
        cloud_cost_scheme.cloud_cost_structure = database_ccs
        cloud_cost_scheme.save!
      end

      # Add data_out costs to database
      cloud_cost_scheme = CloudCostScheme.new()
      cloud_cost_scheme.cloud = cloud
      cloud_cost_scheme.cloud_resource_type = database_type
      cloud_cost_scheme.cloud_cost_structure = data_out_ccs
      cloud_cost_scheme.save!
    end
  end
end