class StaticPagesController < ApplicationController
  def home
    if logged_in?
      redirect_to supervisor_root_path if is_supervisor?
      @pagy, @tests = pagy(current_user.tests.newest.includes(:subject),
                           items: Settings.pagination.per_page_10)
    else
      flash[:info] = t ".login_message" unless flash.keys.include? "info"
      redirect_to signup_path
    end
  end
end
