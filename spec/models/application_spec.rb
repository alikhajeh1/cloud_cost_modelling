require 'spec_helper'

describe Application do
  let(:user) { User.make! }

  it "should be invalid without a name, user, server and deployment" do
    application = Application.new()
    application.should have(1).error_on(:name)
    application.should have(1).error_on(:user_id)
    application.should have(1).error_on(:deployment_id)
    application.errors.count.should == 3
    application.should_not be_valid
  end

  context "clone" do
    it "should be deep cloned, including all of its associations" do
      application = given_resources_for([:application])[:application]
      new_application = application.deep_clone
      Application.last.should               == new_application
      new_application.name.should           == "Copy of #{application.name}"
      new_application.deployment.should     == application.deployment
      new_application.server.should         == application.server
      new_application.patterns.count.should == application.patterns.count
      new_application.should be_valid
    end

    it "should be deep cloned with a new name" do
      application = Application.make(:user => user)
      new_application = application.deep_clone(:name => 'application2')
      new_application.name.should == "application2"
    end
  end

  it "should be invalid when server belongs to another deployment" do
    application = given_resources_for([:application])[:application]
    application2 = given_resources_for([:application])[:application]

    application.server = application2.server
    application.should have(1).error_on(:server)
    application.errors.count.should == 1
    application.should_not be_valid
  end

end