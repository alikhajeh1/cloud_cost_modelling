class InfoMailer < ActionMailer::Base
  default :from => "test@test"

  # InfoMailer.user_email.deliver
  def user_email
    @users = User.order(:id)
    mail(:to => "test@test", :subject => "Weekly User Report")
  end
end