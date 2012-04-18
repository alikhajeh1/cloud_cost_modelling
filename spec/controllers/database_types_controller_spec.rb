require 'spec_helper'

describe DatabaseTypesController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @cloud = Cloud.make!(:cloud_provider => CloudProvider.make!)
    @database_type =  DatabaseType.make!
    @database_types = [@database_type]
  end

  it "should render index with database types" do
    cloud_cost_structure = CloudCostStructure.make!
    CloudCostTier.make!(:cloud_cost_structure => cloud_cost_structure)
    CloudCostScheme.make!(:cloud => @cloud, :cloud_resource_type => @database_type, :cloud_cost_structure => cloud_cost_structure)

    get :index, :cloud_id => @cloud.id
    response.code.should == "200"
    assigns(:database_types).should == DatabaseType.all
    response.should render_template("index")
  end
end