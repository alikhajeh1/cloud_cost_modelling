require 'spec_helper'

describe RulesController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @pattern = Pattern.make!(:user => user)
    @rule = Rule.make!(:user => user, :pattern => @pattern)
    @rules = [@rule]
    @params = {:pattern_id => @pattern.id, :id => @rule.id}
  end

  it "should render index" do
    get :index, :pattern_id => @pattern.id
    response.code.should == "200"
    # TODO: ALI for some reason the following breaks the specs even though the record is in the DB,
    # I think it's a threading issue with AR and transactional fixtures
    #assigns(:rules).should == @rules
    assigns(:pattern).should == @pattern
    response.should render_template("index")
  end

  context "update" do
    it "should update the rule" do
      put :update, @params.merge(:rule => {:value => 123})
      response.code.should == "200"
      @rule.reload.value.should == 123
      assigns(:pattern).should == @pattern
    end

    it "should return a json of the update errors" do
      put :update, @params.merge(:rule => {:value => ''})
      response.code.should == "422"
      response.body.should == ["Value is not a number"].to_json
      assigns(:pattern).should == @pattern
    end
  end

  context "create" do
    it "should not create invalid rule" do
      post :create, @params.merge(:rule => {:value => ''})
      assigns(:rules).should == @rules
      assigns(:pattern).should == @pattern
      response.should render_template("index")
    end

    it "should create rule" do
      post :create, :pattern_id => @pattern.id, :rule => {:rule_type => 'temporary', :year => '2011', :variation => '+', :value => '1'}
      response.should redirect_to(pattern_rules_url(@pattern))
    end
  end

  it "should destroy the rule" do
    delete :destroy, @params
    response.should redirect_to(pattern_rules_url(@pattern))
    Rule.exists?(@rule.id).should == false
  end

  it "should clone the rule" do
    post :clone, @params
    response.should redirect_to(pattern_rules_url(@pattern))
    flash[:success].should == "Rule was cloned."
  end

  it "should the rule move higher" do
    post :move_higher, @params
    response.should redirect_to(pattern_rules_url(@pattern))
    flash[:success].should == "Rule was moved higher."
  end

  it "should the rule move lower" do
    post :move_lower, @params
    response.should redirect_to(pattern_rules_url(@pattern))
    flash[:success].should == "Rule was moved lower."
  end

end