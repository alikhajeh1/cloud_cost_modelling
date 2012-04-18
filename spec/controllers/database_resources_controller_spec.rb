require 'spec_helper'

describe DatabaseResourcesController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @deployment = given_resources_for([:deployment], :user => user)[:deployment]
    @database = @deployment.database_resources.first
    @databases = @deployment.database_resources
    @params = {:deployment_id => @deployment.id, :id => @database.id}


  end

  it "should render index" do
    get :index, :deployment_id => @deployment.id
    response.code.should                == "200"
    assigns(:database_resources).should =~ @databases
    assigns(:deployment).should         == @deployment
    response.should render_template("index")
  end

  it "should show deployment databases" do
    get :show, :deployment_id => @deployment.id, :id => @database.id
    response.should redirect_to(deployment_database_resources_url(@deployment))
  end

  context "update" do
    it "should update the database" do
      put :update, @params.merge(:database_resource => {:name => 'new name'})
      response.code.should         == "200"
      @database.reload.name.should == 'new name'
      assigns(:deployment).should  == @deployment
    end

    it "should return a json of the update errors" do
      put :update, @params.merge(:database_resource => {:name => ''})
      response.code.should        == "422"
      response.body.should        == ["Name can't be blank"].to_json
      assigns(:deployment).should == @deployment
    end
  end

  context "create" do
    it "should not create invalid database" do
      post :create, @params.merge(:database_resource => {:name => ''})
      assigns(:database_resources).should =~ @databases
      assigns(:deployment).should == @deployment
      response.should render_template("index")
    end

    it "should create database" do
      @cloud = Cloud.make!(:cloud_provider => CloudProvider.make!)
      @database_type = DatabaseType.make!
      cost_structure = CloudCostStructure.make!
      cost_scheme = CloudCostScheme.make!(:cloud => @cloud, :cloud_resource_type => @database_type, :cloud_cost_structure => cost_structure)

      cloud_database_type = "#{@cloud.id}:#{@database_type.id}"
      post :create, @params.merge(:database_resource => {:name => 'Test'}, :cloud_database_type => cloud_database_type)
      response.should redirect_to(deployment_database_resources_url(@deployment))
      flash[:success].should == 'Database was created.'
    end
  end

  it "should destroy the database" do
    delete :destroy, @params
    response.should redirect_to(deployment_database_resources_url(@deployment))
    DatabaseResource.exists?(@database.id).should == false
  end

  it "should clone the database" do
    post :clone, @params
    response.should redirect_to(deployment_database_resources_url(@deployment))
    flash[:success].should == "Database was cloned."
  end
end