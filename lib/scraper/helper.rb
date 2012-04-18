class Scraper::Helper
  def self.get_db_table_count
    items = {}
    [CloudProvider, Cloud, ServerType, StorageType, DatabaseType, CloudCostStructure, CloudCostTier, CloudCostScheme].each do |m|
      items[m.to_s] = m.count
    end
    items
  end

  def self.check_db_table_count(old_count, expected_count)
    new_count = get_db_table_count
    expected_count.each do |model_name, expected_change|
      raise AppExceptions::ScraperError.new("A scraper has scraped an unexpected number of items:\n" +
          ">>>>> Expected #{model_name} to change by #{expected_change}, but it was changed by #{new_count[model_name] - old_count[model_name]}") if
          new_count[model_name] - old_count[model_name] != expected_change
    end
  end
end
