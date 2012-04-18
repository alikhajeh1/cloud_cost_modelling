class StoragesController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_deployment, :only => [:index, :show, :update, :create, :destroy, :clone]
  before_filter :load_storage, :only => [:update, :destroy, :clone]

  def index
    load_storages
    @storage = current_user.storages.new
  end

  def show
    redirect_to deployment_storages_url(@deployment)
  end

  def update
    set_cloud_resource_type(params[:storage].delete(:storage_type))
    if @storage.update_attributes(params[:storage])
      head :ok
    else
      render :json => @storage.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def create
    @storage = current_user.storages.new(params[:storage])
    @storage.deployment = @deployment
    set_cloud_resource_type(params[:cloud_storage_type])

    if @storage.save
      redirect_to deployment_storages_url(@deployment), :flash => {:success => 'Storage was created.'}
    else
      load_storages
      # If there were other validation error, we want to remember the type that the user picked
      @selected_cloud_storage_type = params[:cloud_storage_type]
      render :index
    end
  end

  def destroy
    @storage.destroy
    redirect_to deployment_storages_url(@deployment), :flash => {:success => 'Storage was deleted.'}
  end

  def clone
    begin
      @storage.deep_clone
      redirect_to deployment_storages_url(@deployment), :flash => {:success => 'Storage was cloned.'}
    rescue
      redirect_to deployment_storages_url(@deployment), :flash => {:error => 'Storage could not be cloned.'}
    end
  end

  private
  def load_deployment
    @deployment = current_user.deployments.find(params[:deployment_id])
  end

  def load_storage
    @storage = @deployment.storages.find(params[:id])
  end

  def load_storages
    @storages = @deployment.storages.page(params[:page]).order('name')
    @cloud_storage_types = StorageType.all_cloud_resource_types
  end

  def set_cloud_resource_type(param)
    if param && param.include?(':')
      @storage.cloud = Cloud.find(param.split(':')[0])
      @storage.storage_type = StorageType.find(param.split(':')[1])
    end
  end
end