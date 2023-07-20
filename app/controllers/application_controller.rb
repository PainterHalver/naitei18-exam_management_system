class ApplicationController < ActionController::Base
  include Pagy::Backend
  include SessionsHelper
  around_action :switch_locale

  private
  def switch_locale &action
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    {locale: I18n.locale}
  end

  def require_login
    return if logged_in?

    flash[:danger] = t "require_login"
    redirect_to login_path
  end
end
