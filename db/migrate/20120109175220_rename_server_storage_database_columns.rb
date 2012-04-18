class RenameServerStorageDatabaseColumns < ActiveRecord::Migration
  def change
    rename_column :servers, :instance_hours_monthly_baseline, :instance_hour_monthly_baseline
    rename_column :servers, :quantity_baseline, :quantity_monthly_baseline

    rename_column :storages, :size_monthly_baseline, :storage_size_monthly_baseline
    rename_column :storages, :read_requests_monthly_baseline, :read_request_monthly_baseline
    rename_column :storages, :write_requests_monthly_baseline, :write_request_monthly_baseline
    rename_column :storages, :quantity_baseline, :quantity_monthly_baseline

    rename_column :database_resources, :size_monthly_baseline, :storage_size_monthly_baseline
    rename_column :database_resources, :transactions_monthly_baseline, :transaction_monthly_baseline
    rename_column :database_resources, :instance_hours_monthly_baseline, :instance_hour_monthly_baseline
    rename_column :database_resources, :quantity_baseline, :quantity_monthly_baseline

    rename_column :applications, :instance_hours_monthly_baseline, :instance_hour_monthly_baseline

    rename_column :data_chunks, :size_monthly_baseline, :storage_size_monthly_baseline
    rename_column :data_chunks, :read_requests_monthly_baseline, :read_request_monthly_baseline
    rename_column :data_chunks, :write_requests_monthly_baseline, :write_request_monthly_baseline

  end
end
