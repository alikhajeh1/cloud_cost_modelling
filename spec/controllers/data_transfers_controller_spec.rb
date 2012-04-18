require 'spec_helper'

describe DataTransfersController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @cloud = Cloud.make!(:cloud_provider => CloudProvider.make!)
    @server_type =  ServerType.make!
  end

  it "should render index with data transfer costs" do
    cloud_cost_structure = CloudCostStructure.make!(:name => 'data_in')
    CloudCostScheme.make!(:cloud => @cloud, :cloud_resource_type => @server_type, :cloud_cost_structure => cloud_cost_structure)

    cloud_cost_structure = CloudCostStructure.make!(:name => 'data_out')
    CloudCostScheme.make!(:cloud => @cloud, :cloud_resource_type => @server_type, :cloud_cost_structure => cloud_cost_structure)

    get :index, :cloud_id => @cloud.id
    response.code.should == "200"
    assigns(:server_type).should == ServerType.first(:include => [:clouds], :conditions => ["clouds.id = ?", @cloud.id])
    response.should render_template("index")
  end

  it "should render index with no data transfers" do
    get :index, :cloud_id => @cloud.id
    response.code.should == "200"
    assigns(:server_type).should == ServerType.first(:include => [:clouds], :conditions => ["clouds.id = ?", @cloud.id])
    response.should render_template("index")
  end

end