require 'spec_helper'

describe Cloud do

  context "Currency" do
    before(:all) do
      @cloud = given_resources_for([:cloud])[:cloud]
    end

    it "should allow a change to a valid currency" do
      @cloud.billing_currency     = 'GBP'
      @cloud.save.should          == true
      @cloud.errors.count.should  == 0
      @cloud.should be_valid
    end

    it "should not allow a currency not accepted by Google Currency" do
      @cloud.billing_currency     = 'IRR'
      @cloud.save.should          == false
      @cloud.should have(1).errors_on(:billing_currency)
      @cloud.errors.count.should  == 1
      @cloud.should_not be_valid
    end

    it "should not allow an invalid currency" do
      @cloud.billing_currency     = 'AAA'
      @cloud.save.should          == false
      @cloud.should have(1).errors_on(:billing_currency)
      @cloud.errors.count.should  == 1
      @cloud.should_not be_valid
    end
  end
end
