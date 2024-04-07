class GoogleOauthsController < ApplicationController
  skip_before_action :require_login

  def oauth
    client_id = ENV['GOOGLE_CLIENT_ID']
    redirect_uri = "https://vimemoback.fly.dev/oauth/callback?provider=google"
    scope = "email profile"
    state = "SOME_STATE_VALUE"

    oauth_url = "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=#{client_id}&redirect_uri=#{CGI.escape(redirect_uri)}&scope=#{CGI.escape(scope)}&state=#{state}&access_type=offline&prompt=consent"
    redirect_to oauth_url, allow_other_host: true
  end

  def callback
    service = GoogleOauthService.new(params[:code])
    @user = service.authenticate

    if @user
      reset_session
      auto_login(@user)
      redirect_to root_path, notice: "ログインしました！"
    else
      redirect_to root_path, alert: "ログインに失敗しました！"
    end
  rescue => e
    Rails.logger.error { "ログイン処理中にエラーが発生しました: #{e.message}" }
    redirect_to root_path, alert: "ログインに失敗しました！"
  end
end
