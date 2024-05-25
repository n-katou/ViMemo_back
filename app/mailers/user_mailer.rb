class UserMailer < ApplicationMailer
  def reset_password_email(user,url)
    @user = user
    @url = url
    mail(to: user.email, subject: 'パスワードリセットの案内')
  end
end
