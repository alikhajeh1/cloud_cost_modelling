require 'machinist/active_record'

# Best Practices:
#- Keep blueprints minimal
#- If you want to construct a whole graph of connected objects, do it outside of a blueprint
#- Sort your blueprints alphabetically

AdditionalCost.blueprint do
  user
  name                  {"name_#{sn}"}
  cost_monthly_baseline {10}
end

Application.blueprint do
  user
  deployment
  server
  name                            {"name_#{sn}"}
  instance_hour_monthly_baseline {10}
end

Cloud.blueprint do
  cloud_provider
  name             {"name_#{sn}"}
  billing_currency {"USD"}
  location         {"United States"}
end

CloudCostScheme.blueprint do
  cloud
  cloud_resource_type {Server.make}
  cloud_cost_structure
end

CloudCostStructure.blueprint do
  name  {"instance_hour"}
  units {"per.1.hours"}
end

CloudCostTier.blueprint do
  cloud_cost_structure
  name {"name_#{sn}"}
  upto {100}
  cost {0.2}
end

CloudProvider.blueprint do
  name {"name_#{sn}"}
end

DatabaseResource.blueprint do
  user
  deployment
  database_type
  cloud
  name                           {"name_#{sn}"}
  storage_size_monthly_baseline  {10}
  instance_hour_monthly_baseline {10}
  transaction_monthly_baseline   {10}
  quantity_monthly_baseline      {1}
end

DatabaseType.blueprint do
  name             {"On Demand Standard Small"}
  cpu_architecture {"X64"}
  cpu_speed        {1.0}
  cpu_count        {1}
  memory           {1.7}
  software         {"MySQL"}
end

DataChunk.blueprint do
  user
  deployment
  storage
  name                           {"name_#{sn}"}
  storage_size_monthly_baseline  {10}
  read_request_monthly_baseline  {10}
  write_request_monthly_baseline {10}
end

DataLink.blueprint do
  user
  deployment
  sourcable                         {Application.make}
  targetable                        {DataChunk.make}
  source_to_target_monthly_baseline {5}
  target_to_source_monthly_baseline {10}
end

Deployment.blueprint do
  user
  name {"name_#{sn}"}
end

Pattern.blueprint do
  user
  name {"name_#{sn}"}
end

PatternMap.blueprint do
  user
  patternable           {Application.make}
  patternable_attribute {"instance_hour_monthly_baseline"}
  pattern
end

Report.blueprint do
  user
  name       {"name_#{sn}"}
  reportable {Deployment.make}
  start_date {"2012-01-01"}
  end_date   {"2013-01-01"}
end

RemoteNode.blueprint do
  user
  deployment
  name       {"name_#{sn}"}
end

Rule.blueprint do
  user
  pattern
  rule_type {"permanent"}
  year      {"every.1.years"}
  month     {"every.1.months"}
  day       {"every.1.days"}
  hour      {"every.1.hours"}
  variation {"+"}
  value     {"1"}
end

Server.blueprint do
  user
  deployment
  server_type
  cloud
  name                           {"name_#{sn}"}
  instance_hour_monthly_baseline {10}
  quantity_monthly_baseline      {1}
end

ServerType.blueprint do
  name             {"On Demand Standard Small"}
  cpu_architecture {"X86"}
  cpu_speed        {1.0}
  cpu_count        {1}
  local_disk_count {1}
  local_disk_size  {160}
  memory           {1.7}
  operating_system {"Linux"}
end

Storage.blueprint do
  user
  deployment
  storage_type
  cloud
  name                           {"name_#{sn}"}
  storage_size_monthly_baseline  {10}
  read_request_monthly_baseline  {10}
  write_request_monthly_baseline {10}
  quantity_monthly_baseline      {1}
end

StorageType.blueprint do
  name {"S3"}
end

User.blueprint do
  email                 {"email_#{rand(2**32)}@test.com"}
  password              {"password"}
  password_confirmation {"password"}
  first_name            {"first_name_#{sn}"}
  last_name             {"last_name_#{sn}"}
  company               {"company_#{sn}"}
end
