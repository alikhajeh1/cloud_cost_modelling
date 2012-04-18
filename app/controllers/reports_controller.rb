class ReportsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_report, :only => [:update, :destroy, :regenerate]
  before_filter :check_reportable_type, :only => [:new, :create]

  def index
    @reports = current_user.reports.page(params[:page]).order('completed_at DESC')
  end

  def show
    load_report_with_html
    redirect_to reports_url, :flash => {:warning => 'Report is either still being processed or has failed and cannot be viewed.'} unless @report.status == 'Completed'
  end

  def print
    load_report_with_html
    if @report.status == 'Completed'
      render :show
    else
      redirect_to reports_url, :flash => {:warning => 'Report is still being processed, it can only be printed once completed.'}
    end
  end

  def update
    # Hack to allow users to update the report dates with best_in_place, YUCK!
    start_date = params[:report].delete(:display_start_date)
    end_date = params[:report].delete(:display_end_date)
    if start_date || end_date
      if @report.updatable?
        if start_date
          if start_date =~ /\A\d{4}-\d{2}\z/
            params[:report][:start_date] = start_date + '-01'
          else
            render :json => ["Report date format must be YYYY-MM"], :status => :unprocessable_entity
            return
          end
        end
        if end_date
          if end_date =~ /\A\d{4}-\d{2}\z/
            params[:report][:end_date] = end_date + '-01'
          else
            render :json => ["Report date format must be YYYY-MM"], :status => :unprocessable_entity
            return
          end
        end
      else
        render :json => ["Report dates cannot be updated as the report is still being processed."], :status => :unprocessable_entity
        return
      end
    end
    # End of hack

    if @report.update_attributes(params[:report])
      head :ok
    else
      render :json => @report.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def new
    @report = current_user.reports.new
    if params[:report][:reportable_id]
      reportable = get_reportable
      # Regenerate the report if it one already exists
      if reportable.report
        @report = reportable.report
        regenerate
        return
      end

      @report.reportable = reportable
    else
      @report.reportable_type = params[:report][:reportable_type]
    end
    load_reportables
  end

  def create
    # Hack to allow users to set year-month dates for the report
    params[:report][:start_date] = params[:report][:start_date] + '-01' if params[:report][:start_date]
    params[:report][:end_date] = params[:report][:end_date] + '-01' if params[:report][:end_date]
    @report = current_user.reports.new(params[:report])

    reportable = get_reportable
    if reportable.report
      redirect_to reports_url, :flash => {:error => 'A report already exists for that source, you can regenerate it if needed.'}
      return
    end

    @report.reportable = reportable
    if @report.save
      Delayed::Job.enqueue(Reports::Job.new(@report))
      redirect_to reports_url, :flash => {:success => 'Report is being created, this should only take a minute...'}
    else
      load_reportables
      render :new
    end
  end

  def destroy
    if @report.destroy
      redirect_to reports_url, :flash => {:success => 'Report was deleted.'}
    else
      redirect_to reports_url, :flash => {:warning => 'Report is still being processed, it can only be deleted once completed.'}
    end
  end

  def regenerate
    if @report.updatable?
      Delayed::Job.enqueue(Reports::Job.new(@report))
      redirect_to reports_url, :flash => {:success => 'Report is being regenerated, this should only take a minute...'}
    else
      redirect_to reports_url, :flash => {:warning => 'Report is still being processed, it can only be regenerated once completed.'}
    end
  end

  private
  def load_report
    @report = current_user.reports.find(params[:id])
  end

  def check_reportable_type
    raise AppExceptions::InvalidParameter.new("Reports can only be created from user models.") unless
        Report::USER_REPORTABLE_MODELS.include?(params[:report][:reportable_type])
  end

  def load_reportables
    @reportables = params[:report][:reportable_type].constantize.where('user_id = ?', current_user.id).order(:name)
  end

  def get_reportable
    reportable = params[:report][:reportable_type].constantize.where(
        'id = ? AND user_id = ?', params[:report][:reportable_id], current_user.id).first
    raise ActiveRecord::RecordNotFound unless reportable
    reportable
  end

  def load_report_with_html
    @report = current_user.reports.find(params[:id], :select => :html)
  end
end