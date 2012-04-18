require 'spec_helper'

describe DatabaseResource do
  let(:user) { User.make! }

  it "should be invalid without a name, user, deployment, database and cloud" do
    database = DatabaseResource.new()
    database.should have(1).error_on(:name)
    database.should have(1).error_on(:user_id)
    database.should have(1).error_on(:deployment_id)
    database.should have(1).error_on(:database_type_id)
    database.should have(1).error_on(:cloud_id)
    database.errors.count.should == 5
    database.should_not be_valid
  end

  it "should be deep cloned" do
    cloud_provider = CloudProvider.make!
    cloud = Cloud.make!(:name => 'TestCloud', :cloud_provider => cloud_provider)
    database = DatabaseResource.make(:user => user)
    database.deployment = Deployment.make!(:user => user)
    database.database_type = DatabaseType.make!
    database.cloud = cloud
    database.add_patterns('storage_size_monthly_baseline', [Pattern.make!(:user => user)])
    database.add_patterns('instance_hour_monthly_baseline', [Pattern.make!(:user => user)])
    database.add_patterns('transaction_monthly_baseline', [Pattern.make!(:user => user)])
    database.add_patterns('quantity_monthly_baseline', [Pattern.make!(:user => user)])
    database.save
    new_database = database.deep_clone

    new_database.should be_valid
    new_database.name.should            == "Copy of #{database.name}"
    new_database.user.should            == database.user
    new_database.deployment.should      == database.deployment
    new_database.patterns.count.should  == database.patterns.count
  end

end