require 'spec_helper'

describe RemoteNode do
  let(:user) { User.make! }

  it "should be invalid without a name, deployment and user" do
    remote_node = RemoteNode.new()
    remote_node.should have(1).error_on(:name)
    remote_node.should have(1).error_on(:user_id)
    remote_node.should have(1).error_on(:deployment_id)
    remote_node.errors.count.should == 3
    remote_node.should_not be_valid
  end
end