class AdditionalCostsDeploymentsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_deployment, :only => [:index, :update]

  def index
    @additional_costs = current_user.additional_costs.page(params[:page]).order(:name)
  end

  def update
    @additional_cost = current_user.additional_costs.find(params[:id])
    if @deployment.additional_costs.include?(@additional_cost)
      @deployment.additional_costs.delete(@additional_cost)
    else
      @deployment.additional_costs << @additional_cost
    end
    head :ok
  end

  private
  def load_deployment
    @deployment = current_user.deployments.find(params[:deployment_id], :include => :additional_costs)
  end
end