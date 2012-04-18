class DatabaseResourcesController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_deployment, :only => [:index, :show, :update, :create, :destroy, :clone]
  before_filter :load_database_resource, :only => [:update, :destroy, :clone]

  def index
    load_database_resources
    @database_resource = current_user.database_resources.new
  end

  def show
    redirect_to deployment_database_resources_url(@deployment)
  end

  def update
    set_cloud_resource_type(params[:database_resource].delete(:database_type))
    if @database_resource.update_attributes(params[:database_resource])
      head :ok
    else
      render :json => @database_resource.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def create
    @database_resource = current_user.database_resources.new(params[:database_resource])
    @database_resource.deployment = @deployment
    set_cloud_resource_type(params[:cloud_database_type])

    if @database_resource.save
      redirect_to deployment_database_resources_url(@deployment), :flash => {:success => 'Database was created.'}
    else
      load_database_resources
      # If there were other validation error, we want to remember the type that the user picked
      @selected_cloud_database_type = params[:cloud_database_type]
      render :index
    end
  end

  def destroy
    @database_resource.destroy
    redirect_to deployment_database_resources_url(@deployment), :flash => {:success => 'Database was deleted.'}
  end

  def clone
    begin
      @database_resource.deep_clone
      redirect_to deployment_database_resources_url(@deployment), :flash => {:success => 'Database was cloned.'}
    rescue
      redirect_to deployment_database_resources_url(@deployment), :flash => {:error => 'Database could not be cloned.'}
    end
  end

  private
  def load_deployment
    @deployment = current_user.deployments.find(params[:deployment_id])
  end

  def load_database_resource
    @database_resource = @deployment.database_resources.find(params[:id])
  end

  def load_database_resources
    @database_resources = @deployment.database_resources.page(params[:page]).order('name')
    @cloud_database_types = DatabaseType.all_cloud_resource_types
  end

  def set_cloud_resource_type(param)
    if param && param.include?(':')
      @database_resource.cloud = Cloud.find(param.split(':')[0])
      @database_resource.database_type = DatabaseType.find(param.split(':')[1])
    end
  end
end