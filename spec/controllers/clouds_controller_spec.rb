require 'spec_helper'

describe CloudsController do
  render_views
  let(:user) { User.make! }

  before(:each) do
   sign_in user
    @cloud = Cloud.make!(:cloud_provider => CloudProvider.make!)
  end

  it "should render index of clouds" do
    @cloud_two = Cloud.make!(:cloud_provider => CloudProvider.make!)
    @clouds = [@cloud, @cloud_two]

    get :index
    response.code.should == "200"
    assigns(:clouds).should_not be_nil
    assigns(:clouds).count.should be >= 2
    response.should render_template("index")
  end

  it "should show cloud given cloud id" do
    get :show, :id => @cloud.id
    response.should redirect_to(cloud_server_types_url(@cloud))
  end
end