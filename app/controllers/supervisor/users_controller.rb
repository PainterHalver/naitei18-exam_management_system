class Supervisor::UsersController < Supervisor::SupervisorController
  before_action :load_user_by_id, only: %i(activate deactivate)
  def index
    @query = User.newest.ransack params[:q]
    @pagy, @users = pagy @query.result,
                         items: Settings.digit.length_10
  end

  def activate
    if @user.activate
      flash[:success] = t "account_activation.activated"
    else
      flash[:danger] = t "account_activation.failed"
    end
    redirect_to supervisor_users_path
  end

  def deactivate
    if @user.deactivate
      flash[:success] = t "account_activation.deactivated"
    else
      flash[:danger] = t "account_activation.deactivation_failed"
    end
    redirect_to supervisor_users_path
  end
end
