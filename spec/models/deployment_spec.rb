require 'spec_helper'

describe Deployment do
  let(:user) { User.make! }

  it "should be invalid without a user and a name" do
    deployment = Deployment.new()
    deployment.should have(1).error_on(:name)
    deployment.should have(1).error_on(:user_id)
    deployment.errors.count.should == 2
    deployment.should_not be_valid
  end

  context "clone" do
    it "should be deep cloned, including all of its associations" do
      deployment = given_resources_for([:deployment])[:deployment]
      new_deployment = deployment.deep_clone

      new_deployment.should be_valid
      new_deployment.name.should                     == "Copy of #{deployment.name}"
      Deployment.last.should                         == new_deployment
      new_deployment.user.should                     == deployment.user
      new_deployment.applications.count.should       == deployment.applications.count
      new_deployment.data_chunks.count.should        == deployment.data_chunks.count
      new_deployment.database_resources.count.should == deployment.database_resources.count
      new_deployment.servers.count.should            == deployment.servers.count
      new_deployment.storages.count.should           == deployment.storages.count
      new_deployment.remote_nodes.count.should       == deployment.remote_nodes.count
      new_deployment.data_links.count.should         == deployment.data_links.count
      new_deployment.applications.first.patterns.count.should == deployment.applications.first.patterns.count
    end

    it "should be deep cloned with a new name" do
      deployment = Deployment.make!(:user => user)
      new_deployment = deployment.deep_clone(:name => 'deployment2')
      new_deployment.name.should == "deployment2"
      new_deployment.should be_valid
    end
  end
end