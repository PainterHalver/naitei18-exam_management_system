module SessionsHelper
  def log_in user
    session[:user_id] = user.id
  end

  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find_by id: user_id if user_id
  end

  def current_user? user
    user && user == current_user
  end

  def logged_in?
    current_user.present?
  end

  def log_out
    session.delete :user_id
    @current_user = nil
  end

  def is_supervisor?
    current_user&.is_supervisor?
  end
end
