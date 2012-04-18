require 'spec_helper'

describe Storage do
  let(:user) { User.make! }

  it "should be invalid without a name, user, deployment, storage type and cloud" do
    storage = Storage.new()
    storage.should have(1).error_on(:name)
    storage.should have(1).error_on(:user_id)
    storage.should have(1).error_on(:deployment_id)
    storage.should have(1).error_on(:storage_type_id)
    storage.should have(1).error_on(:cloud_id)
    storage.errors.count.should == 5
    storage.should_not be_valid
  end

  it "should be deep cloned" do
    cloud_provider = CloudProvider.make!
    cloud = Cloud.make!(:name => 'TestCloud', :cloud_provider => cloud_provider)
    storage = Storage.make(:user => user)
    storage.deployment = Deployment.make!(:user => user)
    storage.storage_type = StorageType.make!
    storage.cloud = cloud
    storage.add_patterns('storage_size_monthly_baseline', [Pattern.make!(:user => user)])
    storage.add_patterns('read_request_monthly_baseline', [Pattern.make!(:user => user)])
    storage.add_patterns('write_request_monthly_baseline', [Pattern.make!(:user => user)])
    storage.add_patterns('quantity_monthly_baseline', [Pattern.make!(:user => user)])
    storage.save
    new_storage = storage.deep_clone

    new_storage.should be_valid
    new_storage.name.should            == "Copy of #{storage.name}"
    new_storage.user.should            == storage.user
    new_storage.deployment.should      == storage.deployment
    new_storage.patterns.count.should  == storage.patterns.count
  end

end