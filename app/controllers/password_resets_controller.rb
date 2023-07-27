class PasswordResetsController < ApplicationController
  before_action :load_user, :valid_user, :check_expiration,
                only: [:edit, :update]

  def new; end

  def create
    @user = User.find_by email: params.dig(:password_reset, :email)&.downcase
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = t "users.reset_password.begin"
      redirect_to login_path
    else
      flash.now[:danger] = t "users.errors.email_invalid"
      render :new
    end
  end

  def edit; end

  def update
    if params[:user][:password].empty?
      @user.errors.add :password, t("users.errors.password_empty")
      render :edit
    elsif @user.update(user_params)
      log_in @user
      flash[:success] = t "users.reset_password.success"
      redirect_to root_path
    else
      render :edit
    end
  end

  private

  def load_user
    @user = User.find_by email: params[:email]

    return if @user

    flash[:danger] = t "users.errors.not_found"
    redirect_to login_path
  end

  def check_expiration
    return unless @user.password_reset_expired?

    flash[:danger] = t "users.reset_password.expired"
    redirect_to new_password_reset_url
  end

  def valid_user
    return if @user.activated? && @user.authenticated?(:reset, params[:id])

    flash[:danger] = t "users.errors.user_invalid"
    redirect_to root_url
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
