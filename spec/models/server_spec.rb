require 'spec_helper'

describe Server do
  let(:user) { User.make! }

  it "should be invalid without a name, user, deployment, server and cloud" do
    server = Server.new()
    server.should have(1).error_on(:name)
    server.should have(1).error_on(:user_id)
    server.should have(1).error_on(:deployment_id)
    server.should have(1).error_on(:server_type_id)
    server.should have(1).error_on(:cloud_id)
    server.errors.count.should == 5
    server.should_not be_valid
  end

  it "should be deep cloned" do
    cloud_provider = CloudProvider.make!
    cloud = Cloud.make!(:name => 'TestCloud', :cloud_provider => cloud_provider)
    server = Server.make(:user => user)
    server.deployment = Deployment.make!(:user => user)
    server.server_type = ServerType.make!
    server.cloud = cloud
    server.add_patterns('instance_hour_monthly_baseline', [Pattern.make!(:user => user)])
    server.add_patterns('quantity_monthly_baseline', [Pattern.make!(:user => user)])
    server.save
    new_server = server.deep_clone

    new_server.should be_valid
    new_server.name.should            == "Copy of #{server.name}"
    new_server.user.should            == server.user
    new_server.deployment.should      == server.deployment
    new_server.patterns.count.should  == server.patterns.count
  end

end