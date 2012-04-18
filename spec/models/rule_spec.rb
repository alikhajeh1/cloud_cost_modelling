require 'spec_helper'

describe Rule do
  let(:user) { User.make! }

  before(:all) do
    @pattern = Pattern.make!(:user => user)
  end

  context "invalid rules" do
    it "should be invalid without a pattern, year, variation and value" do
      rule = Rule.new()
      rule.should have(1).error_on(:pattern_id)
      rule.should have(1).error_on(:rule_type)
      rule.should have(1).error_on(:year)
      rule.should have(1).error_on(:variation)
      rule.should have(1).error_on(:value)
      rule.errors.count.should == 5
      rule.should_not be_valid
    end

    it "should reject invalid values" do
      rule_params = {:rule_type => 'temporary', :year => '2015', :variation =>'+'}

      rule = @pattern.rules.create(rule_params.merge(:value => '-1'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:value => 'abc'))
      rule.should_not be_valid
    end

    it "should reject rules with invalid ranges or single values" do
      rule_params = {:rule_type => 'temporary', :variation =>'+', :value => '1'}

      rule = @pattern.rules.create(rule_params.merge(:year => 'every.0.years'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => 'year.0'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => 'year.2-year.0'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => 'year.0-year.2'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => 'year.5-year.1'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => '1800'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => '2010-2009'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => '2010-2009'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => '2010', :month => 'dec-dec'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => '2010', :month => 'dec-mar'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => '2010', :day => '32'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => '2010', :day => '10-9'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => '2010', :hour => '24'))
      rule.should_not be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => '2010', :hour => '2-1'))
      rule.should_not be_valid
    end
  end

  context "valid rules" do
    it "should allow valid rule_types" do
      rule_params = {:year => '2015', :variation =>'+', :value => '1'}

      rule = @pattern.rules.create(rule_params.merge(:rule_type => 'temporary'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:rule_type => 'permanent'))
      rule.should be_valid
    end

    it "should allow valid years" do
      rule_params = {:rule_type => 'temporary', :variation =>'+', :value => '1'}

      rule = @pattern.rules.create(rule_params.merge(:year => 'every.1.year'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => 'every.2.years'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => 'year.1'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => 'year.4'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => 'year.4-year.6'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => 'year.1-year.4'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => '2015'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:year => '2015-2020'))
      rule.should be_valid
    end

    it "should allow valid months" do
      rule_params = {:rule_type => 'temporary', :year => '2015', :variation =>'+', :value => '1'}

      rule = @pattern.rules.create(rule_params.merge(:month => 'every.1.month'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:month => 'every.2.months'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:month => 'jun'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:month => 'jun-sep'))
      rule.should be_valid
    end

    it "should allow valid days" do
      rule_params = {:rule_type => 'temporary', :year => '2015', :variation =>'+', :value => '1'}

      rule = @pattern.rules.create(rule_params.merge(:day => 'every.1.day'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:day => 'every.2.days'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:day => 'every.mon'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:day => 'every.mon-thu'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:day => '15'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:day => '15-20'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:day => 'last.fri'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:day => 'last.sat-sun'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:day => 'first.mon'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:day => 'first.sat-sun'))
      rule.should be_valid
    end

    it "should allow valid hours" do
      rule_params = {:rule_type => 'temporary', :year => '2015', :variation =>'+', :value => '1'}

      rule = @pattern.rules.create(rule_params.merge(:hour => 'every.1.hour'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:hour => 'every.2.hours'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:hour => '20'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:hour => '9-17'))
      rule.should be_valid
    end

    it "should allow valid variations" do
      rule_params = {:rule_type => 'temporary', :year => '2015', :value => '1'}

      rule = @pattern.rules.create(rule_params.merge(:variation => '+'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:variation => '-'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:variation => '*'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:variation => '/'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:variation => '^'))
      rule.should be_valid

      rule = @pattern.rules.create(rule_params.merge(:variation => '='))
      rule.should be_valid
    end
  end

  it "should be deep cloned" do
    rule = user.rules.create(:rule_type => 'temporary', :year => '2015', :variation =>'+', :value => '1')
    rule.pattern = @pattern
    rule.should be_valid

    new_rule = rule.deep_clone
    new_rule.user.should      == rule.user
    new_rule.pattern.should   == rule.pattern
    new_rule.rule_type.should == 'temporary'
    new_rule.year.should      == '2015'
    new_rule.variation.should == '+'
    new_rule.value.should     == 1
  end

end