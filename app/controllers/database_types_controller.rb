class DatabaseTypesController < ApplicationController

  before_filter :authenticate_user!

  def index
    @cloud = Cloud.find(params[:cloud_id])
    @database_types = DatabaseType.all
  end
end