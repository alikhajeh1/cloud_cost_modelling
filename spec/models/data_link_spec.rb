require 'spec_helper'

describe DataLink do
  let(:user) { User.make! }

  context "DataLink creation" do
    before(:all) do
      @deployment = given_resources_for([:deployment], :user => user)[:deployment]
    end

    it "should be invalid without a user, deployment and sourcable" do
      data_link = DataLink.new()
      data_link.should have(1).error_on(:user_id)
      data_link.should have(1).error_on(:deployment_id)
      # Sourcable is equal to Targetable at this point and therefore the following error should occur
      data_link.should have(1).error_on(:sourcable)
      data_link.errors.count.should == 3
      data_link.should_not be_valid
    end

    it "should be invalid if sourcable/targetable is in different deployment" do
      data_link = @deployment.data_links.first
      data_link.sourcable = given_resources_for([:server], :user => user)[:server]
      data_link.should_not be_valid
      data_link.should have(1).error_on(:sourcable)
      data_link.errors.count.should == 1
    end

    it "should be invalid if sourcable and targetable are the same" do
      data_link = @deployment.data_links.first
      data_link.sourcable = data_link.targetable
      data_link.should_not be_valid
      data_link.should have(1).error_on(:sourcable)
      data_link.errors.count.should == 1
    end

    it "should return correct string for best_in_place" do
      data_link = @deployment.data_links.first
      data_link.sourcable_type_id.should  == "#{data_link.sourcable_type}:#{data_link.sourcable_id}"
      data_link.targetable_type_id.should == "#{data_link.targetable_type}:#{data_link.targetable_id}"
    end
  end

  it "should be deep cloned" do
    cloud_provider = CloudProvider.make!
    cloud = Cloud.make!(:name => 'TestCloud', :cloud_provider => cloud_provider)
    data_link = DataLink.make(:user => user)
    deployment = Deployment.make!(:user => user)
    data_link.deployment = deployment
    # Create first server
    server1 = Server.make(:user => user)
    server1.deployment = deployment
    server1.server_type = ServerType.make!
    server1.cloud = cloud
    server1.save
    # Create second server
    server2 = Server.make(:user => user)
    server2.deployment = deployment
    server2.server_type = ServerType.make!
    server2.cloud = cloud
    server2.save

    data_link.sourcable = server1
    data_link.targetable = server2
    data_link.save

    new_data_link = data_link.deep_clone
    new_data_link.should be_valid
    new_data_link.name.should            == "Copy of #{data_link.name}"
    new_data_link.user.should            == data_link.user
    new_data_link.deployment.should      == data_link.deployment
    new_data_link.sourcable.should      == data_link.sourcable
    new_data_link.targetable.should      == data_link.targetable
  end

end