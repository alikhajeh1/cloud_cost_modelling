require 'spec_helper'

describe Report do
  let(:user) { User.make! }

  before(:each) do
    @report = given_resources_for([:report])[:report]
  end

  it "should be invalid without a user, name, reportable_id, reportable_type, start_date and end_date" do
    report = Report.new()
    report.should have(1).error_on(:user_id)
    report.should have(1).error_on(:name)
    report.should have(1).error_on(:reportable_type)
    report.should have(1).error_on(:reportable_id)
    report.should have(1).error_on(:start_date)
    report.should have(1).error_on(:end_date)
    report.errors.count.should == 6
    report.should_not be_valid
  end

  context "report date range" do
    it "should be invalid if the report start_date is before Jan-2012" do
      @report.start_date = '2011-12-01'
      @report.end_date = '2012-01-01'
      @report.save.should == false
      @report.should have(1).error_on(:start_date)
      @report.errors.count.should == 1
      @report.should_not be_valid
    end

    it "should be invalid if the report period is less than 2 months" do
      @report.start_date = Time.now
      @report.end_date = Time.now
      @report.save.should == false
      @report.should have(1).error_on(:end_date)
      @report.errors.count.should == 1
      @report.should_not be_valid
    end

    it "should be valid if the report period is more than 1 month" do
      @report.start_date = Time.now
      @report.end_date = Time.now + 1.month
      @report.save.should == true
      @report.should be_valid
    end

    it "should be invalid if the report period is more than 10 years" do
      @report.start_date = Time.now
      @report.end_date = Time.now + 12.years
      @report.save.should == false
      @report.should have(1).error_on(:end_date)
      @report.errors.count.should == 1
      @report.should_not be_valid
    end

    it "should be valid if the report period is less than 10 years" do
      @report.start_date = Time.now
      @report.end_date = Time.now + 10.years
      @report.save.should == true
      @report.should be_valid
    end
  end

  context "destroy" do
    it "should not be destroyed if it has just been created (and not queued yet)" do
      @report.destroy.should == false
    end

    it "should not be destroyed if it is pending" do
      @report.status = 'Pending'
      @report.save
      @report.destroy.should == false
    end

    it "should not be destroyed if it is processing" do
      @report.status = 'Processing'
      @report.save
      @report.destroy.should == false
    end

    it "should be destroyed if it completed" do
      @report.status = 'Completed'
      @report.save
      @report.destroy.should_not == false
    end

    it "should be destroyed if it failed" do
      @report.status = 'Failed'
      @report.save
      @report.destroy.should_not == false
    end
  end

  context "default scope" do
    it "should not include xml by default" do
      Report.last.has_attribute?(:xml).should == false
      Report.last.has_attribute?(:html).should == false
    end

    it "should include xml when required" do
      Report.last(:select => :html).has_attribute?(:html).should == true
    end

  end
end