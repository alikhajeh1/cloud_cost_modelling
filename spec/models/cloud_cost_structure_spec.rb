require 'spec_helper'

describe CloudCostStructure do

  it "should be invalid without a name" do
    cloud_cost_structure = CloudCostStructure.new()
    cloud_cost_structure.should have(1).error_on(:name)
    cloud_cost_structure.should have(1).error_on(:units)
    cloud_cost_structure.errors.count.should == 2
    cloud_cost_structure.should_not be_valid
  end

  context "tier_prices_string method" do
    before(:each) do
      @cloud_cost_structure = CloudCostStructure.create!(:name => 'storage_size', :units => 'per.1.gbs.per.1.months')
    end

    it "should return the price on a single tier" do
      tier = CloudCostTier.new(:cost => 0.13)
      tier.cloud_cost_structure = @cloud_cost_structure
      tier.save!

      @cloud_cost_structure.tier_prices_string().should == "0.13"
    end

    it "should return a string of prices for all tiers" do
      tier = CloudCostTier.new(:upto => 11, :cost => 0.12)
      tier.cloud_cost_structure = @cloud_cost_structure
      tier.save!
      tier = CloudCostTier.new(:upto => 101, :cost => 0.10)
      tier.cloud_cost_structure = @cloud_cost_structure
      tier.save!
      tier = CloudCostTier.new(:cost => 0.08)
      tier.cloud_cost_structure = @cloud_cost_structure
      tier.save!

      @cloud_cost_structure.tier_prices_string('T').should == "From 0T up to 11T: 0.12, up to 101T: 0.1, and above: 0.08"
    end
  end

end