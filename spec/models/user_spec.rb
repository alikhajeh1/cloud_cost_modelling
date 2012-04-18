require 'spec_helper'

describe User do
  let(:user) { User.make! }

  context "Spam-bot protection" do
    it "should create new user when no spam-protection triggered (i.e. a user is created from rails console)" do
      u = User.make
      u.comment = nil
      u.homepage = nil
      u.save.should == true
    end

    it "should not create new user when honeypot is filled" do
      u = User.make
      u.comment = 'abc'
      u.save.should == false
      u.should have(1).errors_on(:comment)
      u.errors.count.should == 1
    end

    it "should not create new user when form was filled too quickly" do
      u = User.make
      u.homepage = Time.now
      u.save.should == false
      u.should have(1).errors_on(:homepage)
      u.errors.count.should == 1
    end

    it "should not create new user when timestamp is invalid" do
      u = User.make
      u.homepage = 'abc'
      u.save.should == false
      u.should have(1).errors_on(:homepage)
      u.errors.count.should == 1
    end

    it "should create new user when user took more than 5 seconds to fill form" do
      u = User.make
      u.homepage = (Time.now - 5.seconds).to_s
      u.save.should == true
    end
  end

  context "Currency" do
    it "should allow a change to a valid currency" do
      user.currency = 'GBP'
      user.save.should == true
      user.errors.count.should == 0
      user.should be_valid
    end

    it "should not allow a currency not accepted by Google Currency" do
      user.currency = 'IRR'
      user.save.should == false
      user.should have(1).errors_on(:currency)
      user.errors.count.should == 1
      user.should_not be_valid
    end

    it "should not allow an invalid currency" do
      user.currency = 'AAA'
      user.save.should == false
      user.should have(1).errors_on(:currency)
      user.errors.count.should == 1
      user.should_not be_valid
    end
  end

  context "initialize new users" do
    before(:each) do
      @user = User.make
      @user.sign_in_count = 1
      @user.current_sign_in_at = Time.now
      @user.save!
    end

    it "should not initialize new users twice" do
      @user.current_sign_in_at = Time.now - 10.seconds
      @user.save
      @user.initialize_new_user
      @user.deployments.count.should == 0

      @user.sign_in_count = 2
      @user.save
      @user.initialize_new_user
      @user.deployments.count.should == 0
    end
  end
end
