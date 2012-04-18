require 'spec_helper'

describe PatternMapsController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @patternable = given_resources_for([:application], :user => user)[:application]
    3.times { Pattern.make!(:user => user) }
  end

  context 'multi_update' do
    before(:each) do
      # Setup HTTP_REFERER since the controller redirects back and if this is not set then it won't work
      request.env['HTTP_REFERER'] = deployment_applications_path(@patternable.deployment, @patternable)
      @params = {:pattern_map => {
          :patternable_type => @patternable.class.to_s,
          :patternable_id => @patternable.id,
          :patternable_attribute => 'instance_hour_monthly_baseline'}}
    end

    it "should multi_update the patterns map when patterns are attached" do
      new_params = @params
      new_params[:pattern_map][:pattern] = [user.patterns[2].id.to_s, user.patterns[1].id.to_s]
      put :multi_update, new_params

      patterns = @patternable.get_patterns('instance_hour_monthly_baseline')
      patterns.count.should == 2
      patterns[0].should == user.patterns[2]
      patterns[1].should == user.patterns[1]
      response.should redirect_to(deployment_applications_path(@patternable.deployment, @patternable))
    end

    it "should remove all patterns when none are attached" do
      put :multi_update, @params

      @patternable.get_patterns('instance_hour_monthly_baseline').should be_empty
      response.should redirect_to(deployment_applications_path(@patternable.deployment, @patternable))
    end

    it "should throw exception when a pattern is attached to non-user model" do
      expect{ put :multi_update, :pattern_map => {:patternable_type => "CloudProvider"}}.should raise_error
    end
  end


end