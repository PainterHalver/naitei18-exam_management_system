class Supervisor::TestsController < Supervisor::SupervisorController
  before_action ->{load_user_by_id params[:user_id]}

  def index
    @query = @user.tests.newest.includes(:subject).ransack params[:q]
    @pagy, @tests = pagy @query.result,
                         items: Settings.digit.length_10
  end
end
