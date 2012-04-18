class HomeController < ApplicationController

  def index
    flash.keep
    if user_signed_in?
      redirect_to user_root_url
    else
      redirect_to new_user_session_url
    end
  end

end