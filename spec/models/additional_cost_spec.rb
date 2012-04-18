require 'spec_helper'

describe AdditionalCost do
  let(:user) { User.make! }

  it "should be invalid without a user and a name" do
    additional_cost = AdditionalCost.new()
    additional_cost.should have(1).error_on(:name)
    additional_cost.should have(1).error_on(:user_id)
    additional_cost.errors.count.should == 2
    additional_cost.should_not be_valid
  end

  context "clone" do
    it "should be deep cloned, including all of its associations (deployments and patterns)" do
      additional_cost = AdditionalCost.make!(:user => user)
      additional_cost.deployments << Deployment.make!(:user => user)
      additional_cost.add_patterns('cost_monthly_baseline', [Pattern.make!(:user => user)])
      additional_cost.add_patterns('cost_monthly_baseline', [Pattern.make!(:user => user)])
      new_additional_cost = additional_cost.deep_clone

      new_additional_cost.should be_valid
      new_additional_cost.name.should                     == "Copy of #{additional_cost.name}"
      new_additional_cost.user.should                     == additional_cost.user
      AdditionalCost.last.should                          == new_additional_cost
      new_additional_cost.deployments.count.should        == additional_cost.deployments.count
      new_additional_cost.patterns.count.should           == additional_cost.patterns.count
    end

    it "should be deep cloned with a new name" do
      additional_cost = AdditionalCost.make!(:user => user)
      new_additional_cost = additional_cost.deep_clone(:name => 'AdditionalCostTwo')
      new_additional_cost.name.should == "AdditionalCostTwo"
      new_additional_cost.should be_valid
    end
  end

end