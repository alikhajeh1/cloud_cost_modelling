class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_user_time_zone
  layout 'application'

  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception, :with => :render_error
  end

  # Rails 3 needs a hack for 404 errors to be displayed, see last route
  def render_404()
    logger.error("\n\n404 error for #{params[:url]}")
    render :template => "/errors/404.html.erb", :status => 404
  end

  private
  def set_user_time_zone
    Time.zone = current_user.timezone if user_signed_in?
  end

  def render_error(exception)
    logger.error("\n\n#{exception.class.to_s} (#{exception.message.to_s}):\n#{exception.backtrace}")
    notify_airbrake(exception)
    render :template => "/errors/500.html.erb", :status => 500
  end
end