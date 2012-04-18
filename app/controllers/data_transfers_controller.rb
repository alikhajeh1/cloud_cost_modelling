class DataTransfersController < ApplicationController

  before_filter :authenticate_user!

  def index
    @cloud = Cloud.find(params[:cloud_id])
    @server_type = ServerType.first(:include => [:clouds], :conditions => ["clouds.id = ?", @cloud.id])
  end
end