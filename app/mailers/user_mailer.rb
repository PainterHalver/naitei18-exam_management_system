class UserMailer < ApplicationMailer
  def account_activation user
    @user = user
    mail to: user.email, subject: t("mail.account_activation")
  end

  def reset_password user
    @user = user
    mail to: user.email, subject: t("mail.reset_password")
  end
end
