require 'spec_helper'

describe ServerTypesController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @cloud = Cloud.make!(:cloud_provider => CloudProvider.make!)
    @server_type =  ServerType.make!
    @server_types = [@server_type]
  end

  it "should render index with server types" do
    cloud_cost_structure = CloudCostStructure.make!
    cloud_cost_tier = CloudCostTier.make!(:cloud_cost_structure => cloud_cost_structure)
    CloudCostScheme.make!(:cloud => @cloud, :cloud_resource_type => @server_type, :cloud_cost_structure => cloud_cost_structure)

    get :index, :cloud_id => @cloud.id
    response.code.should == "200"
    assigns(:server_types).should == ServerType.all
    response.should render_template("index")
  end
end