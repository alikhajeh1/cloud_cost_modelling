class ServersController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_deployment, :only => [:index, :show, :update, :create, :destroy, :clone]
  before_filter :load_server, :only => [:update, :destroy, :clone]

  def index
    load_servers
    @server = current_user.servers.new
  end

  def show
    redirect_to deployment_servers_url(@deployment)
  end

  def update
    set_cloud_resource_type(params[:server].delete(:server_type))
    if @server.update_attributes(params[:server])
      head :ok
    else
      render :json => @server.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def create
    @server = current_user.servers.new(params[:server])
    @server.deployment = @deployment
    set_cloud_resource_type(params[:cloud_server_type])

    if @server.save
      redirect_to deployment_servers_url(@deployment), :flash => {:success => 'Server was created.'}
    else
      load_servers
      # If there were other validation error, we want to remember the type that the user picked
      @selected_cloud_server_type = params[:cloud_server_type]
      render :index
    end
  end

  def destroy
    @server.destroy
    redirect_to deployment_servers_url(@deployment), :flash => {:success => 'Server was deleted.'}
  end

  def clone
    begin
      @server.deep_clone
      redirect_to deployment_servers_url(@deployment), :flash => {:success => 'Server was cloned.'}
    rescue
      redirect_to deployment_servers_url(@deployment), :flash => {:error => 'Server could not be cloned.'}
    end
  end

  private
  def load_deployment
    @deployment = current_user.deployments.find(params[:deployment_id])
  end

  def load_server
    @server = @deployment.servers.find(params[:id])
  end

  def load_servers
    @servers = @deployment.servers.page(params[:page]).order('name')
    @cloud_server_types = ServerType.all_cloud_resource_types
  end

  def set_cloud_resource_type(param)
    if param && param.include?(':')
      @server.cloud = Cloud.find(param.split(':')[0])
      @server.server_type = ServerType.find(param.split(':')[1])
    end
  end
end