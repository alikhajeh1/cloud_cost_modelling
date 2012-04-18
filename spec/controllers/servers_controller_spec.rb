require 'spec_helper'

describe ServersController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @deployment = given_resources_for([:deployment], :user => user)[:deployment]
    @server = @deployment.servers.first
    @servers = @deployment.servers
    @params = {:deployment_id => @deployment.id, :id => @server.id}
  end

  it "should render index" do
    get :index, :deployment_id => @deployment.id
    response.code.should              == "200"
    assigns(:servers).should          =~ @servers
    assigns(:deployment).should       == @deployment
    response.should render_template("index")
  end

  it "should show deployment servers" do
    get :show, :deployment_id => @deployment.id, :id => @server.id
    response.should redirect_to(deployment_servers_url(@deployment))
  end

  context "update" do
    it "should update the server" do
      put :update, @params.merge(:server => {:name => 'new name'})
      response.code.should == "200"
      @server.reload.name.should == 'new name'
      assigns(:deployment).should == @deployment
    end

    it "should return a json of the update errors" do
      put :update, @params.merge(:server => {:name => ''})
      response.code.should == "422"
      response.body.should == ["Name can't be blank"].to_json
      assigns(:deployment).should == @deployment
    end
  end

  context "create" do
    it "should not create invalid server" do
      post :create, @params.merge(:server => {:name => ''})
      assigns(:servers).should =~ @servers
      assigns(:deployment).should == @deployment
      response.should render_template("index")
    end

    it "should create server" do
      @cloud = Cloud.make!(:cloud_provider => CloudProvider.make!)
      @server_type = ServerType.make!
      cost_structure = CloudCostStructure.make!
      cost_scheme = CloudCostScheme.make!(:cloud => @cloud, :cloud_resource_type => @server_type, :cloud_cost_structure => cost_structure)

      cloud_server_type = "#{@cloud.id}:#{@server_type.id}"
      post :create, @params.merge(:server => {:name => 'Test'}, :cloud_server_type => cloud_server_type)
      response.should redirect_to(deployment_servers_url(@deployment))
      flash[:success].should == 'Server was created.'
    end
  end

  it "should destroy the server" do
    delete :destroy, @params
    response.should redirect_to(deployment_servers_url(@deployment))
    Server.exists?(@server.id).should == false
  end

  it "should clone the server" do
    post :clone, @params
    response.should redirect_to(deployment_servers_url(@deployment))
    flash[:success].should == "Server was cloned."
  end
end