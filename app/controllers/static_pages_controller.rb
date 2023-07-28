class StaticPagesController < ApplicationController
  def home
    if logged_in?
      @pagy, @tests = pagy(current_user.tests.includes(:subject),
                           items: Settings.pagination.per_page_10)
    else
      flash[:info] = t ".login_message" unless flash.keys.include? "info"
      redirect_to signup_path
    end
  end
end
