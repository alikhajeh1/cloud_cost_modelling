# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120323033212) do

  create_table "additional_costs", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.decimal  "cost_monthly_baseline", :precision => 30, :scale => 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "additional_costs", ["user_id"], :name => "index_additional_costs_on_user_id"

  create_table "additional_costs_deployments", :id => false, :force => true do |t|
    t.integer  "additional_cost_id"
    t.integer  "deployment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "additional_costs_deployments", ["additional_cost_id"], :name => "index_additional_costs_deployments_on_additional_cost_id"
  add_index "additional_costs_deployments", ["deployment_id"], :name => "index_additional_costs_deployments_on_deployment_id"

  create_table "applications", :force => true do |t|
    t.integer  "user_id"
    t.integer  "deployment_id"
    t.integer  "server_id"
    t.string   "name"
    t.text     "description"
    t.float    "instance_hour_monthly_baseline"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "applications", ["deployment_id"], :name => "index_applications_on_deployment_id"
  add_index "applications", ["server_id"], :name => "index_applications_on_server_id"
  add_index "applications", ["user_id"], :name => "index_applications_on_user_id"

  create_table "cloud_cost_schemes", :force => true do |t|
    t.integer  "cloud_id",                :null => false
    t.integer  "cloud_resource_type_id",  :null => false
    t.integer  "cloud_cost_structure_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cloud_cost_schemes", ["cloud_cost_structure_id"], :name => "index_cloud_cost_schemes_on_cloud_cost_structure_id"
  add_index "cloud_cost_schemes", ["cloud_id", "cloud_resource_type_id", "cloud_cost_structure_id"], :name => "index_cloud_cost_structure_unique", :unique => true
  add_index "cloud_cost_schemes", ["cloud_id"], :name => "index_cloud_cost_schemes_on_cloud_id"
  add_index "cloud_cost_schemes", ["cloud_resource_type_id"], :name => "index_cloud_cost_schemes_on_cloud_resource_type_id"

  create_table "cloud_cost_structures", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "units"
    t.datetime "valid_until"
    t.decimal  "recurring_costs_monthly_baseline", :precision => 30, :scale => 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "custom_algorithm"
  end

  create_table "cloud_cost_tiers", :force => true do |t|
    t.integer  "cloud_cost_structure_id"
    t.string   "name"
    t.text     "description"
    t.integer  "upto"
    t.decimal  "cost",                    :precision => 30, :scale => 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cloud_cost_tiers", ["cloud_cost_structure_id"], :name => "index_cloud_cost_tiers_on_cloud_cost_structure_id"

  create_table "cloud_providers", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "website"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cloud_resource_types", :force => true do |t|
    t.string   "type"
    t.string   "name"
    t.text     "description"
    t.string   "cpu_architecture"
    t.float    "cpu_speed"
    t.integer  "cpu_count"
    t.integer  "local_disk_count"
    t.float    "local_disk_size"
    t.float    "memory"
    t.string   "operating_system"
    t.string   "software"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cloud_resource_types", ["name"], :name => "index_cloud_resource_types_on_name"

  create_table "clouds", :force => true do |t|
    t.integer  "cloud_provider_id"
    t.string   "name"
    t.text     "description"
    t.string   "billing_currency"
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clouds", ["cloud_provider_id"], :name => "index_clouds_on_cloud_provider_id"

  create_table "data_chunks", :force => true do |t|
    t.integer  "user_id"
    t.integer  "deployment_id"
    t.integer  "storage_id"
    t.string   "name"
    t.text     "description"
    t.float    "storage_size_monthly_baseline"
    t.float    "read_request_monthly_baseline"
    t.float    "write_request_monthly_baseline"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "data_chunks", ["deployment_id"], :name => "index_data_chunks_on_deployment_id"
  add_index "data_chunks", ["storage_id"], :name => "index_data_chunks_on_storage_id"
  add_index "data_chunks", ["user_id"], :name => "index_data_chunks_on_user_id"

  create_table "data_links", :force => true do |t|
    t.integer  "user_id"
    t.integer  "deployment_id"
    t.string   "name"
    t.text     "description"
    t.integer  "sourcable_id"
    t.string   "sourcable_type"
    t.integer  "targetable_id"
    t.string   "targetable_type"
    t.float    "source_to_target_monthly_baseline"
    t.float    "target_to_source_monthly_baseline"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "data_links", ["deployment_id"], :name => "index_data_links_on_deployment_id"
  add_index "data_links", ["sourcable_id", "sourcable_type"], :name => "index_data_links_on_sourcable_id_and_sourcable_type"
  add_index "data_links", ["targetable_id", "targetable_type"], :name => "index_data_links_on_targetable_id_and_targetable_type"
  add_index "data_links", ["user_id"], :name => "index_data_links_on_user_id"

  create_table "database_resources", :force => true do |t|
    t.integer  "user_id"
    t.integer  "deployment_id"
    t.integer  "cloud_id"
    t.integer  "database_type_id"
    t.string   "name"
    t.text     "description"
    t.float    "instance_hour_monthly_baseline"
    t.float    "storage_size_monthly_baseline"
    t.float    "transaction_monthly_baseline"
    t.integer  "quantity_monthly_baseline"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "database_resources", ["cloud_id"], :name => "index_database_resources_on_cloud_id"
  add_index "database_resources", ["database_type_id"], :name => "index_database_resources_on_database_type_id"
  add_index "database_resources", ["deployment_id"], :name => "index_database_resources_on_deployment_id"
  add_index "database_resources", ["user_id"], :name => "index_database_resources_on_user_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "deployments", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "cost"
  end

  add_index "deployments", ["user_id"], :name => "index_deployments_on_user_id"

  create_table "pattern_maps", :force => true do |t|
    t.integer  "user_id"
    t.integer  "patternable_id"
    t.string   "patternable_type"
    t.string   "patternable_attribute", :null => false
    t.integer  "pattern_id",            :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
  end

  add_index "pattern_maps", ["user_id", "patternable_id", "patternable_type", "patternable_attribute", "pattern_id"], :name => "index_pattern_maps_unique", :unique => true

  create_table "patterns", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "patterns", ["user_id"], :name => "index_patterns_on_user_id"

  create_table "remote_nodes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "deployment_id"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "remote_nodes", ["deployment_id"], :name => "index_remote_nodes_on_deployment_id"
  add_index "remote_nodes", ["user_id"], :name => "index_remote_nodes_on_user_id"

  create_table "reports", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.integer  "reportable_id"
    t.string   "reportable_type"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "completed_at"
    t.string   "status"
    t.text     "xml"
    t.string   "xslt_file"
    t.text     "html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reports", ["reportable_id", "reportable_type"], :name => "index_reports_on_reportable_id_and_reportable_type"
  add_index "reports", ["user_id"], :name => "index_reports_on_user_id"

  create_table "rules", :force => true do |t|
    t.integer  "user_id"
    t.integer  "pattern_id"
    t.string   "rule_type"
    t.string   "year"
    t.string   "month"
    t.string   "day"
    t.string   "hour"
    t.string   "variation"
    t.decimal  "value",      :precision => 30, :scale => 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
  end

  add_index "rules", ["pattern_id"], :name => "index_rules_on_pattern_id"
  add_index "rules", ["user_id"], :name => "index_rules_on_user_id"

  create_table "servers", :force => true do |t|
    t.integer  "user_id"
    t.integer  "deployment_id"
    t.integer  "cloud_id"
    t.integer  "server_type_id"
    t.string   "name"
    t.text     "description"
    t.float    "instance_hour_monthly_baseline"
    t.integer  "quantity_monthly_baseline"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "servers", ["cloud_id"], :name => "index_servers_on_cloud_id"
  add_index "servers", ["deployment_id"], :name => "index_servers_on_deployment_id"
  add_index "servers", ["server_type_id"], :name => "index_servers_on_server_type_id"
  add_index "servers", ["user_id"], :name => "index_servers_on_user_id"

  create_table "storages", :force => true do |t|
    t.integer  "user_id"
    t.integer  "deployment_id"
    t.integer  "cloud_id"
    t.integer  "storage_type_id"
    t.string   "name"
    t.text     "description"
    t.float    "storage_size_monthly_baseline"
    t.float    "read_request_monthly_baseline"
    t.float    "write_request_monthly_baseline"
    t.integer  "quantity_monthly_baseline"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "storages", ["cloud_id"], :name => "index_storages_on_cloud_id"
  add_index "storages", ["deployment_id"], :name => "index_storages_on_deployment_id"
  add_index "storages", ["storage_type_id"], :name => "index_storages_on_storage_type_id"
  add_index "storages", ["user_id"], :name => "index_storages_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",                       :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company"
    t.string   "timezone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "currency"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true
end