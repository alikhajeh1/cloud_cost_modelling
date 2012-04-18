class AdditionalCostsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_additional_cost, :only => [:update, :destroy, :clone]

  def index
    load_additional_costs
    @additional_cost = current_user.additional_costs.new
  end

  def show
    redirect_to additional_costs_url
  end

  def update
    if @additional_cost.update_attributes(params[:additional_cost])
      head :ok
    else
      render :json => @additional_cost.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def create
    @additional_cost = current_user.additional_costs.new(params[:additional_cost])
    if @additional_cost.save
      redirect_to additional_costs_url, :flash => {:success => 'Additional cost was created.'}
    else
      load_additional_costs
      render :index
    end
  end

  def destroy
    @additional_cost.destroy
    redirect_to additional_costs_url, :flash => {:success => 'Additional cost was deleted, all deployments that used this additional cost have been updated.'}
  end

  def clone
    begin
      @additional_cost.deep_clone
      redirect_to additional_costs_url, :flash => {:success => 'Additional cost was cloned.'}
    rescue
      redirect_to additional_costs_url, :flash => {:error => 'Additional cost could not be cloned.'}
    end
  end

  private
  def load_additional_cost
    @additional_cost = current_user.additional_costs.find(params[:id])
  end

  def load_additional_costs
    @additional_costs = current_user.additional_costs.includes(:deployments).page(params[:page]).order(:name)
  end
end
