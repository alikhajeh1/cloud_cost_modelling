require 'spec_helper'

describe PatternMap do
  let(:user) { User.make! }

  before(:all) do
    @patterns = 3.times.collect{ Pattern.make!(:user => user) }
  end

  context "add patterns in order" do
    it "should update the pattern_map with the correct position when patterns are added and removed" do
      server = given_resources_for([:server])[:server]
      server.remove_all_patterns('instance_hour_monthly_baseline')
      server.add_patterns('instance_hour_monthly_baseline', @patterns)
      server.get_patterns('instance_hour_monthly_baseline').count.should == 3
      server.pattern_maps.last.position.should == 3

      server.add_patterns('quantity_monthly_baseline', @patterns)
      server.get_patterns('quantity_monthly_baseline').count.should == 3
      server.pattern_maps.last.position.should == 3

      server.remove_patterns('instance_hour_monthly_baseline', [@patterns.first])
      server.pattern_maps.where("patternable_attribute = 'instance_hour_monthly_baseline'").last.position.should == 2
    end
  end

  it "should throw an exception if a pattern is added to a non-existent or a non-numeric attribute" do
    deployment = given_resources_for([:deployment])[:deployment]
    expect{ deployment.applications.first.add_patterns('non_existent_attr', [])}.should raise_error
    expect{ deployment.applications.first.add_patterns('name', [])}.should raise_error
  end

  it "should return all patterns ordered correctly" do
    server = given_resources_for([:server], :user => user)[:server]
    server.remove_all_patterns('instance_hour_monthly_baseline')
    server.add_patterns('instance_hour_monthly_baseline', @patterns[0..1])
    patterns_hash = server.get_all_patterns_ordered('instance_hour_monthly_baseline')

    patterns_hash[:selected_patterns_count].should == 2
    patterns_hash[:all_patterns][0].should == @patterns[0]
    patterns_hash[:all_patterns][1].should == @patterns[1]
    patterns_hash[:all_patterns][2].should == @patterns[2]
  end

end