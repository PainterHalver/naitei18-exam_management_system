class StaticPagesController < ApplicationController
  def home
    flash.now[:info] = t ".login_message"
    @user = User.new
    render "users/new"
  end
end
