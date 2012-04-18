class StorageTypesController < ApplicationController

  before_filter :authenticate_user!

  def index
    @cloud = Cloud.find(params[:cloud_id])
    @storage_types = StorageType.all
  end
end