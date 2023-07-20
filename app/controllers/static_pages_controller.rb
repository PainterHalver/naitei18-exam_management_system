class StaticPagesController < ApplicationController
  def home
    flash.now[:info] = t ".login_message" unless flash.keys.include? "info"
    @user = User.new
    render "users/new"
  end
end
