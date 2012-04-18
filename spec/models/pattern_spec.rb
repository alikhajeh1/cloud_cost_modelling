require 'spec_helper'

describe Pattern do
  let(:user) { User.make! }

  before(:each) do
    @pattern = given_resources_for([:pattern])[:pattern]
  end

  it "should be invalid without a name" do
    pattern = Pattern.new()
    pattern.should have(1).error_on(:name)
    pattern.errors.count.should == 1
    pattern.should_not be_valid
  end

  context "clone" do
    it "should be deep cloned, including all of its associations" do
      new_pattern = @pattern.deep_clone

      new_pattern.should be_valid
      new_pattern.name.should        == "Copy of #{@pattern.name}"
      Pattern.last.should            == new_pattern
      new_pattern.rules.count.should == @pattern.rules.count
      new_pattern.user.should        == @pattern.user
    end

    it "should be deep cloned with a new name" do
      new_pattern = @pattern.deep_clone(:name => 'pattern2')
      new_pattern.name.should == "pattern2"
      new_pattern.should be_valid
    end
  end
end