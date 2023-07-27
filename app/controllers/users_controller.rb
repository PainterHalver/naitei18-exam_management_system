class UsersController < ApplicationController
  before_action :load_user, :require_login, except: [:new, :create]
  before_action :correct_user, only: [:edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new user_params
    if @user.save
      @user.send_activation_email
      flash[:info] = t "signup.mail_check"
      redirect_to root_path
    else
      flash[:danger] = t "signup.signup_failed"
      render :new
    end
  end

  def edit; end

  def update
    if @user.update(user_params)
      # Handle a successful update.
      flash[:success] = t "users.edit.saved"
      # redirect_to @user
      redirect_to subjects_path
    else
      render :edit
    end
  end

  private

  def load_user
    @user = User.find_by id: params[:id]

    return if @user

    flash[:danger] = t "user.error"
    redirect_to login_path
  end

  def correct_user
    return if current_user?(@user)

    flash[:danger] = t "users.edit.user_invalid"
    redirect_to root_url
  end

  def user_params
    params.require(:user)
          .permit :name, :email, :password, :password_confirmation
  end
end
