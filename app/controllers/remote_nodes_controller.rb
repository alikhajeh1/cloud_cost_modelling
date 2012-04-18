class RemoteNodesController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_deployment, :only => [:index, :show, :update, :create, :destroy]
  before_filter :load_remote_node, :only => [:update, :destroy]

  def index
    load_remote_nodes
    @remote_node = current_user.remote_nodes.new
  end

  def show
    redirect_to deployment_remote_nodes_url(@deployment)
  end

  def update
    if @remote_node.update_attributes(params[:remote_node])
      head :ok
    else
      render :json => @remote_node.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def create
    @remote_node = current_user.remote_nodes.new(params[:remote_node])
    @remote_node.deployment = @deployment

    if @remote_node.save
      redirect_to deployment_remote_nodes_url(@deployment), :flash => {:success => 'Remote node was created.'}
    else
      load_remote_nodes
      render :index
    end
  end

  def destroy
    @remote_node.destroy
    redirect_to deployment_remote_nodes_url(@deployment), :flash => {:success => 'Remote node was deleted.'}
  end

  private
  def load_deployment
    @deployment = current_user.deployments.find(params[:deployment_id])
  end

  def load_remote_node
    @remote_node = @deployment.remote_nodes.find(params[:id])
  end

  def load_remote_nodes
    @remote_nodes = @deployment.remote_nodes.page(params[:page]).order('name')
  end
end