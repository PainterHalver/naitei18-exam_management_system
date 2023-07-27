class Supervisor::UsersController < Supervisor::SupervisorController
  def index
    @query = User.newest.ransack params[:q]
    @pagy, @users = pagy @query.result,
                         items: Settings.digit.length_10
  end
end
