require 'spec_helper'

describe ReportsController do
  render_views
  let(:user) { User.make! }

  before(:each) do
    sign_in user
    @deployment = given_resources_for([:deployment], :user => user)[:deployment]
    @report = Report.make!(:user => user, :reportable => @deployment)
    @reports = [@report]
  end

  it "should render index" do
    get :index
    response.code.should         == "200"
    assigns(:reports).should == @reports
    response.should render_template("index")
  end

  context "print" do
    it "should redirect back to reports page and give warning" do
      @report.status = 'Processing'
      @report.save
      get :print, :id => @report.id
      response.should redirect_to(reports_url)
      flash[:warning].should == 'Report is still being processed, it can only be printed once completed.'
    end

    it "should render show - print success" do
      @report.status = 'Completed'
      @report.html = '<HTML></HTML>'
      @report.save
      get :print, :id => @report.id
      response.should render_template("show")
    end
  end

  context "show" do
    it "should not render show for incomplete reports" do
       get :show, :id => @report.id
       response.should redirect_to(reports_url)
       flash[:warning].should == 'Report is either still being processed or has failed and cannot be viewed.'
    end

    it "should render show" do
      @report.status = "Completed"
      @report.html = "<div>report</div>"
      @report.save
      get :show, :id => @report.id
      assigns(:report).should_not be_nil
      response.should render_template("show")
    end
  end

  it "should update the report" do
    put :update, :id => @report.id, :report => {:name => 'new name'}
    response.code.should       == "200"
    @report.reload.name.should == 'new name'
  end

  it "should update the report" do
    put :update, :id => @report.id, :report => {:display_end_date => '2014-12'}
    response.code.should == "422"
    response.body.should == ['Report dates cannot be updated as the report is still being processed.'].to_json
  end

  context "invalid updates" do
    before(:each) do
      @report.status = "Completed"
      @report.save
    end

    it "should return a json of the update errors" do
      put :update, :id => @report.id, :report => {:name => ''}
      response.code.should == "422"
      response.body.should == ["Name can't be blank"].to_json
    end

    it "should return a json of the update errors (invalid start date)" do
      put :update, :id => @report.id, :report => {:display_start_date => 'abc'}
      response.code.should == "422"
      response.body.should == ["Report date format must be YYYY-MM"].to_json
    end

    it "should return a json of the update errors (too early start date)" do
      put :update, :id => @report.id, :report => {:display_start_date => '2010-10'}
      response.code.should == "422"
      response.body.should == ["Start date can't be earlier than 2012-01 as we don't have pricing details for earlier dates"].to_json
    end

    it "should return a json of the update errors (invalid end date)" do
      put :update, :id => @report.id, :report => {:display_end_date => 'abc'}
      response.code.should == "422"
      response.body.should == ["Report date format must be YYYY-MM"].to_json
    end

    it "should return a json of the update errors (too early end date)" do
      put :update, :id => @report.id, :report => {:display_end_date => '2010-10'}
      response.code.should == "422"
      response.body.should == ["End date must be after Sun, 01 Jan 2012 00:00:00 +0000"].to_json
    end

    it "should return a json of the update errors (start_date after end date)" do
      put :update, :id => @report.id, :report => {:display_start_date => '2013-02', :display_end_date => '2013-01'}
      response.code.should == "422"
      response.body.should == ["End date must be after Fri, 01 Feb 2013 00:00:00 +0000"].to_json
    end
  end

  it "should render new" do
    get :new, :report => {:reportable_type => 'Deployment'}
    assigns(:report).should_not be_nil
    assigns(:reportables).should_not be_nil
    response.should render_template("new")
  end

  context "create" do
    before(:each) do
      # Create a new deployment without any associated reports
      @deployment = given_resources_for([:deployment], :user => user)[:deployment]
      @deployment.applications.destroy_all
      @deployment.data_chunks.destroy_all
    end

    it "should not create invalid report" do
      post :create, :report => {:name => '', :reportable_type => 'Deployment', :reportable_id => @deployment.id}
      assigns(:report).should_not be_nil
      assigns(:reportables).should_not be_nil
      response.should render_template("new")
    end

    it "should create report" do
      expect { post :create, :report => {:name => 'new report', :start_date => '2012-01', :end_date => '2013-01',
                                :reportable_type => 'Deployment', :reportable_id => @deployment.id}
              }.to change(Report, :count).by(+1)
      Report.last.xslt_file.should_not be_nil
      response.should redirect_to(reports_url)
    end

    it "should warn that a report exists if it already exists" do
      @report.reportable = @deployment
      @report.save
      post :create, :report => {:reportable_type => 'Deployment', :reportable_id => @deployment.id}
      response.should redirect_to(reports_url)
      flash[:error].should == 'A report already exists for that source, you can regenerate it if needed.'
    end
  end

  context "destroy" do
    it "should not destroy in-progress reports" do
      delete :destroy, :id => @report.id
      response.should redirect_to(reports_url)
      Report.exists?(@report.id).should == true
    end

    it "should destroy report" do
      @report.status = 'Completed'
      @report.save
      delete :destroy, :id => @report.id
      response.should redirect_to(reports_url)
      Report.exists?(@report.id).should == false
    end
  end

  context "regenerate" do
    it "should not allow a regeneration of an in generation report" do
      @report.status = "Processing"
      @report.save
      get :regenerate, :id => @report.id
      response.should redirect_to(reports_url)
      flash[:warning].should == 'Report is still being processed, it can only be regenerated once completed.'
    end

    it "should regenerate the report" do
      @report.status = "Completed"
      @report.save
      get :regenerate, :id => @report.id
      response.should redirect_to(reports_url)
      flash[:success].should == 'Report is being regenerated, this should only take a minute...'
    end
  end
end