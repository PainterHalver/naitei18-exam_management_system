class StaticPagesController < ApplicationController
  def home
    flash.now[:info] = t ".login_message"
  end
end
