class DashboardController < ApplicationController

  before_filter :authenticate_user!

  def index
    current_user.initialize_new_user
    number_of_deployments = 5
    @recent_deployments = current_user.deployments.all(:include => :report, :limit => number_of_deployments+1,
                                                       :order => "updated_at DESC")
    if @recent_deployments.length > number_of_deployments
      @more_deployments = true
      @recent_deployments.pop
    end
    @example_deployment = current_user.deployments.find_by_name('Example deployment')
    @cloud_providers = CloudProvider.all(:include => :clouds, :order => :name)
    @cloud_count = Cloud.count
  end
end
