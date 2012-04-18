require 'spec_helper'

describe DataLinksController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @deployment = given_resources_for([:deployment], :user => user)[:deployment]
    @data_link = @deployment.data_links.first
    @data_links = @deployment.data_links
    @params = {:deployment_id => @deployment.id, :id => @data_link.id}
  end

  it "should render index" do
    get :index, :deployment_id => @deployment.id
    response.code.should              == "200"
    assigns(:data_links).should       =~ @data_links
    assigns(:deployment).should       == @deployment
    assigns(:deployment_resources).should == @deployment.get_resources_for_data_link.collect{
        |r| ["#{r.display_class}: #{r.name}", "#{r.class}:#{r.id}"]}
    response.should render_template("index")
  end

  it "should show deployment data_links" do
    get :show, :deployment_id => @deployment.id, :id => @data_link.id
    response.should redirect_to(deployment_data_links_url(@deployment))
  end

  context "update" do
    it "should update the data_link's sourcable/targetable" do
      old_sourcable  = @data_link.sourcable
      old_targetable = @data_link.targetable
      put :update, @params.merge(:data_link => {:sourcable_type_id => @data_link.targetable_type_id,
                                                :targetable_type_id => @data_link.sourcable_type_id})
      response.code.should == "200"
      @data_link.reload
      @data_link.sourcable.should == old_targetable
      @data_link.targetable.should == old_sourcable
      assigns(:deployment).should == @deployment
    end

    it "should update the data_link" do
      put :update, @params.merge(:data_link => {:source_to_target_monthly_baseline => 123})
      response.code.should == "200"
      @data_link.reload.source_to_target_monthly_baseline.should == 123
      assigns(:deployment).should == @deployment
    end

    it "should return a json of the update errors" do
      put :update, @params.merge(:data_link => {:source_to_target_monthly_baseline => -1})
      response.code.should == "422"
      response.body.should == ["Source to target monthly baseline must be greater than or equal to 0"].to_json
      assigns(:deployment).should == @deployment
    end
  end

  context "create" do
    it "should not create invalid data_link (no sourcable/targetable)" do
      post :create, @params.merge(:data_link => {})
      response.should redirect_to(deployment_data_links_url(@deployment))
      flash[:error].should == 'Please create Servers/Storages/Databases/Remote Nodes before creating a data transfer between them.'
    end

    it "should not create invalid data_link (bad sourcable/targetable)" do
      lambda {post :create, @params.merge(:data_link => {:sourcable => 'A', :targetable => 'B'})}.should
          raise_error(AppExceptions::InvalidParameter, "Data links can only be added to a subset of deployment models.")
    end

    it "should not create invalid data_link (sourcable/targetable not found)" do
      lambda {post :create, @params.merge(:data_link => {:sourcable => 'Server:0', :targetable => "Server:#{Server.first.id}"})}.should raise_error(ActiveRecord::RecordNotFound)

      lambda {post :create, @params.merge(:data_link => {:sourcable => "Server:#{Server.first.id}", :targetable => 'Server:0'})}.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should create data_link" do
      # Create a data_link like the @data_link but with source/target flipped
      post :create, @params.merge(:data_link => {:sourcable => @data_link.targetable_type_id,
                                                 :targetable => @data_link.sourcable_type_id,
                                                 :source_to_target_monthly_baseline => 2, :target__to_source_monthly_baseline => 3})
      response.should redirect_to(deployment_data_links_url(@deployment))
      flash[:success].should == 'Data transfer was created.'
      @deployment.reload.data_links.last.sourcable = @data_link.targetable
      @deployment.data_links.last.targetable = @data_link.sourcable
      @deployment.data_links.last.source_to_target_monthly_baseline = 2
      @deployment.data_links.last.target_to_source_monthly_baseline = 3
    end
  end

  it "should destroy the data_link" do
    delete :destroy, @params
    response.should redirect_to(deployment_data_links_url(@deployment))
    DataLink.exists?(@data_link.id).should == false
  end

  it "should clone the data_link" do
    post :clone, @params
    response.should redirect_to(deployment_data_links_url(@deployment))
    flash[:success].should == "Data transfer was cloned."
  end
end