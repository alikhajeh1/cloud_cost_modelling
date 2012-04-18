class DataChunksController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_deployment, :only => [:index, :show, :update, :create, :destroy, :clone]
  before_filter :load_data_chunk, :only => [:update, :destroy, :clone]

  def index
    load_data_chunks
    @data_chunk = current_user.data_chunks.new
  end

  def show
    redirect_to deployment_data_chunks_url(@deployment)
  end

  def update
    if @data_chunk.update_attributes(params[:data_chunk])
      head :ok
    else
      render :json => @data_chunk.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def create
    # Hack: force storage_id to be set since we can't do it in model validations
    unless params[:data_chunk][:storage_id]
      redirect_to deployment_data_chunks_url(@deployment), :flash => {:error => 'Please create a storage unit before creating application data.'}
      return true
    end

    @data_chunk = current_user.data_chunks.new(params[:data_chunk])
    @data_chunk.deployment = @deployment
    if @data_chunk.save
      redirect_to deployment_data_chunks_url(@deployment), :flash => {:success => 'Application Data was created.'}
    else
      load_data_chunks
      render :index
    end
  end

  def destroy
    @data_chunk.destroy
    redirect_to deployment_data_chunks_url(@deployment), :flash => {:success => 'Application Data was deleted.'}
  end

  def clone
    begin
      @data_chunk.deep_clone
      redirect_to deployment_data_chunks_url(@deployment), :flash => {:success => 'Application Data was cloned.'}
    rescue
      redirect_to deployment_data_chunks_url(@deployment), :flash => {:error => 'Application Data could not be cloned.'}
    end
  end

  private
  def load_deployment
    @deployment = current_user.deployments.find(params[:deployment_id])
  end

  def load_data_chunk
    @data_chunk = @deployment.data_chunks.find(params[:id])
  end

  def load_data_chunks
    @data_chunks = @deployment.data_chunks.page(params[:page]).order('name')
  end
end