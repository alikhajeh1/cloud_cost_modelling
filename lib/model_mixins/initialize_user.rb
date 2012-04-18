class InitializeUser
  include ReportHelper

  def initialize(user)
    @user = user
  end

  def create_example_deployment
    deployment = Deployment.new(:name => 'Example deployment', :description => 'This is an example deployment, check it out')
    deployment.user = @user
    deployment.save!

    aws_cloud = Cloud.find_by_name('AWS US-West (Northern California)')

    # Storage (one for each), Database, Remote node, data transfer, additional cost
    # First server - Load balancer on AWS
    server_load_balancer = Server.new(:name => 'Load balancer - HAProxy',
                                      :description => 'Server running 24/7 - HAProxy for load balancing',
                                      :instance_hour_monthly_baseline => 744,
                                      :quantity_monthly_baseline => 1)
    server_load_balancer.user = @user
    server_load_balancer.deployment = deployment
    server_load_balancer.cloud = aws_cloud
    server_load_balancer.server_type = ServerType.first(:conditions =>
                                                            ["name = 'Heavy-Utilization Reserved 1-Year Standard Small' AND operating_system = 'Linux/UNIX'"])
    server_load_balancer.save!

    # Second server - 2 x web server on AWS
    server_web_servers = Server.new(:name => 'Web servers',
                                    :description => '2 servers for peak, running 6am to 9pm = 465 h/month',
                                    :instance_hour_monthly_baseline => 465,
                                    :quantity_monthly_baseline => 2)
    server_web_servers.user = @user
    server_web_servers.deployment = deployment
    server_web_servers.cloud = aws_cloud
    server_web_servers.server_type = ServerType.first(:conditions =>
                                                          ["name = 'On-Demand Standard Small' AND operating_system = 'Linux/UNIX'"])
    server_web_servers.save!

    # Second server - 1 x small web server on AWS
    server_small_web_server = Server.new(:name => 'Base web server',
                                         :description => 'Server to support overnight use',
                                         :instance_hour_monthly_baseline => 744,
                                         :quantity_monthly_baseline => 1)
    server_small_web_server.user = @user
    server_small_web_server.deployment = deployment
    server_small_web_server.cloud = aws_cloud
    server_small_web_server.server_type = ServerType.first(:conditions =>
                                                               ["name = 'Heavy-Utilization Reserved 3-Year Micro' AND operating_system = 'Linux/UNIX'"])
    server_small_web_server.save!

    # First storage - 3 x EBS storage on AWS
    storage_web_servers = Storage.new(:name => 'Storage for web servers',
                                      :storage_size_monthly_baseline => 50,
                                      :read_request_monthly_baseline => 70000000,
                                      :write_request_monthly_baseline => 10000000,
                                      :quantity_monthly_baseline => 3)
    storage_web_servers.user = @user
    storage_web_servers.deployment = deployment
    storage_web_servers.cloud = aws_cloud
    storage_web_servers.storage_type = StorageType.find_by_name('EBS')
    storage_web_servers.save!

    # First database - one RDS with BYO licence
    database_central = DatabaseResource.new(:name => 'Central Database',
                                            :instance_hour_monthly_baseline => 744,
                                            :storage_size_monthly_baseline => 300,
                                            :transaction_monthly_baseline => 90000000,
                                            :quantity_monthly_baseline => 1)
    database_central.user = @user
    database_central.deployment = deployment
    database_central.cloud = aws_cloud
    database_central.database_type = DatabaseType.find_by_name('RDS Standard Heavy-Utilization Reserved 1-Year Large')
    database_central.save

    # Back up storage for DB on Rackspace USA
    storage_backup = Storage.new(:name => 'Backup of database',
                                 :storage_size_monthly_baseline => 300,
                                 :read_request_monthly_baseline => 100000,
                                 :write_request_monthly_baseline => 5000000,
                                 :quantity_monthly_baseline => 1)
    storage_backup.user = @user
    storage_backup.deployment = deployment
    storage_backup.cloud = Cloud.find_by_name('Rackspace USA')
    storage_backup.storage_type = StorageType.find_by_name('Cloud Files')
    storage_backup.save!

    # Additional cost
    additional_cost = AdditionalCost.new(:name => 'Cloudability.com',
                                         :description => '3rd party plugin to monitor costs',
                                         :cost_monthly_baseline => 49)
    additional_cost.user = @user
    additional_cost.save!
    deployment.additional_costs << additional_cost
    @user.additional_costs.create!(:name => 'RightScale Cloud Management',
                                   :description => '3rd party platform to manage cloud resources',
                                   :cost_monthly_baseline => 500)

    # Create pattern - DB increase size
    pattern_for_db_growth = Pattern.new(:name => 'Pattern for database and database backup',
                                        :description => 'Increase the baseline by 10GB per month on an ongoing basis')
    pattern_for_db_growth.user = @user
    pattern_for_db_growth.save!

    # Pattern rule to increase the quantity by 10GB a month
    pattern_rule_add_five = Rule.new(:rule_type => 'Permanent',
                                     :year => 'every.1.years',
                                     :month => 'every.1.months',
                                     :variation => '+',
                                     :value => 10)
    pattern_rule_add_five.pattern = pattern_for_db_growth
    pattern_rule_add_five.save!

    # Create a remote node for users
    remote_node_users = RemoteNode.new(:name => 'Users',
                                       :description => 'Users will send requests to Load Balancer (modelled in servers tab)')
    remote_node_users.deployment = deployment
    remote_node_users.user = @user
    remote_node_users.save

    # Create data links
    # User to load balancer
    link_user_load_balancer = DataLink.new(:source_to_target_monthly_baseline => 80,
                                           :target_to_source_monthly_baseline => 480)
    link_user_load_balancer.user = @user
    link_user_load_balancer.deployment = deployment
    link_user_load_balancer.sourcable = remote_node_users
    link_user_load_balancer.targetable = server_load_balancer
    link_user_load_balancer.save!

    # Database to database backup
    link_database_backup = DataLink.new(:source_to_target_monthly_baseline => 300,
                                        :target_to_source_monthly_baseline => 300)
    link_database_backup.user = @user
    link_database_backup.deployment = deployment
    link_database_backup.sourcable = database_central
    link_database_backup.targetable = storage_backup
    link_database_backup.save!

    # Assign patterns to fields
    pattern_map_db_size = PatternMap.new()
    pattern_map_db_size.user = @user
    pattern_map_db_size.pattern = pattern_for_db_growth
    pattern_map_db_size.patternable = database_central
    pattern_map_db_size.patternable_attribute = 'storage_size_monthly_baseline'
    pattern_map_db_size.save!

    pattern_map_backup_size = PatternMap.new()
    pattern_map_backup_size.user = @user
    pattern_map_backup_size.pattern = pattern_for_db_growth
    pattern_map_backup_size.patternable = storage_backup
    pattern_map_backup_size.patternable_attribute = 'storage_size_monthly_baseline'
    pattern_map_backup_size.save!

    pattern_map_backup_size = PatternMap.new()
    pattern_map_backup_size.user = @user
    pattern_map_backup_size.pattern = pattern_for_db_growth
    pattern_map_backup_size.patternable = link_database_backup
    pattern_map_backup_size.patternable_attribute = 'source_to_target_monthly_baseline'
    pattern_map_backup_size.save!

    pattern_map_backup_size = PatternMap.new()
    pattern_map_backup_size.user = @user
    pattern_map_backup_size.pattern = pattern_for_db_growth
    pattern_map_backup_size.patternable = link_database_backup
    pattern_map_backup_size.patternable_attribute = 'target_to_source_monthly_baseline'
    pattern_map_backup_size.save!


    end_date = Time.now + 3.years - 1.month
    report = @user.reports.new(:name => '3-year report',
                               :start_date => "#{Time.now.year}-#{Time.now.month}-01",
                               :end_date => "#{end_date.year}-#{end_date.month}-01")
    report.reportable = deployment
    report.save!
    job = Reports::Job.new(report)
    job.perform
    job.success(nil)
  end
end