require 'spec_helper'

describe StoragesController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @deployment = given_resources_for([:deployment], :user => user)[:deployment]
    @storage = @deployment.storages.first
    @storages = @deployment.storages
    @params = {:deployment_id => @deployment.id, :id => @storage.id}


  end

  it "should render index" do
    get :index, :deployment_id => @deployment.id
    response.code.should              == "200"
    assigns(:storages).should          =~ @storages
    assigns(:deployment).should       == @deployment
    response.should render_template("index")
  end

  it "should show deployment storage" do
    get :show, :deployment_id => @deployment.id, :id => @storage.id
    response.should redirect_to(deployment_storages_url(@deployment))
  end

  context "update" do
    it "should update the storage" do
      put :update, @params.merge(:storage => {:name => 'new name'})
      response.code.should == "200"
      @storage.reload.name.should == 'new name'
      assigns(:deployment).should == @deployment
    end

    it "should return a json of the update errors" do
      put :update, @params.merge(:storage => {:name => ''})
      response.code.should == "422"
      response.body.should == ["Name can't be blank"].to_json
      assigns(:deployment).should == @deployment
    end
  end

  context "create" do
    it "should not create invalid storage" do
      post :create, @params.merge(:storage => {:name => ''})
      assigns(:storages).should =~ @storages
      assigns(:deployment).should == @deployment
      response.should render_template("index")
    end

    it "should create application" do
      @cloud = Cloud.make!(:cloud_provider => CloudProvider.make!)
      @storage_type = StorageType.make!
      cost_structure = CloudCostStructure.make!
      cost_scheme = CloudCostScheme.make!(:cloud => @cloud, :cloud_resource_type => @storage_type, :cloud_cost_structure => cost_structure)

      cloud_storage_type = "#{@cloud.id}:#{@storage_type.id}"
      post :create, @params.merge(:storage => {:name => 'Test'}, :cloud_storage_type => cloud_storage_type)
      response.should redirect_to(deployment_storages_url(@deployment))
      flash[:success].should == 'Storage was created.'
    end
  end

  it "should destroy the storage" do
    delete :destroy, @params
    response.should redirect_to(deployment_storages_url(@deployment))
    Storage.exists?(@storage.id).should == false
  end

  it "should clone the storage" do
    post :clone, @params
    response.should redirect_to(deployment_storages_url(@deployment))
    flash[:success].should == "Storage was cloned."
  end
end