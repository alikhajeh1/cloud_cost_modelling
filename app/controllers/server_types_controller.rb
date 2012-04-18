class ServerTypesController < ApplicationController

  before_filter :authenticate_user!

  def index
    @cloud = Cloud.find(params[:cloud_id])
    @server_types = ServerType.all
  end
end