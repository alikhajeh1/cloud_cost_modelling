class DataLinksController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_deployment, :only => [:index, :update, :create, :destroy, :clone]
  before_filter :load_data_link, :only => [:update, :destroy, :clone]

  def index
    load_data_links
    @data_link = current_user.data_links.new
  end

  def show
    flash.keep
    redirect_to deployment_data_links_url(@deployment)
  end

  def update
    @data_link.sourcable = get_resource(params[:data_link].delete(:sourcable_type_id)) if params[:data_link][:sourcable_type_id]
    @data_link.targetable = get_resource(params[:data_link].delete(:targetable_type_id)) if params[:data_link][:targetable_type_id]
    if @data_link.update_attributes(params[:data_link])
      head :ok
    else
      render :json => @data_link.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def create
    # Hack: force sourcable_id to be set since we can't do it in model validations
    if params[:data_link][:sourcable].blank? || params[:data_link][:targetable].blank?
      redirect_to deployment_data_links_url(@deployment), :flash => {
          :error => 'Please create Servers/Storages/Databases/Remote Nodes before creating a data transfer between them.'}
      return true
    end

    @data_link = current_user.data_links.new(params[:data_link])
    @data_link.deployment = @deployment
    @data_link.sourcable = get_resource(params[:data_link][:sourcable])
    @data_link.targetable = get_resource(params[:data_link][:targetable])
    if @data_link.save
      redirect_to deployment_data_links_url(@deployment), :flash => {:success => 'Data transfer was created.'}
    else
      load_data_links
      # If there were other validation error, we want to remember the selected source and target
      @selected_data_link_sourcable = params[:data_link][:sourcable]
      @selected_data_link_targetable = params[:data_link][:targetable]
      render :index
    end
  end

  def clone
    begin
      @data_link.deep_clone
      redirect_to deployment_data_links_url(@deployment), :flash => {:success => 'Data transfer was cloned.'}
    rescue
      redirect_to deployment_data_links_url(@deployment), :flash => {:error => 'Data transfer could not be cloned.'}
    end
  end

  def destroy
    @data_link.destroy
    redirect_to deployment_data_links_url(@deployment), :flash => {:success => 'Data transfer was deleted.'}
  end

  private
  def load_deployment
    @deployment = current_user.deployments.find(params[:deployment_id])
  end

  def load_data_link
    @data_link = @deployment.data_links.find(params[:id])
  end

  def load_data_links
    @data_links = @deployment.data_links.page(params[:page]).order(:name)
    @deployment_resources = @deployment.get_resources_for_data_link.collect{
        |r| ["#{r.display_class}: #{r.name}", "#{r.class}:#{r.id}"]}
  end

  def get_resource(param)
    raise AppExceptions::InvalidParameter.new("Data links can only be added to a subset of deployment models.") unless
      DataLink::DATA_LINKABLE_MODELS.include?(param.split(':')[0])
    resource = param.split(':')[0].constantize.where(
      'id = ? AND deployment_id = ? AND user_id = ?', param.split(':')[1], @deployment.id, current_user.id).first
    raise ActiveRecord::RecordNotFound unless resource
    resource
  end
end