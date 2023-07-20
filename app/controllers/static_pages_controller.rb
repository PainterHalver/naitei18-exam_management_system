class StaticPagesController < ApplicationController
  def home
    return if logged_in?

    flash.now[:info] = t ".login_message" unless flash.keys.include? "info"
    @user = User.new
    render "users/new"
  end
end
