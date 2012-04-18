require 'spork'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  ENV['RAILS_ENV'] = 'test'
  require 'simplecov'
  SimpleCov.start do
    add_filter "lib/model_mixins/initialize_user.rb"
  end if ENV['COVERAGE']


  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  Spork.trap_method(Rails::Application::RoutesReloader, :reload!)
  require File.expand_path(File.dirname(__FILE__) + "/support/factory_spec_helper")
  require File.expand_path(File.dirname(__FILE__) + "/support/cloud_maker")

  RSpec.configure do |config|
    config.mock_with :flexmock
    config.use_transactional_fixtures = true
    config.use_instantiated_fixtures  = false

    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true
    config.include Devise::TestHelpers, :type => :controller
    config.include FactorySpecHelper
  end
  CloudMaker.create_test_clouds
end

Spork.each_run do
  # This code will be run each time you run your specs.
  require File.expand_path(File.dirname(__FILE__) + "/support/blueprints")
end