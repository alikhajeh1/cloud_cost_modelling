require 'spec_helper'

describe DashboardController do
  render_views
  let(:user) { User.make! }

  before(:each) do
   sign_in user
  end

  it "should render the dashboard" do
    deployment = Deployment.make!(:user => user, :name => 'Example deployment')
    cloud_provider = CloudProvider.make!
    Cloud.make!(:cloud_provider => cloud_provider)

    get :index
    response.code.should == "200"
    assigns(:recent_deployments).should == [deployment]
    assigns(:example_deployment).should == deployment
    assigns(:cloud_providers).should include(cloud_provider)
    assigns(:cloud_count).should > 1
    response.should render_template("index")
  end

  it "should render the dashboard when there is no example deployment" do
    get :index
    response.code.should == "200"
    assigns(:recent_deployment).should be_nil
    assigns(:example_deployment).should be_nil
    response.should render_template("index")
  end

end