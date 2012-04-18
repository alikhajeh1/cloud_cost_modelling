class CloudsController < ApplicationController

  before_filter :authenticate_user!

  def index
    @clouds = Cloud.page(params[:page]).order(:name)
  end

  def show
    @cloud = Cloud.find(params[:id])
    # By default, go to the Server Types tab of the cloud when it's opened
    redirect_to cloud_server_types_url(@cloud)
  end

end