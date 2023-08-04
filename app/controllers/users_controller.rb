class UsersController < ApplicationController
  before_action ->{load_user_by_id params[:id]}, :require_login,
                except: [:new, :create]
  before_action :correct_user, only: [:edit, :update]
  before_action :profile_accessible?, only: [:show]

  def new
    @user = User.new
  end

  def create
    @user = User.new user_params
    if @user.save
      flash[:info] = t "signup.wait_for_activation"
      redirect_to login_path
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
      redirect_to @user
    else
      render :edit
    end
  end

  def show
    @tests = @user.tests.includes(:subject)
    @subjects_data = @tests.joins(:subject).group(:name).count
  end

  private

  def correct_user
    return if current_user?(@user)

    flash[:danger] = t "users.edit.user_invalid"
    redirect_to root_url
  end

  def user_params
    params.require(:user)
          .permit :name, :email, :password, :password_confirmation
  end

  def profile_accessible?
    return if current_user?(@user) || current_user.is_supervisor?

    flash[:danger] = t "users.profile.invalid"
    redirect_to root_url
  end
end
