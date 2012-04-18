require 'spec_helper'

describe StorageTypesController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @cloud = Cloud.make!(:cloud_provider => CloudProvider.make!)
    @storage_type =  StorageType.make!
    @storage_types = [@storage_type]
  end

  it "should render index with storage types" do
    @cloud_cost_structure = CloudCostStructure.make!(:name => 'storage_size')
    @cloud_cost_tier = CloudCostTier.make!(:cloud_cost_structure => @cloud_cost_structure)
    @cloud_cost_scheme = CloudCostScheme.make!(:cloud => @cloud, :cloud_resource_type => @storage_type, :cloud_cost_structure => @cloud_cost_structure)

    get :index, :cloud_id => @cloud.id
    response.code.should == "200"
    assigns(:storage_types).should == StorageType.all
    response.should render_template("index")
  end
end