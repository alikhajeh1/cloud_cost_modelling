require 'spec_helper'

describe RemoteNodesController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @deployment = given_resources_for([:deployment], :user => user)[:deployment]
    @remote_node = @deployment.remote_nodes.first
    @remote_nodes = @deployment.remote_nodes
    @params = {:deployment_id => @deployment.id, :id => @remote_node.id}
  end

  it "should render index" do
    get :index, :deployment_id => @deployment.id
    response.code.should                == "200"
    assigns(:remote_nodes).should =~ @remote_nodes
    assigns(:deployment).should         == @deployment
    response.should render_template("index")
  end

  it "should show deployment remote nodes" do
    get :show, :deployment_id => @deployment.id, :id => @remote_node.id
    response.should redirect_to(deployment_remote_nodes_url(@deployment))
  end

  context "update" do
    it "should update the remote node" do
      put :update, @params.merge(:remote_node => {:name => 'new name'})
      response.code.should         == "200"
      @remote_node.reload.name.should == 'new name'
      assigns(:deployment).should  == @deployment
    end

    it "should return a json of the update errors" do
      put :update, @params.merge(:remote_node => {:name => ''})
      response.code.should        == "422"
      response.body.should        == ["Name can't be blank"].to_json
      assigns(:deployment).should == @deployment
    end
  end

  context "create" do
    it "should not create invalid remote node" do
      post :create, @params.merge(:remote_node => {:name => ''})
      assigns(:remote_nodes).should =~ @remote_nodes
      assigns(:deployment).should == @deployment
      response.should render_template("index")
    end

    it "should create remote node" do
      post :create, @params.merge(:remote_node => {:name => 'Test'})
      response.should redirect_to(deployment_remote_nodes_url(@deployment))
      flash[:success].should == 'Remote node was created.'
    end
  end

  it "should destroy the remote node" do
    delete :destroy, @params
    response.should redirect_to(deployment_remote_nodes_url(@deployment))
    RemoteNode.exists?(@remote_node.id).should == false
  end
end