require "open-uri"
require "net/http"

class Scraper::Aws

  DATA_TRANSFER_URL   = 'http://aws.amazon.com/ec2/pricing/pricing-data-transfer.json'
  EBS_URL             = 'http://aws.amazon.com/ec2/pricing/pricing-ebs.json'
  S3_URL              = 'http://aws.amazon.com/s3/pricing/pricing-storage.json'
  S3_REQUESTS_URL     = 'http://aws.amazon.com/s3/pricing/pricing-requests.json'
  ON_DEMAND_URL       = 'http://aws.amazon.com/ec2/pricing/pricing-on-demand-instances.json'
  LIGHT_RI_LINUX_URL  = 'http://aws.amazon.com/ec2/pricing/ri-light-linux.json'
  LIGHT_RI_MSWIN_URL  = 'http://aws.amazon.com/ec2/pricing/ri-light-mswin.json'
  MEDIUM_RI_LINUX_URL = 'http://aws.amazon.com/ec2/pricing/ri-medium-linux.json'
  MEDIUM_RI_MSWIN_URL = 'http://aws.amazon.com/ec2/pricing/ri-medium-mswin.json'
  HEAVY_RI_LINUX_URL  = 'http://aws.amazon.com/ec2/pricing/ri-heavy-linux.json'
  HEAVY_RI_MSWIN_URL  = 'http://aws.amazon.com/ec2/pricing/ri-heavy-mswin.json'
  # SQL Server
  SQL_SERVER_ON_DEMAND_URL       = 'http://aws.amazon.com/windows/pricing-on-demand-instances.json'
  SQL_SERVER_LIGHT_RESERVED_URL  = 'http://aws.amazon.com/windows/pricing-reserved-instances-low-utilization-windows-sql.json'
  SQL_SERVER_MEDIUM_RESERVED_URL = 'http://aws.amazon.com/windows/pricing-reserved-instances-windows-sql.json'
  SQL_SERVER_HEAVY_RESERVED_URL  = 'http://aws.amazon.com/windows/pricing-reserved-instances-high-utilization-windows-sql.json'
  # RDS-MySQL
  RDS_MYSQL_STANDARD_STORAGE_URL = 'http://aws.amazon.com/rds/pricing/mysql/pricing-provisioned-db-standard-deploy.json'
  RDS_MYSQL_MULTI_AZ_STORAGE_URL = 'http://aws.amazon.com/rds/pricing/mysql/pricing-provisioned-db-multiAZ-deploy.json'
  RDS_MYSQL_STANDARD_URL         = 'http://aws.amazon.com/rds/pricing/mysql/pricing-standard-deployments.json'
  RDS_MYSQL_MULTI_AZ_URL         = 'http://aws.amazon.com/rds/pricing/mysql/pricing-multiAZ-deployments.json'
  RDS_MYSQL_LIGHT_RESERVED_URL   = 'http://aws.amazon.com/rds/pricing/mysql/pricing-light-utilization-reserved-instances.json'
  RDS_MYSQL_MEDIUM_RESERVED_URL  = 'http://aws.amazon.com/rds/pricing/mysql/pricing-medium-utilization-reserved-instances.json'
  RDS_MYSQL_HEAVY_RESERVED_URL   = 'http://aws.amazon.com/rds/pricing/mysql/pricing-heavy-utilization-reserved-instances.json'
  # RDS-Oracle
  RDS_ORACLE_STANDARD_STORAGE_URL         = 'http://aws.amazon.com/rds/pricing/oracle/pricing-provisioned-db-standard-deploy.json'
  RDS_ORACLE_LICENSED_STANDARD_URL        = 'http://aws.amazon.com/rds/pricing/oracle/pricing-li-standard-deployments.json'
  RDS_ORACLE_BYOL_STANDARD_URL            = 'http://aws.amazon.com/rds/pricing/oracle/pricing-byol-standard-deployments.json'
  RDS_ORACLE_LICENSED_LIGHT_RESERVED_URL  = 'http://aws.amazon.com/rds/pricing/oracle/pricing-li-light-utilization-reserved-instances.json'
  RDS_ORACLE_LICENSED_MEDIUM_RESERVED_URL = 'http://aws.amazon.com/rds/pricing/oracle/pricing-li-medium-utilization-reserved-instances.json'
  RDS_ORACLE_LICENSED_HEAVY_RESERVED_URL  = 'http://aws.amazon.com/rds/pricing/oracle/pricing-li-heavy-utilization-reserved-instances.json'
  RDS_ORACLE_BYOL_LIGHT_RESERVED_URL      = 'http://aws.amazon.com/rds/pricing/oracle/pricing-byol-light-utilization-reserved-instances.json'
  RDS_ORACLE_BYOL_MEDIUM_RESERVED_URL     = 'http://aws.amazon.com/rds/pricing/oracle/pricing-byol-medium-utilization-reserved-instances.json'
  RDS_ORACLE_BYOL_HEAVY_RESERVED_URL      = 'http://aws.amazon.com/rds/pricing/oracle/pricing-byol-heavy-utilization-reserved-instances.json'

  @@aws = nil
  # The following 2 hashes will store a mapping of relevant CloudCostStructures for each region
  @@rds_storage_ccs = {
      'mysql_standard'  => {'storage_ccs' => {}, 'transaction_ccs' => {}},
      'mysql_multiaz'   => {'storage_ccs' => {}, 'transaction_ccs' => {}},
      'oracle_standard' => {'storage_ccs' => {}, 'transaction_ccs' => {}}
  }
  @@data_out_ccs = {}

  # Keys are the type/size of the Standard On-Demand Instances
  @@server_type_details = {
      "stdODI sm"                 => {:name => 'Standard Small', :cpu_architecture => 'X86', :cpu_speed => 1.0, :cpu_count => 1,
                                      :local_disk_size => 160, :memory => 1.7},
      "stdODI lg"                 => {:name => 'Standard Large', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 4,
                                      :local_disk_size => 850, :memory => 7.5},
      "stdODI xl"                 => {:name => 'Standard XLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 8,
                                      :local_disk_size => 1690, :memory => 15},
      "uODI u"                    => {:name => 'Micro', :cpu_architecture => 'X86/X64', :cpu_speed => 1.0, :cpu_count => 2,
                                      :local_disk_size => 0, :memory => 0.6},
      "hiMemODI xl"               => {:name => 'Hi-Memory XLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 6,
                                      :local_disk_size => 420, :memory => 17.1},
      "hiMemODI xxl"              => {:name => 'Hi-Memory XXLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 13,
                                      :local_disk_size => 850, :memory => 34.2},
      "hiMemODI xxxxl"            => {:name => 'Hi-Memory XXXXLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 26,
                                      :local_disk_size => 1690, :memory => 68.4},
      "hiCPUODI med"              => {:name => 'Hi-CPU Medium', :cpu_architecture => 'X86', :cpu_speed => 1.0, :cpu_count => 5,
                                      :local_disk_size => 350, :memory => 1.7},
      "hiCPUODI xl"               => {:name => 'Hi-CPU XLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 20,
                                      :local_disk_size => 1690, :memory => 7},
      "clusterComputeI xxxxl"     => {:name => 'Cluster Compute XXXXLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 33,
                                      :local_disk_size => 1690, :memory => 23, :description => '10 Gigabit Ethernet'},
      "clusterComputeI xxxxxxxxl" => {:name => 'Cluster Compute XXXXXXXXLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 88,
                                      :local_disk_size => 3370, :memory => 60.5, :description => '10 Gigabit Ethernet'},
      "clusterGPUI xxxxl"         => {:name => 'Cluster GPU XLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 33,
                                      :local_disk_size => 1690, :memory => 22, :description => '10 Gigabit Ethernet, 2 x NVIDIA Tesla Fermi M2050 GPUs'}
  }

  # Map the reserved server_type keys to the @@server_type_details as they share the same server details
  @@reserved_server_type_keys = {
      "stdResI sm"                => "stdODI sm",
      "stdResI lg"                => "stdODI lg",
      "stdResI xl"                => "stdODI xl",
      "uResI u"                   => "uODI u",
      "hiMemResI xl"              => "hiMemODI xl",
      "hiMemResI xxl"             => "hiMemODI xxl",
      "hiMemResI xxxxl"           => "hiMemODI xxxxl",
      "hiCPUResI med"             => "hiCPUODI med",
      "hiCPUResI xl"              => "hiCPUODI xl",
      "clusterCompResI xxxxl"     => "clusterComputeI xxxxl",
      "clusterCompResI xxxxxxxxl" => "clusterComputeI xxxxxxxxl",
      "clusterGPUResI xxxxl"      => "clusterGPUI xxxxl"
  }

  # Keys are the type/size of the Standard RDS Databases
  @@database_type_details = {
      "dbInstClass smDBInst"        => {:name => 'Small', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 1, :memory => 1.7},
      "dbInstClass lgDBInst"        => {:name => 'Large', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 4, :memory => 7.5},
      "dbInstClass xlDBInst"        => {:name => 'XLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 8, :memory => 15},
      "hiMemDBInstClass xlDBInst"   => {:name => 'Hi-Memory XLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 6, :memory => 17.1},
      "hiMemDBInstClass xxlDBInst"  => {:name => 'Hi-Memory XXLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 13, :memory => 34},
      "hiMemDBInstClass xxxxDBInst" => {:name => 'Hi-Memory XXXXLarge', :cpu_architecture => 'X64', :cpu_speed => 1.0, :cpu_count => 26, :memory => 68}
  }

  # Map the Standard/MultiAZ/Reserved database_type keys to the @@database_type_details as they share the same server details
  @@database_type_keys = {
      # Map the Standard keys to themselves so we can always use this map (and don't have to use conditionals to determine which key to use)
      "dbInstClass smDBInst"             => "dbInstClass smDBInst",
      "dbInstClass lgDBInst"             => "dbInstClass lgDBInst",
      "dbInstClass xlDBInst"             => "dbInstClass xlDBInst",
      "hiMemDBInstClass xlDBInst"        => "hiMemDBInstClass xlDBInst",
      "hiMemDBInstClass xxlDBInst"       => "hiMemDBInstClass xxlDBInst",
      "hiMemDBInstClass xxxxDBInst"      => "hiMemDBInstClass xxxxDBInst",
      # MultiAZ
      "multiAZDBInstClass smDBInst"      => "dbInstClass smDBInst",
      "multiAZDBInstClass lgDBInst"      => "dbInstClass lgDBInst",
      "multiAZDBInstClass xlDBInst"      => "dbInstClass xlDBInst",
      "multiAZHiMemInstClass xlDBInst"   => "hiMemDBInstClass xlDBInst",
      "multiAZHiMemInstClass xxlDBInst"  => "hiMemDBInstClass xxlDBInst",
      "multiAZHiMemInstClass xxxxDBInst" => "hiMemDBInstClass xxxxDBInst",
      # Standard Reserved
      "stdDeployRes sm"                  => "dbInstClass smDBInst",
      "stdDeployRes lg"                  => "dbInstClass lgDBInst",
      "stdDeployRes xl"                  => "dbInstClass xlDBInst",
      "stdDeployRes xlHiMem"             => "hiMemDBInstClass xlDBInst",
      "stdDeployRes xxlHiMem"            => "hiMemDBInstClass xxlDBInst",
      "stdDeployRes xxxxlHiMem"          => "hiMemDBInstClass xxxxDBInst",
      # MultiAZ Reserved
      "multiAZdeployRes sm"              => "dbInstClass smDBInst",
      "multiAZdeployRes lg"              => "dbInstClass lgDBInst",
      "multiAZdeployRes xl"              => "dbInstClass xlDBInst",
      "multiAZdeployRes xlHiMem"         => "hiMemDBInstClass xlDBInst",
      "multiAZdeployRes xxlHiMem"        => "hiMemDBInstClass xxlDBInst",
      "multiAZdeployRes xxxxlHiMem"      => "hiMemDBInstClass xxxxDBInst",
  }

  @@operating_systems = {
      'mswin'    => 'Windows',
      'linux'    => 'Linux/UNIX',
      'mswinSQL' => 'Windows & SQL Server'
  }

  @@clouds = {
      "us-east"    => {:name => 'AWS US-East', :location => 'Virginia, USA'},
      "us-west"    => {:name => 'AWS US-West (Northern California)', :location => 'Northern California, USA'},
      "us-west-2"  => {:name => 'AWS US-West (Oregon)', :location => 'Oregon, USA'},
      "eu-ireland" => {:name => 'AWS EU-Ireland', :location => 'Ireland'},
      "apac-sin"   => {:name => 'AWS Asia Pacific (Singapore)', :location => 'Singapore'},
      "apac-tokyo" => {:name => 'AWS Asia Pacific (Tokyo)', :location => 'Tokyo, Japan'},
      "sa-east-1"  => {:name => 'AWS South America (Sao Paulo)', :location => 'Sao Paulo, Brazil'}
  }

  # AWS switched to using new region names for some of their JSON files, so we need to map them back to the old ones
  @@region_names_map = {
    "us-east"        => "us-east",
    "us-west-1"      => "us-west",
    "us-west-2"      => "us-west-2",
    "eu-west-1"      => "eu-ireland",
    "ap-southeast-1" => "apac-sin",
    "ap-northeast-1" => "apac-tokyo",
    "sa-east-1"      => "sa-east-1"
  }

  def self.scrape
    @@aws = CloudProvider.find_or_create_by_name('AWS')
    @@aws.update_attributes!(:description => 'Amazon Web Services', :website => 'http://www.aws.amazon.com')

    # scrape data_outs, this also creates the clouds
    json = get_json(DATA_TRANSFER_URL)
    parse_data_transfer(json)

    old_count = Scraper::Helper.get_db_table_count
    # scrape On-Demand ServerTypes
    json = get_json(ON_DEMAND_URL)
    parse_on_demand(json, "On-Demand")
    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 0,
                                                     'Cloud' => 0,
                                                     'ServerType' => 0,
                                                     'StorageType' => 0,
                                                     'DatabaseType' => 0,
                                                     'CloudCostStructure' => 132,
                                                     'CloudCostTier' => 132,
                                                     'CloudCostScheme' => 264})
    old_count = Scraper::Helper.get_db_table_count
    # scrape SQL Server On-Demand ServerTypes
    json = get_json(SQL_SERVER_ON_DEMAND_URL)
    parse_sql_server_on_demand(json, "On-Demand")
    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 0,
                                                     'Cloud' => 0,
                                                     'ServerType' => 0,
                                                     'StorageType' => 0,
                                                     'DatabaseType' => 0,
                                                     'CloudCostStructure' => 45,
                                                     'CloudCostTier' => 45,
                                                     'CloudCostScheme' => 90})

    old_count = Scraper::Helper.get_db_table_count
    # scrape Reserved ServerTypes
    json = get_json(LIGHT_RI_LINUX_URL)
    parse_reserved(json, "Light-Utilization Reserved", 'linux')
    json = get_json(LIGHT_RI_MSWIN_URL)
    parse_reserved(json, "Light-Utilization Reserved", 'mswin')
    json = get_json(MEDIUM_RI_LINUX_URL)
    parse_reserved(json, "Medium-Utilization Reserved", 'linux')
    json = get_json(MEDIUM_RI_MSWIN_URL)
    parse_reserved(json, "Medium-Utilization Reserved", 'mswin')
    json = get_json(HEAVY_RI_LINUX_URL)
    parse_reserved(json, "Heavy-Utilization Reserved", 'linux')
    json = get_json(HEAVY_RI_MSWIN_URL)
    parse_reserved(json, "Heavy-Utilization Reserved", 'mswin')
    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 0,
                                                     'Cloud' => 0,
                                                     'ServerType' => 0,
                                                     'StorageType' => 0,
                                                     'DatabaseType' => 0,
                                                     'CloudCostStructure' => 792,
                                                     'CloudCostTier' => 792,
                                                     'CloudCostScheme' => 1584})

    old_count = Scraper::Helper.get_db_table_count
    # scrape SQL Server Reserved ServerTypes
    json = get_json(SQL_SERVER_LIGHT_RESERVED_URL)
    parse_reserved(json, "Light-Utilization Reserved", 'mswinSQL')
    json = get_json(SQL_SERVER_MEDIUM_RESERVED_URL)
    parse_reserved(json, "Medium-Utilization Reserved", 'mswinSQL')
    json = get_json(SQL_SERVER_HEAVY_RESERVED_URL)
    parse_reserved(json, "Heavy-Utilization Reserved", 'mswinSQL')
    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 0,
                                                     'Cloud' => 0,
                                                     'ServerType' => 0,
                                                     'StorageType' => 0,
                                                     'DatabaseType' => 0,
                                                     'CloudCostStructure' => 264,
                                                     'CloudCostTier' => 264,
                                                     'CloudCostScheme' => 528})

    old_count = Scraper::Helper.get_db_table_count
    # scrape EBS StorageTypes
    json = get_json(EBS_URL)
    parse_ebs(json)
    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 0,
                                                     'Cloud' => 0,
                                                     'ServerType' => 0,
                                                     'StorageType' => 0,
                                                     'DatabaseType' => 0,
                                                     'CloudCostStructure' => 21,
                                                     'CloudCostTier' => 21,
                                                     'CloudCostScheme' => 28})

    old_count = Scraper::Helper.get_db_table_count
    # scrape S3 StorageTypes
    s3_json = get_json(S3_URL)
    s3_requests_json = get_json(S3_REQUESTS_URL)
    parse_s3(s3_json, s3_requests_json)
    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 0,
                                                     'Cloud' => 0,
                                                     'ServerType' => 0,
                                                     'StorageType' => 0,
                                                     'DatabaseType' => 0,
                                                     'CloudCostStructure' => 42,
                                                     'CloudCostTier' => 112,
                                                     'CloudCostScheme' => 56})

    old_count = Scraper::Helper.get_db_table_count
    # scrape RDS storage costs
    json = get_json(RDS_MYSQL_STANDARD_STORAGE_URL)
    parse_rds_storage(json, 'mysql_standard')
    json = get_json(RDS_MYSQL_MULTI_AZ_STORAGE_URL)
    parse_rds_storage(json, 'mysql_multiaz')
    json = get_json(RDS_ORACLE_STANDARD_STORAGE_URL)
    parse_rds_storage(json, 'oracle_standard')
    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 0,
                                                     'Cloud' => 0,
                                                     'ServerType' => 0,
                                                     'StorageType' => 0,
                                                     'DatabaseType' => 0,
                                                     'CloudCostStructure' => 42,
                                                     'CloudCostTier' => 42,
                                                     'CloudCostScheme' => 0})

    old_count = Scraper::Helper.get_db_table_count
    # scrape RDS On-Demand database_types
    json = get_json(RDS_MYSQL_STANDARD_URL)
    parse_rds_on_demand(json, 'mysql_standard', "RDS On-Demand Standard", "MySQL")
    json = get_json(RDS_MYSQL_MULTI_AZ_URL)
    parse_rds_on_demand(json, 'mysql_multiaz', "RDS On-Demand Multi-AZ", "MySQL")
    json = get_json(RDS_ORACLE_LICENSED_STANDARD_URL)
    parse_rds_on_demand(json, 'oracle_standard', "RDS On-Demand License-Included", "Oracle")
    json = get_json(RDS_ORACLE_BYOL_STANDARD_URL)
    parse_rds_on_demand(json, 'oracle_standard', "RDS On-Demand Bring-Your-Own-License", "Oracle")
    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 0,
                                                     'Cloud' => 0,
                                                     'ServerType' => 0,
                                                     'StorageType' => 0,
                                                     'DatabaseType' => 0,
                                                     'CloudCostStructure' => 154,
                                                     'CloudCostTier' => 154,
                                                     'CloudCostScheme' => 616})

    old_count = Scraper::Helper.get_db_table_count
    # scrape RDS MySQL Reserved database_types
    json = get_json(RDS_MYSQL_LIGHT_RESERVED_URL)
    parse_rds_reserved(json, 'mysql_standard', "RDS Standard Light-Utilization Reserved", "MySQL", "stdDeployRes")
    parse_rds_reserved(json, 'mysql_multiaz', "RDS Multi-AZ Light-Utilization Reserved", "MySQL", "multiAZdeployRes")
    json = get_json(RDS_MYSQL_MEDIUM_RESERVED_URL)
    parse_rds_reserved(json, 'mysql_standard', "RDS Standard Medium-Utilization Reserved", "MySQL", "stdDeployRes")
    parse_rds_reserved(json, 'mysql_multiaz', "RDS Multi-AZ Medium-Utilization Reserved", "MySQL", "multiAZdeployRes")
    json = get_json(RDS_MYSQL_HEAVY_RESERVED_URL)
    parse_rds_reserved(json, 'mysql_standard', "RDS Standard Heavy-Utilization Reserved", "MySQL", "stdDeployRes")
    parse_rds_reserved(json, 'mysql_multiaz', "RDS Multi-AZ Heavy-Utilization Reserved", "MySQL", "multiAZdeployRes")
    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 0,
                                                     'Cloud' => 0,
                                                     'ServerType' => 0,
                                                     'StorageType' => 0,
                                                     'DatabaseType' => 0,
                                                     'CloudCostStructure' => 504,
                                                     'CloudCostTier' => 504,
                                                     'CloudCostScheme' => 2016})

    old_count = Scraper::Helper.get_db_table_count
    # scrape RDS Oracle Reserved database_types
    json = get_json(RDS_ORACLE_LICENSED_LIGHT_RESERVED_URL)
    parse_rds_reserved(json, 'oracle_standard', "RDS License-Included Light-Utilization Reserved", "Oracle", "stdDeployRes")
    json = get_json(RDS_ORACLE_BYOL_LIGHT_RESERVED_URL)
    parse_rds_reserved(json, 'oracle_standard', "RDS Bring-Your-Own-License Light-Utilization Reserved", "Oracle", "stdDeployRes")
    json = get_json(RDS_ORACLE_LICENSED_MEDIUM_RESERVED_URL)
    parse_rds_reserved(json, 'oracle_standard', "RDS License-Included Medium-Utilization Reserved", "Oracle", "stdDeployRes")
    json = get_json(RDS_ORACLE_BYOL_MEDIUM_RESERVED_URL)
    parse_rds_reserved(json, 'oracle_standard', "RDS Bring-Your-Own-License Medium-Utilization Reserved", "Oracle", "stdDeployRes")
    json = get_json(RDS_ORACLE_LICENSED_HEAVY_RESERVED_URL)
    parse_rds_reserved(json, 'oracle_standard', "RDS License-Included Heavy-Utilization Reserved", "Oracle", "stdDeployRes")
    json = get_json(RDS_ORACLE_BYOL_HEAVY_RESERVED_URL)
    parse_rds_reserved(json, 'oracle_standard', "RDS Bring-Your-Own-License Heavy-Utilization Reserved", "Oracle", "stdDeployRes")
    Scraper::Helper.check_db_table_count(old_count, {'CloudProvider' => 0,
                                                     'Cloud' => 0,
                                                     'ServerType' => 0,
                                                     'StorageType' => 0,
                                                     'DatabaseType' => 0,
                                                     'CloudCostStructure' => 420,
                                                     'CloudCostTier' => 420,
                                                     'CloudCostScheme' => 1680})
  end

  def self.get_json(uri)
    uri = URI.parse(uri)
    request = Net::HTTP::Get.new(uri.path)
    response = Net::HTTP.start(uri.host, uri.port) {|http| http.request(request)}
    json = JSON.parse(response.body)
    raise AppExceptions::ScraperError.new("JSON from #{uri} could not be parsed.") if json.has_key?('Error')
    return json
  end

  def self.parse_data_transfer(json)
    json["config"]["regions"].each do |regions|
      # Create cloud if necessary
      cloud = Cloud.find_or_create_by_name(@@clouds[regions["region"]])
      cloud.update_attributes(@@clouds[regions["region"]].merge(:billing_currency => 'USD'))
      cloud.cloud_provider = @@aws
      cloud.save!

      # Create the data_out cloud_cost_structures for each region
      invalidate_old_ccs_with_no_resource_type('data_out', cloud)
      @@data_out_ccs[regions["region"]] = CloudCostStructure.create!(:name => 'data_out', :units => 'per.1.gbs')
      data_out_tier = CloudCostTier.new(:upto => 1, :cost => parse_num(regions["types"][1]["tiers"][0]["prices"]["USD"]))
      data_out_tier.cloud_cost_structure = @@data_out_ccs[regions["region"]]
      data_out_tier.save!

      data_out_tier = CloudCostTier.new(:upto => 10240, :cost => parse_num(regions["types"][1]["tiers"][1]["prices"]["USD"]))
      data_out_tier.cloud_cost_structure = @@data_out_ccs[regions["region"]]
      data_out_tier.save!

      data_out_tier = CloudCostTier.new(:upto => 51200, :cost => parse_num(regions["types"][1]["tiers"][2]["prices"]["USD"]))
      data_out_tier.cloud_cost_structure = @@data_out_ccs[regions["region"]]
      data_out_tier.save!

      data_out_tier = CloudCostTier.new(:upto => 153600, :cost => parse_num(regions["types"][1]["tiers"][3]["prices"]["USD"]))
      data_out_tier.cloud_cost_structure = @@data_out_ccs[regions["region"]]
      data_out_tier.save!

      data_out_tier = CloudCostTier.new(:cost => parse_num(regions["types"][1]["tiers"][4]["prices"]["USD"]))
      data_out_tier.cloud_cost_structure = @@data_out_ccs[regions["region"]]
      data_out_tier.save!
    end
  end

  def self.parse_on_demand(json, server_type_name_prefix)
    json["config"]["regions"].each {|regions|
      cloud = Cloud.find_by_name(@@clouds[regions["region"]][:name])
      regions["instanceTypes"].each{|instance|
        instance["sizes"].each{|size|
          size["valueColumns"].each{|values|
            if (values["prices"]["USD"] != 'N/A*')
              s_type_key = "#{instance["type"]} #{size["size"]}"
              s_type_name = "#{server_type_name_prefix} #{@@server_type_details[s_type_key][:name]}"

              # Create ServerType if necessary
              params = @@server_type_details[s_type_key].merge(
                  :name => s_type_name,
                  :operating_system => @@operating_systems[values["name"]])
              s_type = ServerType.where(params).first
              s_type ||= ServerType.create!(params)

              # Create a ccs for instance_hour
              invalidate_old_ccs(s_type, 'instance_hour', cloud)
              cc_struct = CloudCostStructure.create!(:name => "instance_hour", :units => "per.1.hours")
              cc_tier = CloudCostTier.new(:cost => parse_num(values["prices"]["USD"]))
              cc_tier.cloud_cost_structure = cc_struct
              cc_tier.save!

              # Link ServerType to its instance_hour CloudCostStructure
              cc_scheme = CloudCostScheme.new()
              cc_scheme.cloud = cloud
              cc_scheme.cloud_resource_type = s_type
              cc_scheme.cloud_cost_structure = cc_struct
              cc_scheme.save!

              # Link ServerType to its data_out CloudCostStructure
              cc_scheme = CloudCostScheme.new()
              cc_scheme.cloud = cloud
              cc_scheme.cloud_resource_type = s_type
              cc_scheme.cloud_cost_structure = @@data_out_ccs[regions["region"]]
              cc_scheme.save!
            end
          }
        }
      }
    }
  end

  def self.parse_sql_server_on_demand(json, server_type_name_prefix)
    json["config"]["regions"].each {|regions|
      cloud = Cloud.find_by_name(@@clouds[regions["region"]][:name])
      regions["instanceTypes"].each{|instance|
        instance["sizes"].each{|size|
          size["valueColumns"].each{|values|
            # Don't add mswin prices since they have already been added by parse_on_demand
            if (!['N/A*', '--'].include?(values["prices"]["USD"]) && values["name"] != 'mswin')
              s_type_key = "#{instance["type"]} #{size["size"]}"
              s_type_name = "#{server_type_name_prefix} #{@@server_type_details[s_type_key][:name]}"

              # Create ServerType if necessary
              params = @@server_type_details[s_type_key].merge(
                  :name => s_type_name,
                  :operating_system => @@operating_systems[values["name"]])
              s_type = ServerType.where(params).first
              s_type ||= ServerType.create!(params)

              # Create a ccs for instance_hour
              invalidate_old_ccs(s_type, 'instance_hour', cloud)
              cc_struct = CloudCostStructure.create!(:name => "instance_hour", :units => "per.1.hours")
              cc_tier = CloudCostTier.new(:cost => parse_num(values["prices"]["USD"]))
              cc_tier.cloud_cost_structure = cc_struct
              cc_tier.save!

              # Link ServerType to its instance_hour CloudCostStructure
              cc_scheme = CloudCostScheme.new()
              cc_scheme.cloud = cloud
              cc_scheme.cloud_resource_type = s_type
              cc_scheme.cloud_cost_structure = cc_struct
              cc_scheme.save!

              # Link ServerType to its data_out CloudCostStructure
              cc_scheme = CloudCostScheme.new()
              cc_scheme.cloud = cloud
              cc_scheme.cloud_resource_type = s_type
              cc_scheme.cloud_cost_structure = @@data_out_ccs[regions["region"]]
              cc_scheme.save!
            end
          }
        }
      }
    }
  end

  def self.parse_reserved(json, server_type_name_prefix, os)
    json["config"]["regions"].each {|regions|
      cloud = Cloud.find_by_name(@@clouds[@@region_names_map[regions["region"]]][:name])
      regions["instanceTypes"].each{|instance|
        instance["sizes"].each{|size|
          # 1 or 3 year
          [1, 3].each do |yearly|
            # Set the column that has the reservation cost
            yearly_column_index = (yearly == 1 ? 0 : 2)
            reservation_cost = size["valueColumns"][yearly_column_index]["prices"]["USD"]

            if (reservation_cost != 'N/A*')
              # Map "stdResI sm" to "stdODI sm" so we can find the details
              s_type_key = @@reserved_server_type_keys["#{instance["type"]} #{size["size"]}"]
              s_type_name = "#{server_type_name_prefix} #{yearly}-Year #{@@server_type_details[s_type_key][:name]}"

              # Create ServerType if necessary
              params = @@server_type_details[s_type_key].merge(
                  :name => s_type_name,
                  :operating_system => @@operating_systems[os])
              s_type = ServerType.where(params).first
              s_type ||= ServerType.create!(params)

              # Create pattern for reservation costs
              pattern = Pattern.create!(:name => 'Reservation cost')
              rule = Rule.new(:rule_type => 'Temporary', :year => "every.#{yearly}.years", :variation => '+',
                              :value => parse_num(reservation_cost))
              rule.pattern = pattern
              rule.save!

              # Create a ccs for instance_hour and add reservation costs pattern
              invalidate_old_ccs(s_type, 'instance_hour', cloud)
              cc_struct = CloudCostStructure.create!(:name => "instance_hour", :units => "per.1.hours")
              cc_struct.add_patterns(:recurring_costs_monthly_baseline, [pattern])
              cc_tier = CloudCostTier.new(:cost => parse_num(size["valueColumns"][yearly_column_index + 1]["prices"]["USD"]))
              cc_tier.cloud_cost_structure = cc_struct
              cc_tier.save!

              # Link ServerType to its instance_hour CloudCostStructure
              cc_scheme = CloudCostScheme.new()
              cc_scheme.cloud = cloud
              cc_scheme.cloud_resource_type = s_type
              cc_scheme.cloud_cost_structure = cc_struct
              cc_scheme.save!

              # Link ServerType to its data_out CloudCostStructure
              cc_scheme = CloudCostScheme.new()
              cc_scheme.cloud = cloud
              cc_scheme.cloud_resource_type = s_type
              cc_scheme.cloud_cost_structure = @@data_out_ccs[@@region_names_map[regions["region"]]]
              cc_scheme.save!
            end
          end
        }
      }
    }
  end

  def self.parse_ebs(json)
    json["config"]["regions"].each {|regions|
      cloud = Cloud.find_by_name(@@clouds[regions["region"]][:name])

      storage_cost    = regions["types"][0]["values"][0]["prices"]["USD"]
      io_request_cost = regions["types"][0]["values"][1]["prices"]["USD"]
      if (storage_cost != 'N/A*')
        # Create StorageType if necessary
        params = {:name => 'EBS', :description => 'Elastic Block Store'}
        s_type = StorageType.where(params).first
        s_type ||= StorageType.create!(params)

        # Create a ccs for storage_size
        invalidate_old_ccs(s_type, 'storage_size', cloud)
        cc_struct = CloudCostStructure.create!(:name => "storage_size", :units => "per.1.gbs.per.1.months")
        cc_tier = CloudCostTier.new(:cost => parse_num(storage_cost))
        cc_tier.cloud_cost_structure = cc_struct
        cc_tier.save!
        # Link StorageType to its storage_size CloudCostStructure
        cc_scheme = CloudCostScheme.new()
        cc_scheme.cloud = cloud
        cc_scheme.cloud_resource_type = s_type
        cc_scheme.cloud_cost_structure = cc_struct
        cc_scheme.save!

        # Create identical ccs for read/write_request
        ["read_request", "write_request"].each do |request|
          invalidate_old_ccs(s_type, request, cloud)
          cc_struct = CloudCostStructure.create!(:name => request, :units => "per.1000000.requests")
          cc_tier = CloudCostTier.new(:cost => parse_num(io_request_cost))
          cc_tier.cloud_cost_structure = cc_struct
          cc_tier.save!
          # Link StorageType to its read_request CloudCostStructure
          cc_scheme = CloudCostScheme.new()
          cc_scheme.cloud = cloud
          cc_scheme.cloud_resource_type = s_type
          cc_scheme.cloud_cost_structure = cc_struct
          cc_scheme.save!
        end

        # Link StorageType to its data_out CloudCostStructure
        cc_scheme = CloudCostScheme.new()
        cc_scheme.cloud = cloud
        cc_scheme.cloud_resource_type = s_type
        cc_scheme.cloud_cost_structure = @@data_out_ccs[regions["region"]]
        cc_scheme.save!
      end
    }
  end

  def self.parse_s3(s3_json, s3_requests_json)
    s3_json["config"]["regions"].each do |regions|
      cloud = Cloud.find_by_name(@@clouds[regions["region"]][:name])

      # Add the S3 Standard and Reduced Redundancy Storage
      [0, 1].each do |column|
        s_name = (column == 0 ? 'S3 Standard' : 'S3 Reduced Redundancy')
        # Create StorageType if necessary
        params = {:name => s_name, :description => 'Simple Storage Service'}
        s_type = StorageType.where(params).first
        s_type ||= StorageType.create!(params)

        invalidate_old_ccs(s_type, 'storage_size', cloud)
        # Create a ccs for storage_size and add its tiers
        cc_struct = CloudCostStructure.create!(:name => "storage_size", :units => "per.1.gbs.per.1.months")
        cc_tier = CloudCostTier.new(:upto => 1024, :cost => parse_num(regions["tiers"][0]["storageTypes"][column]["prices"]["USD"]))
        cc_tier.cloud_cost_structure = cc_struct
        cc_tier.save!

        cc_tier = CloudCostTier.new(:upto => 51200, :cost => parse_num(regions["tiers"][1]["storageTypes"][column]["prices"]["USD"]))
        cc_tier.cloud_cost_structure = cc_struct
        cc_tier.save!

        cc_tier = CloudCostTier.new(:upto => 512000, :cost => parse_num(regions["tiers"][2]["storageTypes"][column]["prices"]["USD"]))
        cc_tier.cloud_cost_structure = cc_struct
        cc_tier.save!

        cc_tier = CloudCostTier.new(:upto => 1024000, :cost => parse_num(regions["tiers"][3]["storageTypes"][column]["prices"]["USD"]))
        cc_tier.cloud_cost_structure = cc_struct
        cc_tier.save!

        cc_tier = CloudCostTier.new(:upto => 5120000, :cost => parse_num(regions["tiers"][4]["storageTypes"][column]["prices"]["USD"]))
        cc_tier.cloud_cost_structure = cc_struct
        cc_tier.save!

        cc_tier = CloudCostTier.new(:cost => parse_num(regions["tiers"][5]["storageTypes"][column]["prices"]["USD"]))
        cc_tier.cloud_cost_structure = cc_struct
        cc_tier.save!

        # Link StorageType to its storage_size CloudCostStructure
        cc_scheme = CloudCostScheme.new()
        cc_scheme.cloud = cloud
        cc_scheme.cloud_resource_type = s_type
        cc_scheme.cloud_cost_structure = cc_struct
        cc_scheme.save!

        invalidate_old_ccs(s_type, 'write_request', cloud)
        # Create ccs for read_request
        cc_struct = CloudCostStructure.create!(:name => 'write_request', :description => 'PUT, COPY, POST, or LIST requests', :units => "per.1000.requests")
        # Find the associated cost from the requests_json
        cc_tier = CloudCostTier.new(:cost => parse_num(s3_requests_json["config"]["regions"].select{
            |request_region| request_region["region"] == regions["region"]}.first["tiers"][0]["prices"]["USD"]))
        cc_tier.cloud_cost_structure = cc_struct
        cc_tier.save!
        # Link StorageType to its read_request CloudCostStructure
        cc_scheme = CloudCostScheme.new()
        cc_scheme.cloud = cloud
        cc_scheme.cloud_resource_type = s_type
        cc_scheme.cloud_cost_structure = cc_struct
        cc_scheme.save!

        invalidate_old_ccs(s_type, 'read_request', cloud)
        # Create ccs for write_request
        cc_struct = CloudCostStructure.create!(:name => 'read_request', :description => 'GET and all other requests', :units => "per.10000.requests")
        # Find the associated cost from the requests_json
        cc_tier = CloudCostTier.new(:cost => parse_num(s3_requests_json["config"]["regions"].select{
            |request_region| request_region["region"] == regions["region"]}.first["tiers"][1]["prices"]["USD"]))
        cc_tier.cloud_cost_structure = cc_struct
        cc_tier.save!
        # Link StorageType to its write_request CloudCostStructure
        cc_scheme = CloudCostScheme.new()
        cc_scheme.cloud = cloud
        cc_scheme.cloud_resource_type = s_type
        cc_scheme.cloud_cost_structure = cc_struct
        cc_scheme.save!

        # Link StorageType to its data_out CloudCostStructure if there is a new data_out_ccs
        cc_scheme = CloudCostScheme.new()
        cc_scheme.cloud = cloud
        cc_scheme.cloud_resource_type = s_type
        cc_scheme.cloud_cost_structure = @@data_out_ccs[regions["region"]]
        cc_scheme.save!
      end
    end
  end

  def self.parse_rds_storage(json, rds_storage_ccs_key)
    # Create the RDS storage cloud_cost_structures, we'll invalidate the old ones in in the parse_rds_on_demand
    # Note that they are also used in the parse_rds_reserved method but we'll only invalidate them once in the parse_rds_on_demand method,
    # otherwise it'll invalidate the new ones we create here.
    json["config"]["regions"].each do |regions|
      # Create a ccs for storage_size
      @@rds_storage_ccs[rds_storage_ccs_key]['storage_ccs'][regions["region"]] =
          CloudCostStructure.create!(:name => "storage_size", :units => "per.1.gbs.per.1.months")
      cc_tier = CloudCostTier.new(:cost => parse_num(regions["rates"][0]["prices"]["USD"]))
      cc_tier.cloud_cost_structure = @@rds_storage_ccs[rds_storage_ccs_key]['storage_ccs'][regions["region"]]
      cc_tier.save!

      # Create a ccs for transaction
      @@rds_storage_ccs[rds_storage_ccs_key]['transaction_ccs'][regions["region"]] =
          CloudCostStructure.create!(:name => "transaction", :units => "per.1000000.transactions")
      cc_tier = CloudCostTier.new(:cost => parse_num(regions["rates"][1]["prices"]["USD"]))
      cc_tier.cloud_cost_structure = @@rds_storage_ccs[rds_storage_ccs_key]['transaction_ccs'][regions["region"]]
      cc_tier.save!
    end
  end

  def self.parse_rds_on_demand(json, rds_storage_ccs_key, database_type_name_prefix, software)
    json["config"]["regions"].each do |regions|
      cloud = Cloud.find_by_name(@@clouds[regions["region"]][:name])
      invalidate_old_rds_prices = true # Only invalidate the prices once otherwise the new ones created by parse_rds_storage will also be invalidated
      # Don't invalidate prices on second call to the oracle_standard key since it's already been invalidated
      invalidate_old_rds_prices = false if rds_storage_ccs_key == "oracle_standard" &&
          database_type_name_prefix == "RDS On-Demand Bring-Your-Own-License" && software == "Oracle"

      regions["types"].each do |db_type_json|
        db_type_json["tiers"].each do |tier|
          if (tier["prices"]["USD"] != 'N/A*')
            db_type_key = @@database_type_keys["#{db_type_json["name"]} #{tier["name"]}"]
            db_type_name = "#{database_type_name_prefix} #{@@database_type_details[db_type_key][:name]}"

            # Create DatabaseType if necessary
            params = @@database_type_details[db_type_key].merge(
                :name => db_type_name,
                :software => software)
            db_type = DatabaseType.where(params).first
            db_type ||= DatabaseType.create!(params)

            # Create a ccs for instance_hour
            invalidate_old_ccs(db_type, 'instance_hour', cloud)
            cc_struct = CloudCostStructure.create!(:name => "instance_hour", :units => "per.1.hours")
            cc_tier = CloudCostTier.new(:cost => parse_num(tier["prices"]["USD"]))
            cc_tier.cloud_cost_structure = cc_struct
            cc_tier.save!

            # Link DatabaseType to its instance_hour CloudCostStructure
            cc_scheme = CloudCostScheme.new()
            cc_scheme.cloud = cloud
            cc_scheme.cloud_resource_type = db_type
            cc_scheme.cloud_cost_structure = cc_struct
            cc_scheme.save!

            if invalidate_old_rds_prices
              invalidate_old_ccs(db_type, 'storage_size', cloud)
              invalidate_old_ccs(db_type, 'transaction', cloud)
              # Set the flag to false so we don't do it again otherwise the new prices created by parse_rds_storage will get invalidated
              invalidate_old_rds_prices = false
            end

            # Link DatabaseType to its storage_size CloudCostStructure
            cc_scheme = CloudCostScheme.new()
            cc_scheme.cloud = cloud
            cc_scheme.cloud_resource_type = db_type
            cc_scheme.cloud_cost_structure = @@rds_storage_ccs[rds_storage_ccs_key]['storage_ccs'][regions["region"]]
            cc_scheme.save!

            # Link DatabaseType to its transaction CloudCostStructure
            cc_scheme = CloudCostScheme.new()
            cc_scheme.cloud = cloud
            cc_scheme.cloud_resource_type = db_type
            cc_scheme.cloud_cost_structure = @@rds_storage_ccs[rds_storage_ccs_key]['transaction_ccs'][regions["region"]]
            cc_scheme.save!

            # Link DatabaseType to its data_out CloudCostStructure
            cc_scheme = CloudCostScheme.new()
            cc_scheme.cloud = cloud
            cc_scheme.cloud_resource_type = db_type
            cc_scheme.cloud_cost_structure = @@data_out_ccs[regions["region"]]
            cc_scheme.save!
          end
        end
      end
    end
  end

  def self.parse_rds_reserved(json, rds_storage_ccs_key, database_type_name_prefix, software, instance_type_filter)
    json["config"]["regions"].each do |regions|
      cloud = Cloud.find_by_name(@@clouds[regions["region"]][:name])

      regions["instanceTypes"].each do |instance|
        # Only process the target instance_types (either standard or multiaz)
        if (instance["type"] == instance_type_filter)
          instance["tiers"].each do |tier|

            # 1 or 3 year
            [1, 3].each do |yearly|
              # Set the column that has the reservation cost
              yearly_column_index = (yearly == 1 ? 0 : 2)
              reservation_cost = tier["valueColumns"][yearly_column_index]["prices"]["USD"]
              hourly_cost      = tier["valueColumns"][yearly_column_index + 1]["prices"]["USD"]

              if (reservation_cost != 'N/A*')
                db_type_key = @@database_type_keys["#{instance["type"]} #{tier["size"]}"]
                db_type_name = "#{database_type_name_prefix} #{yearly}-Year #{@@database_type_details[db_type_key][:name]}"

                # Create DatabaseType if necessary
                params = @@database_type_details[db_type_key].merge(
                    :name => db_type_name,
                    :software => software)
                db_type = DatabaseType.where(params).first
                db_type ||= DatabaseType.create!(params)

                # Create pattern for reservation costs
                pattern = Pattern.create!(:name => 'Reservation cost')
                rule = Rule.new(:rule_type => 'Temporary', :year => "every.#{yearly}.years", :variation => '+',
                                :value => parse_num(reservation_cost))
                rule.pattern = pattern
                rule.save!

                # Create a ccs for instance_hour and add reservation costs pattern
                invalidate_old_ccs(db_type, 'instance_hour', cloud)
                cc_struct = CloudCostStructure.create!(:name => "instance_hour", :units => "per.1.hours")
                cc_struct.add_patterns(:recurring_costs_monthly_baseline, [pattern])
                cc_tier = CloudCostTier.new(:cost => parse_num(hourly_cost))
                cc_tier.cloud_cost_structure = cc_struct
                cc_tier.save!

                # Link DatabaseType to its instance_hour CloudCostStructure
                cc_scheme = CloudCostScheme.new()
                cc_scheme.cloud = cloud
                cc_scheme.cloud_resource_type = db_type
                cc_scheme.cloud_cost_structure = cc_struct
                cc_scheme.save!

                # Link DatabaseType to its storage_size CloudCostStructure
                # The old storage_size ccs has already been invalidated by the rds_on_demand method since it's shared so no need to do anything here
                cc_scheme = CloudCostScheme.new()
                cc_scheme.cloud = cloud
                cc_scheme.cloud_resource_type = db_type
                cc_scheme.cloud_cost_structure = @@rds_storage_ccs[rds_storage_ccs_key]['storage_ccs'][regions["region"]]
                cc_scheme.save!

                # Link DatabaseType to its transaction CloudCostStructure
                # The old transaction ccs has already been invalidated by the rds_on_demand method since it's shared so no need to do anything here
                cc_scheme = CloudCostScheme.new()
                cc_scheme.cloud = cloud
                cc_scheme.cloud_resource_type = db_type
                cc_scheme.cloud_cost_structure = @@rds_storage_ccs[rds_storage_ccs_key]['transaction_ccs'][regions["region"]]
                cc_scheme.save!

                # Link DatabaseType to its data_out CloudCostStructure
                cc_scheme = CloudCostScheme.new()
                cc_scheme.cloud = cloud
                cc_scheme.cloud_resource_type = db_type
                cc_scheme.cloud_cost_structure = @@data_out_ccs[regions["region"]]
                cc_scheme.save!
              end
            end
          end
        end
      end
    end
  end

  def self.parse_num(num)
    # Some of the prices have commas in AWS JSON files
    num.delete(',')
  end

  def self.invalidate_old_ccs(cloud_resource_type, ccs_name, cloud)
    cc_struct = cloud_resource_type.cloud_cost_structures.where(:name => ccs_name, :valid_until => nil).select{|ccs| ccs.clouds.first == cloud}.first
    cc_struct.update_attributes!(:valid_until => Time.now) if cc_struct
  end

  def self.invalidate_old_ccs_with_no_resource_type(ccs_name, cloud)
    cc_struct = CloudCostStructure.where(:name => ccs_name, :valid_until => nil).select{|ccs| ccs.clouds.first == cloud}.first
    cc_struct.update_attributes!(:valid_until => Time.now) if cc_struct
  end

  # Use this method from the rails console
  def self.save_json_files(output_dir)
    require 'open-uri'
    self.constants(false).each do |const|
      value = self.const_get(const)
      next unless value.starts_with?('http://')
      output_file = value.sub('http://', '').gsub('/', '__')
      writeOut = open("#{output_dir}/#{output_file}", "wb")
      writeOut.write(open(value).read)
      writeOut.close
      puts "#{output_file} done"
    end
    puts "ALL DONE."
  end
end