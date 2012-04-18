namespace :scraper do
  # be rake scraper:cloud_provider[aws]
  desc "Scrape cloud provider prices"
  task :cloud_provider, [:name] => [:environment] do |t, args|
    Delayed::Job.enqueue(Scraper::Job.new(args[:name] || ''))
  end

  desc "Empty all cloud related tables, DON'T RUN THIS UNLESS YOU KNOW WHAT YOU ARE DOING"
  task :empty_cloud_related_tables => :environment do
    [CloudProvider, Cloud, CloudResourceType, CloudCostStructure, CloudCostTier, CloudCostScheme].each {|t| t.delete_all}
  end
end
