class CloudMaker
  def self.create_test_clouds
    create_cloud_provider_1
    create_cloud_provider_2
    create_empty_cloud
  end

  private
  def self.create_cloud_provider_1
    return if CloudProvider.find_by_name('Test Provider 1') # Don't create test clouds if already there
    provider1 = CloudProvider.create!(:name => 'Test Provider 1')

    cloud1 = Cloud.new(:name => 'Test Cloud 1', :location => 'New York, USA', :billing_currency => 'USD')
    cloud1.cloud_provider = provider1
    cloud1.save!

    data_out_ccs = CloudCostStructure.create!(:name => 'data_out', :units => 'per.1.gbs')
    data_out_tier = CloudCostTier.new(:cost => 0.1)
    data_out_tier.cloud_cost_structure = data_out_ccs
    data_out_tier.save!

    data_in_ccs = CloudCostStructure.create!(:name => 'data_in', :units => 'per.1.gbs')
    data_in_tier = CloudCostTier.new(:cost => 0.2)
    data_in_tier.cloud_cost_structure = data_in_ccs
    data_in_tier.save!

    # StorageType
    storage_type = StorageType.create!(:name => 'Test StorageType 1')
    storage_ccs = CloudCostStructure.create!(:name => 'storage_size', :units => 'per.1.gbs.per.1.months')
    storage_tier = CloudCostTier.new(:cost => 0.3)
    storage_tier.cloud_cost_structure = storage_ccs
    storage_tier.save!
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud1
    cloud_cost_scheme.cloud_resource_type = storage_type
    cloud_cost_scheme.cloud_cost_structure = storage_ccs
    cloud_cost_scheme.save!
    storage_ccs = CloudCostStructure.create!(:name => 'read_request', :units => 'per.10.requests')
    storage_tier = CloudCostTier.new(:cost => 0.4)
    storage_tier.cloud_cost_structure = storage_ccs
    storage_tier.save!
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud1
    cloud_cost_scheme.cloud_resource_type = storage_type
    cloud_cost_scheme.cloud_cost_structure = storage_ccs
    cloud_cost_scheme.save!
    storage_ccs = CloudCostStructure.create!(:name => 'write_request', :units => 'per.100.requests')
    storage_tier = CloudCostTier.new(:cost => 0.5)
    storage_tier.cloud_cost_structure = storage_ccs
    storage_tier.save!
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud1
    cloud_cost_scheme.cloud_resource_type = storage_type
    cloud_cost_scheme.cloud_cost_structure = storage_ccs
    cloud_cost_scheme.save!

    # ServerType
    server_type = ServerType.create!(:name => 'Test ServerType 1')
    server_ccs = CloudCostStructure.create!(:name => 'instance_hour', :units => 'per.1.hours')
    server_tier = CloudCostTier.new(:cost => 0.6)
    server_tier.cloud_cost_structure = server_ccs
    server_tier.save!
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud1
    cloud_cost_scheme.cloud_resource_type = server_type
    cloud_cost_scheme.cloud_cost_structure = server_ccs
    cloud_cost_scheme.save!

    # DatabaseType
    database_type = DatabaseType.create!(:name => 'Test DatabaseType 1')
    database_ccs = CloudCostStructure.create!(:name => 'instance_hour', :units => 'per.1.hours')
    database_tier = CloudCostTier.new(:cost => 0.7)
    database_tier.cloud_cost_structure = database_ccs
    database_tier.save!
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud1
    cloud_cost_scheme.cloud_resource_type = database_type
    cloud_cost_scheme.cloud_cost_structure = database_ccs
    cloud_cost_scheme.save!
    database_ccs = CloudCostStructure.create!(:name => 'storage_size', :units => 'per.1.gbs.per.1.months')
    database_tier = CloudCostTier.new(:cost => 0.8)
    database_tier.cloud_cost_structure = database_ccs
    database_tier.save!
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud1
    cloud_cost_scheme.cloud_resource_type = database_type
    cloud_cost_scheme.cloud_cost_structure = database_ccs
    cloud_cost_scheme.save!
    database_ccs = CloudCostStructure.create!(:name => 'transaction', :units => 'per.1000.transactions')
    database_tier = CloudCostTier.new(:cost => 0.9)
    database_tier.cloud_cost_structure = database_ccs
    database_tier.save!
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud1
    cloud_cost_scheme.cloud_resource_type = database_type
    cloud_cost_scheme.cloud_cost_structure = database_ccs
    cloud_cost_scheme.save!

    [storage_type, server_type, database_type].each do |resource_type|
      cloud_cost_scheme = CloudCostScheme.new()
      cloud_cost_scheme.cloud = cloud1
      cloud_cost_scheme.cloud_resource_type = resource_type
      cloud_cost_scheme.cloud_cost_structure = data_out_ccs
      cloud_cost_scheme.save!

      cloud_cost_scheme = CloudCostScheme.new()
      cloud_cost_scheme.cloud = cloud1
      cloud_cost_scheme.cloud_resource_type = resource_type
      cloud_cost_scheme.cloud_cost_structure = data_in_ccs
      cloud_cost_scheme.save!
    end
  end

  def self.create_cloud_provider_2
    return if CloudProvider.find_by_name('Test Provider 2') # Don't create test clouds if already there
    provider2 = CloudProvider.create!(:name => 'Test Provider 2')

    cloud2 = Cloud.new(:name => 'Test Cloud 2', :location => 'Santa Barbara, USA', :billing_currency => 'USD')
    cloud2.cloud_provider = provider2
    cloud2.save!

    data_out_ccs = CloudCostStructure.create!(:name => 'data_out', :units => 'per.1.gbs')
    data_out_tier = CloudCostTier.new(:upto => 100, :cost => 0.01)
    data_out_tier.cloud_cost_structure = data_out_ccs
    data_out_tier.save!
    data_out_tier = CloudCostTier.new(:upto => 200, :cost => 0.02)
    data_out_tier.cloud_cost_structure = data_out_ccs
    data_out_tier.save!
    data_out_tier = CloudCostTier.new(:cost => 0.3)
    data_out_tier.cloud_cost_structure = data_out_ccs
    data_out_tier.save!

    data_in_ccs = CloudCostStructure.create!(:name => 'data_in', :units => 'per.1.gbs')
    data_in_tier = CloudCostTier.new(:upto => 50, :cost => 0)
    data_in_tier.cloud_cost_structure = data_in_ccs
    data_in_tier.save!
    data_in_tier = CloudCostTier.new(:upto => 75, :cost => 0.03)
    data_in_tier.cloud_cost_structure = data_in_ccs
    data_in_tier.save!
    data_in_tier = CloudCostTier.new(:cost => 0.04)
    data_in_tier.cloud_cost_structure = data_in_ccs
    data_in_tier.save!

    # StorageType
    storage_type2 = StorageType.create!(:name => 'Test StorageType 2')
    storage_ccs = CloudCostStructure.create!(:name => 'storage_size', :units => 'per.1.gbs.per.1.months')
    storage_tier = CloudCostTier.new(:upto => 45, :cost => 0.6)
    storage_tier.cloud_cost_structure = storage_ccs
    storage_tier.save!
    storage_tier = CloudCostTier.new(:upto => 70, :cost => 0.7)
    storage_tier.cloud_cost_structure = storage_ccs
    storage_tier.save!
    storage_tier = CloudCostTier.new(:cost => 0.01)
    storage_tier.cloud_cost_structure = storage_ccs
    storage_tier.save!
    # Add the tiers in an odd order to make sure the deployment_cost_report sorts them correctly by upto
    storage_tier = CloudCostTier.new(:upto => 30, :cost => 0.5)
    storage_tier.cloud_cost_structure = storage_ccs
    storage_tier.save!

    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud2
    cloud_cost_scheme.cloud_resource_type = storage_type2
    cloud_cost_scheme.cloud_cost_structure = storage_ccs
    cloud_cost_scheme.save!

    # Test ServerType 2 has a $10/month fee + $100/year reservation
    server_type2 = ServerType.create!(:name => 'Test ServerType 2')
    pattern = Pattern.create!(:name => 'reservation cost')
    rule = Rule.new(:rule_type => 'temporary', :year => 'every.1.year', :variation => '+', :value => 100)
    rule.pattern = pattern
    rule.save!
    server_ccs = CloudCostStructure.create!(:name => 'instance_hour', :units => 'per.1.hours',
                                            :recurring_costs_monthly_baseline => 10)
    server_ccs.add_patterns('recurring_costs_monthly_baseline', [pattern])
    server_tier = CloudCostTier.new(:cost => 0)
    server_tier.cloud_cost_structure = server_ccs
    server_tier.save!
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud2
    cloud_cost_scheme.cloud_resource_type = server_type2
    cloud_cost_scheme.cloud_cost_structure = server_ccs
    cloud_cost_scheme.save!

    # Test ServerType 3 has an hourly charge + 3-yearly reservation
    server_type3 = ServerType.create!(:name => 'Test ServerType 3')
    pattern = Pattern.create!(:name => 'reservation cost')
    rule = Rule.new(:rule_type => 'temporary', :year => 'every.3.year', :variation => '+', :value => 80)
    rule.pattern = pattern
    rule.save!
    server_ccs = CloudCostStructure.create!(:name => 'instance_hour', :units => 'per.1.hours')
    server_ccs.add_patterns('recurring_costs_monthly_baseline', [pattern])
    server_tier = CloudCostTier.new(:cost => 0.05)
    server_tier.cloud_cost_structure = server_ccs
    server_tier.save!
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud2
    cloud_cost_scheme.cloud_resource_type = server_type3
    cloud_cost_scheme.cloud_cost_structure = server_ccs
    cloud_cost_scheme.save!

    # Test ServerType 4 has an hourly charge
    server_type4 = ServerType.create!(:name => 'Test ServerType 4')
    server_ccs = CloudCostStructure.create!(:name => 'instance_hour', :units => 'per.1.hours')
    server_tier = CloudCostTier.new(:cost => 0.07)
    server_tier.cloud_cost_structure = server_ccs
    server_tier.save!
    cloud_cost_scheme = CloudCostScheme.new()
    cloud_cost_scheme.cloud = cloud2
    cloud_cost_scheme.cloud_resource_type = server_type4
    cloud_cost_scheme.cloud_cost_structure = server_ccs
    cloud_cost_scheme.save!

    [storage_type2, server_type2, server_type3, server_type4].each do |resource_type|
      cloud_cost_scheme = CloudCostScheme.new()
      cloud_cost_scheme.cloud = cloud2
      cloud_cost_scheme.cloud_resource_type = resource_type
      cloud_cost_scheme.cloud_cost_structure = data_out_ccs
      cloud_cost_scheme.save!

      cloud_cost_scheme = CloudCostScheme.new()
      cloud_cost_scheme.cloud = cloud2
      cloud_cost_scheme.cloud_resource_type = resource_type
      cloud_cost_scheme.cloud_cost_structure = data_in_ccs
      cloud_cost_scheme.save!
    end
  end

  def self.create_empty_cloud
    return if CloudProvider.find_by_name('Empty Provider') # Don't create test clouds if already there
    provider = CloudProvider.create!(:name => 'Empty Provider')
    cloud = Cloud.new(:name => 'Empty Cloud')
    cloud.cloud_provider = provider
    cloud.save!
  end
end