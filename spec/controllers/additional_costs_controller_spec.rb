require 'spec_helper'

describe AdditionalCostsController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @additional_cost  = AdditionalCost.make!(:user => user)
    @additional_costs = [@additional_cost]
  end

  it "should render index" do
    get :index
    response.code.should              == "200"
    assigns(:additional_costs).should == @additional_costs
    assigns(:additional_cost).should_not be_nil
    response.should render_template("index")
  end

  context "update" do
    it "should update the additional cost name" do
      put :update, :id => @additional_cost.id, :additional_cost => {:name => 'new name'}
      response.code.should                == "200"
      @additional_cost.reload.name.should == 'new name'
    end

    it "should return a json of the update errors - name blank" do
      put :update, :id => @additional_cost.id, :additional_cost => {:name => ''}
      response.code.should == "422"
      response.body.should == ["Name can't be blank"].to_json
    end

    it "should return a json of the update errors - additional cost less than zero" do
      put :update, :id => @additional_cost.id, :additional_cost => {:cost_monthly_baseline => -1}
      response.code.should == "422"
      response.body.should == ["Cost monthly baseline must be greater than or equal to 0"].to_json
    end
  end

  context "create" do
    it "should not create an invalid additional cost" do
      post :create, :additional_cost => {:name => ''}
      assigns(:additional_costs).should == @additional_costs
      response.should render_template("index")
    end

    it "should create additional cost and stay on page" do
      post :create, :additional_cost => {:name => 'new name'}
      response.should redirect_to(additional_costs_url)
    end
  end

  it "should destroy the additional cost" do
    delete :destroy, :id => @additional_cost.id
    response.should redirect_to(additional_costs_url)
    AdditionalCost.exists?(@additional_cost.id).should == false
  end

  context "clone" do
    it "should redirect to index if clone fails" do
      flexmock(controller.current_user).should_receive("additional_costs.find").and_return(@additional_cost)
      flexmock(@additional_cost).should_receive("deep_clone").and_raise(RuntimeError)
      post :clone, :id => @additional_cost.id
      response.should redirect_to(additional_costs_url)
      flash[:error].should == "Additional cost could not be cloned."
    end

    it "should clone the additional cost" do
      post :clone, :id => @additional_cost.id
      response.should redirect_to(additional_costs_url)
      flash[:success].should == "Additional cost was cloned."
    end
  end
end