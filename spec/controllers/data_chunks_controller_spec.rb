require 'spec_helper'

describe DataChunksController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @deployment = given_resources_for([:deployment], :user => user)[:deployment]
    @storage = @deployment.storages.first
    @data_chunk = @storage.data_chunks.first
    @data_chunks = @deployment.data_chunks
    @params = {:deployment_id => @deployment.id, :id => @data_chunk.id}
  end

  it "should render index" do
    get :index, :deployment_id => @deployment.id
    response.code.should == "200"
    assigns(:data_chunks).should =~ @data_chunks
    assigns(:deployment).should == @deployment
    response.should render_template("index")
  end

  context "update" do
    it "should update the data_chunk" do
      put :update, @params.merge(:data_chunk => {:name => 'new name'})
      response.code.should == "200"
      @data_chunk.reload.name.should == 'new name'
      assigns(:deployment).should == @deployment
    end

    it "should return a json of the update errors" do
      put :update, @params.merge(:data_chunk => {:name => ''})
      response.code.should == "422"
      response.body.should == ["Name can't be blank"].to_json
      assigns(:deployment).should == @deployment
    end
  end

  context "create" do
    it "should ask use to create a storage first" do
      post :create, :deployment_id => @deployment.id, :data_chunk => {}
      response.should redirect_to(deployment_data_chunks_url(@deployment))
      flash[:error].should == 'Please create a storage unit before creating application data.'
    end

    it "should not create invalid data_chunk" do
      post :create, @params.merge(:data_chunk => {:name => '', :storage_id => @storage.id})
      assigns(:data_chunks).should =~ @data_chunks
      assigns(:deployment).should == @deployment
      response.should render_template("index")
    end

    it "should create data_chunk" do
      post :create, :deployment_id => @deployment.id, :data_chunk => {:name => 'new data_chunk', :storage_id => @storage.id}
      response.should redirect_to(deployment_data_chunks_url(@deployment))
    end
  end

  it "should destroy the data_chunk" do
    delete :destroy, @params
    response.should redirect_to(deployment_data_chunks_url(@deployment))
    DataChunk.exists?(@data_chunk.id).should == false
  end

  it "should clone the data_chunk" do
    post :clone, @params
    response.should redirect_to(deployment_data_chunks_url(@deployment))
    flash[:success].should == "Application Data was cloned."
  end
end