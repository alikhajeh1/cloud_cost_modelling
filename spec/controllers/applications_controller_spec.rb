require 'spec_helper'

describe ApplicationsController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @deployment = given_resources_for([:deployment], :user => user)[:deployment]
    @server = @deployment.servers.first
    @application = @server.applications.first
    @applications = @deployment.applications
    @params = {:deployment_id => @deployment.id, :id => @application.id}
  end

  it "should render index" do
    get :index, :deployment_id => @deployment.id
    response.code.should == "200"
    assigns(:applications).should =~ @applications
    assigns(:deployment).should == @deployment
    response.should render_template("index")
  end

  context "update" do
    it "should update the application" do
      put :update, @params.merge(:application => {:name => 'new name'})
      response.code.should == "200"
      @application.reload.name.should == 'new name'
      assigns(:deployment).should == @deployment
    end

    it "should return a json of the update errors" do
      put :update, @params.merge(:application => {:name => ''})
      response.code.should == "422"
      response.body.should == ["Name can't be blank"].to_json
      assigns(:deployment).should == @deployment
    end
  end

  context "create" do
    it "should ask use to create servers first" do
      post :create, :deployment_id => @deployment.id, :application => {}
      response.should redirect_to(deployment_applications_url(@deployment))
      flash[:error].should == 'Please create a server before creating applications.'
    end

    it "should not create invalid application" do
      post :create, @params.merge(:application => {:name => '', :server_id => @server.id})
      assigns(:applications).should =~ @applications
      assigns(:deployment).should == @deployment
      response.should render_template("index")
    end

    it "should create application" do
      post :create, :deployment_id => @deployment.id, :application => {:name => 'new application', :server_id => @server.id}
      response.should redirect_to(deployment_applications_url(@deployment))
    end
  end

  it "should destroy the application" do
    delete :destroy, @params
    response.should redirect_to(deployment_applications_url(@deployment))
    Application.exists?(@application.id).should == false
  end

  it "should clone the application" do
    post :clone, @params
    response.should redirect_to(deployment_applications_url(@deployment))
    flash[:success].should == "Application was cloned."
  end
end