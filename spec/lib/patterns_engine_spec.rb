require 'spec_helper'

describe PatternsEngine do
  context "no patterns" do
    it "should return an array of zeros when baseline is 0" do
      results = PatternsEngine.get_monthly_results(0, [], Time.now,
                                                   Time.now + 1.year)
      results.should == Array.new(13){0}
    end

    it "should return an array of 2s when baseline is 2" do
      results = PatternsEngine.get_monthly_results(2, [], Time.now,
                                                   Time.now + 1.year)
      results.should == Array.new(13){2}
    end
  end

  context "patterns engine" do
    before(:each) do
      @pattern = Pattern.make!
      @rule = Rule.new(:rule_type => 'Permanent', :year => 'every.1.years', :month => 'every.1.months',
                        :variation => '+', :value => 2)
      @rule.pattern = @pattern
      @rule.save!

      @params = [100, [@pattern], Time.now, Time.now + 3.months]
    end

    context "rule_type" do
      it "should add 2 every month for a permanent rule" do
        results = PatternsEngine.get_monthly_results(*@params)
        results.should == [102.0, 104.0, 106.0, 108.0]
      end

      it "should add 2 every month for a temporary rule" do
        @rule.update_attributes(:rule_type => 'Temporary')
        results = PatternsEngine.get_monthly_results(*@params)
        results.should == [102.0, 102.0, 102.0, 102.0]
      end
    end

    context "variation" do
      it "should subtract 2 every month for a permanent pattern" do
        @rule.update_attributes(:variation => '-')
        results = PatternsEngine.get_monthly_results(*@params)
        results.should == [98.0, 96.0, 94.0, 92.0]
      end

      it "should multiply by 2 every month for a permanent pattern" do
        @rule.update_attributes(:variation => '*')
        results = PatternsEngine.get_monthly_results(*@params)
        results.should == [200.0, 400.0, 800.0, 1600.0]
      end

      it "should divide by 2 every month for a permanent pattern" do
        @rule.update_attributes(:variation => '/')
        results = PatternsEngine.get_monthly_results(*@params)
        results.should == [50.0, 25.0, 12.5, 6.25]
      end

      it "should raise to the power of 2 every month for a permanent pattern" do
        @rule.update_attributes(:variation => '^')
        results = PatternsEngine.get_monthly_results(*@params)
        results.should == [10000.0, 100000000.0, 10000000000000000.0, 100000000000000000000000000000000.0]
      end

      it "should set the value to 2 every month for a permanent pattern" do
        @rule.update_attributes(:variation => '=')
        results = PatternsEngine.get_monthly_results(*@params)
        results.should == [2.0, 2.0, 2.0, 2.0]
      end
    end
  end

  context "applicable rules" do
    before(:each) do
      @value = 2.0
      @pattern = Pattern.make!
      @rule = Rule.new(:rule_type => 'Temporary', :year => 'every.1.years', :variation => '+', :value => @value)
      @rule.pattern = @pattern
      @rule.save!

      @monthly_baseline = 0
      @start_date = Time.new(2012, 01)
      @end_date = (@start_date + 6.years)
    end

    it "should apply rules for every.1.years" do
      @rule.update_attributes!(:year => 'every.1.years')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(6*12+1){|i| i % 12 == 0 ? @value : 0.0}
    end

    it "should apply rules for every.3.years" do
      @rule.update_attributes!(:year => 'every.3.years')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(6*12+1){|i| i % 36 == 0 ? @value : 0.0}
    end

    it "should apply rules for every.1.years, every.3.months" do
      @rule.update_attributes!(:year => 'every.1.years', :month => 'every.3.months')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(6*12+1){|i| i % 3 == 0 ? @value : 0.0}
    end

    it "should apply rules for every.3.years, every.1.months" do
      @rule.update_attributes!(:year => 'every.3.years', :month => 'every.1.months')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(12){@value} + Array.new(2*12){0.0} + Array.new(12){@value} + Array.new(2*12){0.0} + [@value]
    end

    it "should apply rules for year.1" do
      @rule.update_attributes!(:year => 'year.1')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == [@value] + Array.new(6*12){0.0}
    end

    it "should apply rules for year.2" do
      @rule.update_attributes!(:year => 'year.2')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(12){0.0} + [@value] + Array.new(5*12){0.0}
    end

    it "should apply rules for year.3" do
      @rule.update_attributes!(:year => 'year.3')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(2*12){0.0} + [@value] + Array.new(4*12){0.0}
    end

    it "should apply rules for year.1, jun" do
      @rule.update_attributes!(:year => 'year.1', :month => 'jun')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(5){0.0} + [@value] + Array.new(6*12-5){0.0}
    end

    it "should apply rules for year.2, jun" do
      @rule.update_attributes!(:year => 'year.2', :month => 'jun')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(12+5){0.0} + [@value] + Array.new(5*12-5){0.0}
    end

    it "should apply rules for year.1-year.4" do
        @rule.update_attributes!(:year => 'year.1-year.4')
        results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
        results.should == [@value] + Array.new(11){0.0} +
                          [@value] + Array.new(11){0.0} +
                          [@value] + Array.new(11){0.0} +
                          [@value] + Array.new(3*12){0.0}
    end

    it "should apply rules for year.2-year.4" do
        @rule.update_attributes!(:year => 'year.2-year.4')
        results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
        results.should == Array.new(12){0.0} + [@value] + Array.new(11){0.0} +
                                               [@value] + Array.new(11){0.0} +
                                               [@value] + Array.new(3*12){0.0}
    end

    it "should apply rules for year.1-year.4, jun-aug" do
      @rule.update_attributes!(:year => 'year.1-year.4', :month => 'jun-aug')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(5){0.0} + Array.new(3){@value} + Array.new(9){0.0} +
                                            Array.new(3){@value} + Array.new(9){0.0} +
                                            Array.new(3){@value} + Array.new(9){0.0} +
                                            Array.new(3){@value} + Array.new(9+20){0.0}
    end

    it "should apply rules for year.2-year.4, jun-aug" do
      @rule.update_attributes!(:year => 'year.2-year.4', :month => 'jun-aug')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(12+5){0.0} + Array.new(3){@value} + Array.new(9){0.0} +
                                               Array.new(3){@value} + Array.new(9){0.0} +
                                               Array.new(3){@value} + Array.new(9+20){0.0}
    end

    it "should apply rules for 2014" do
      @rule.update_attributes!(:year => '2014')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(2*12){0.0} + [@value] + Array.new(4*12){0.0}
    end

    it "should apply rules for 2014, jun" do
      @rule.update_attributes!(:year => '2014', :month => 'jun')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(2*12+5){0.0} + [@value] + Array.new(4*12-5){0.0}
    end

    it "should apply rules for 2014-2016" do
      @rule.update_attributes!(:year => '2014-2016')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(2*12){0.0} + [@value] + Array.new(11){0.0} +
                                               [@value] + Array.new(11){0.0} +
                                               [@value] + Array.new(2*12){0.0}
    end

    it "should apply rules for 2014-2016, jun" do
      @rule.update_attributes!(:year => '2014-2016', :month => 'jun')
      results = PatternsEngine.get_monthly_results(@monthly_baseline, [@pattern], @start_date, @end_date)
      results.should == Array.new(2*12+5){0.0} + [@value] + Array.new(11){0.0} +
                                               [@value] + Array.new(11){0.0} +
                                               [@value] + Array.new(2*12-5){0.0}
    end

  end

  context "complex patterns" do
    it "should be able to deal with leap years" do
      pattern1 = Pattern.make!
      rule = Rule.new(:rule_type => 'Temporary', :year => 'every.1.years', :variation => '+', :value => 10)
      rule.pattern = pattern1
      rule.save!

      start_date = Time.new(2012, 02, 01)
      end_date = Time.new(2012, 04, 01)

      results = PatternsEngine.get_monthly_results(0, [pattern1], start_date, end_date)
      results.should == [10.0, 0.0, 0.0]
    end

    it "should apply overlapping rules" do
      pattern1 = Pattern.make!
      rule = Rule.new(:rule_type => 'Permanent', :year => 'every.1.years', :month => 'every.1.months',
                      :variation => '+', :value => 1)
      rule.pattern = pattern1
      rule.save!

      pattern2 = Pattern.make!
      rule = Rule.new(:rule_type => 'Temporary', :year => 'every.1.years', :month => 'apr-sep',
                      :variation => '*', :value => 2)
      rule.pattern = pattern2
      rule.save!

      start_date = Time.new(2012, 01)
      end_date = (start_date + 11.months)

      results = PatternsEngine.get_monthly_results(9, [pattern1, pattern2], start_date, end_date)
      results.should == [10.0, 11.0, 12.0] + Array.new(6){|i| (12 + i + 1) * 2.0} + [19.0, 20.0, 21.0]

      results = PatternsEngine.get_monthly_results(9, [pattern2, pattern1], start_date, end_date)
      results.should == [10.0, 11.0, 12.0, 25.0, 51.0, 103.0, 207.0, 415.0, 831.0, 832.0, 833.0, 834.0]
    end
  end
end