class StaticPagesController < ApplicationController
  def home
    if logged_in?
      @tests = current_user.tests.includes(:subject)
    else
      flash[:info] = t ".login_message" unless flash.keys.include? "info"
      redirect_to signup_path
    end
  end
end
