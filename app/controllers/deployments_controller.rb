class DeploymentsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_deployment, :only => [:show, :update, :destroy, :clone]

  def index
    load_deployments
    @deployment = current_user.deployments.new
  end

  def show
    flash.keep
    # By default, go to the servers tab of the deployment when it's opened
    redirect_to deployment_servers_url(@deployment)
  end

  def update
    if @deployment.update_attributes(params[:deployment])
      head :ok
    else
      render :json => @deployment.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def create
    @deployment = current_user.deployments.new(params[:deployment])
    if @deployment.save
      redirect_to @deployment, :flash => {:success => 'Deployment was created.'}
    else
      load_deployments
      render :index
    end
  end

  def destroy
    @deployment.destroy
    redirect_to deployments_url, :flash => {:success => 'Deployment and all of its resources were deleted.'}
  end

  def clone
    begin
      new_deployment = @deployment.deep_clone
      redirect_to new_deployment, :flash => {:success => 'Deployment and all of its resources were cloned.'}
    rescue
      redirect_to deployments_url, :flash => {:error => 'Deployment could not be cloned.'}
    end
  end

  private
  def load_deployment
    @deployment = current_user.deployments.find(params[:id])
  end

  def load_deployments
    @deployments = current_user.deployments.page(params[:page]).order(:name)
  end
end