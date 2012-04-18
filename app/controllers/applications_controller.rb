class ApplicationsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_deployment, :only => [:index, :show, :update, :create, :destroy, :clone]
  before_filter :load_application, :only => [:update, :destroy, :clone]

  def index
    load_applications
    @application = current_user.applications.new
  end

  def show
    redirect_to deployment_application_url(@deployment)
  end

  def update
    if @application.update_attributes(params[:application])
      head :ok
    else
      render :json => @application.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def create
    # Hack: force server_id to be set since we can't do it in model validations
    unless params[:application][:server_id]
      redirect_to deployment_applications_url(@deployment), :flash => {:error => 'Please create a server before creating applications.'}
      return true
    end

    @application = current_user.applications.new(params[:application])
    @application.deployment = @deployment
    if @application.save
      redirect_to deployment_applications_url(@deployment), :flash => {:success => 'Application was created.'}
    else
      load_applications
      render :index
    end
  end

  def destroy
    @application.destroy
    redirect_to deployment_applications_url(@deployment), :flash => {:success => 'Application was deleted.'}
  end

  def clone
    begin
      @application.deep_clone
      redirect_to deployment_applications_url(@deployment), :flash => {:success => 'Application was cloned.'}
    rescue
      redirect_to deployment_applications_url(@deployment), :flash => {:error => 'Application could not be cloned.'}
    end
  end

  private
  def load_deployment
    @deployment = current_user.deployments.find(params[:deployment_id])
  end

  def load_application
    @application = @deployment.applications.find(params[:id])
  end

  def load_applications
    @applications = @deployment.applications.page(params[:page]).order('name')
  end
end