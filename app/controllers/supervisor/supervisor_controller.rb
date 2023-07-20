class Supervisor::SupervisorController < ApplicationController
  before_action :require_login, :require_supervisor_role

  private

  def require_supervisor_role
    return if current_user.is_supervisor?

    flash[:danger] = t "no_permission"
    redirect_to root_path
  end
end
