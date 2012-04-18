require 'spec_helper'

describe DeploymentsController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @deployment = Deployment.make!(:user => user)
    @deployments = [@deployment]
  end

  it "should render index" do
    get :index
    response.code.should         == "200"
    assigns(:deployments).should == @deployments
    assigns(:deployment).should_not be_nil
    response.should render_template("index")
  end

  it "should redirect to the servers index from show" do
    get :show, :id => @deployment.id
    response.should redirect_to(deployment_servers_url(@deployment))
  end

  context "update" do
    it "should update the deployment" do
      put :update, :id => @deployment.id, :deployment => {:name => 'new name'}
      response.code.should           == "200"
      @deployment.reload.name.should == 'new name'
    end

    it "should return a json of the update errors" do
      put :update, :id => @deployment.id, :deployment => {:name => ''}
      response.code.should == "422"
      response.body.should == ["Name can't be blank"].to_json
    end
  end

  context "create" do
    it "should not create invalid deployment" do
      post :create, :deployment => {:name => ''}
      assigns(:deployments).should == @deployments
      response.should render_template("index")
    end

    it "should create deployment" do
      post :create, :deployment => {:name => 'new deployment'}
      response.should redirect_to(Deployment.last)
    end
  end

  it "should destroy the deployment" do
    delete :destroy, :id => @deployment.id
    response.should redirect_to(deployments_url)
    Deployment.exists?(@deployment.id).should == false
  end

  context "clone" do
    it "should redirect to index if clone fails" do
      flexmock(controller.current_user).should_receive("deployments.find").and_return(@deployment)
      flexmock(@deployment).should_receive("deep_clone").and_return(Exception.new)
      post :clone, :id => @deployment.id
      response.should redirect_to(deployments_url)
      flash[:error].should == "Deployment could not be cloned."
    end

    it "should clone the deployment" do
      post :clone, :id => @deployment.id
      response.should redirect_to(Deployment.last)
    end
  end
end