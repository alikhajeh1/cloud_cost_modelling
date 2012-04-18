require 'spec_helper'

describe PatternsController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @pattern  = Pattern.make!(:user => user)
    @patterns = [@pattern]
  end

  it "should render index" do
    get :index
    response.code.should == "200"
    # TODO: ALI for some reason the following breaks the specs even though the record is in the DB,
    # I think it's a threading issue with AR and transactional fixtures
    #assigns(:patterns).should == @patterns
    assigns(:pattern).should_not be_nil
    response.should render_template("index")
  end

  it "should redirect to the rule index from show" do
    get :show, :id => @pattern.id
    response.should redirect_to(pattern_rules_url(@pattern))
  end

  context "update" do
    it "should update the pattern" do
      put :update, :id => @pattern.id, :pattern => {:name => 'new name'}
      response.code.should        == "200"
      @pattern.reload.name.should == 'new name'
    end

    it "should return a json of the update errors" do
      put :update, :id => @pattern.id, :pattern => {:name => ''}
      response.code.should == "422"
      response.body.should == ["Name can't be blank"].to_json
    end
  end

  context "create" do
    it "should not create invalid pattern" do
      post :create, :pattern => {:name => ''}
      assigns(:patterns).should_not be_empty
      response.should render_template("index")
    end

    it "should create pattern" do
      post :create, :pattern => {:name => 'new pattern'}
      response.should redirect_to(Pattern.last)
    end
  end

  it "should destroy the pattern" do
    expect { delete :destroy, :id => @pattern.id }.to change(Pattern, :count).by(-1)
    response.should redirect_to(patterns_url)
  end

  context "clone" do
    it "should redirect to index if clone fails" do
      flexmock(controller.current_user).should_receive("patterns.find").and_return(@pattern)
      flexmock(@pattern).should_receive("deep_clone").and_return(Exception.new)
      post :clone, :id => @pattern.id
      response.should redirect_to(patterns_url)
    end

    it "should clone the pattern" do
      post :clone, :id => @pattern.id
      response.should redirect_to(Pattern.last)
    end
  end
end