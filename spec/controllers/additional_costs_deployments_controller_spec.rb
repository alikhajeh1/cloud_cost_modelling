require 'spec_helper'

describe AdditionalCostsDeploymentsController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @deployment = given_resources_for([:deployment], :user => user)[:deployment]
    @additional_cost  = AdditionalCost.make!(:user => user)
  end

  it "should render index" do
    get :index, :deployment_id      => @deployment.id
    response.code.should            == "200"
    assigns(:deployment).should     == @deployment
    response.should render_template("index")
  end

  context "update" do
    it "should add the additional cost to deployment" do
      put :update, :deployment_id => @deployment.id, :id  => @additional_cost.id
      response.code.should         == "200"
      @deployment.additional_costs =~ @additional_cost
      assigns(:deployment).should  == @deployment
    end

    it "should remote the additional cost from deployment" do
      # Make two update requests, the first adds as per the previous test, the second should remove it again
      put :update, :deployment_id => @deployment.id, :id  => @additional_cost.id
      put :update, :deployment_id => @deployment.id, :id  => @additional_cost.id
      response.code.should         == "200"
      @deployment.additional_costs.should_not include @additional_cost
      assigns(:deployment).should  == @deployment
    end
  end
end