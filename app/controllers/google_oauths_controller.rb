class GoogleOauthsController < ApplicationController
  # skip_before_action :require_login
  skip_before_action :require_login, only: [:callback]
  skip_before_action :verify_authenticity_token, only: [:callback]  # CSRF検証をcallbackのみスキップ

  def oauth
    client_id = ENV['GOOGLE_CLIENT_ID']
    redirect_uri = "https://vimemo.fly.dev/oauth/callback?provider=google"
    # redirect_uri = "http://localhost:3000/oauth/callback?provider=google"
    scope = "email profile"
    state = "SOME_STATE_VALUE"

    oauth_url = "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=#{client_id}&redirect_uri=#{CGI.escape(redirect_uri)}&scope=#{CGI.escape(scope)}&state=#{state}&access_type=offline&prompt=consent"
    redirect_to oauth_url, allow_other_host: true
  end
  
  # def callback
  #   Rails.logger.info "Received params: #{params.inspect}"
  #   service = GoogleOauthService.new(params[:code], params[:code_verifier])
  #   @user = service.authenticate
  
  #   respond_to do |format|
  #     if @user
  #       reset_session
  #       auto_login(@user)
  #       format.html { redirect_to root_path, notice: t('auth.login_success') }
  #       format.json { render json: { status: 'success', message: 'Logged in successfully' } }
  #     else
  #       error_message = service.error_message || "未知のエラーが発生しました"
  #       Rails.logger.error("ログイン処理中にエラーが発生しました: #{error_message}")
  #       format.html { redirect_to login_path, alert: t('auth.login_failed') }
  #       format.json { render json: { status: 'error', message: error_message }, status: :unauthorized }
  #     end
  #   end

  def callback
    # 受け取ったJSONデータのログを記録
    Rails.logger.info "Received params: #{params.inspect}"

    # 受け取ったユーザーデータを処理
    user_data = params.require(:user).permit(:email, :name)
    access_token = params[:accessToken]
    refresh_token = params[:refreshToken]

    # ユーザーの検索または作成
    user = User.find_or_create_by(email: user_data[:email]) do |u|
      u.name = user_data[:name]
      u.password = SecureRandom.hex(10)  # 安全なランダムパスワードを生成
      u.password_confirmation = u.password
    end

    if user.persisted?
      # セッションリセットと自動ログイン
      reset_session
      auto_login(user)
      # 成功レスポンス
      respond_to do |format|
        format.html { redirect_to root_path, notice: t('auth.login_success') }
        format.json { render json: { status: 'success', message: 'Logged in successfully' } }
      end
    else
      # エラーメッセージの処理
      error_message = user.errors.full_messages.join(", ") || "未知のエラーが発生しました"
      Rails.logger.error("ログイン処理中にエラーが発生しました: #{error_message}")
      respond_to do |format|
        format.html { redirect_to login_path, alert: t('auth.login_failed') }
        format.json { render json: { status: 'error', message: error_message }, status: :unauthorized }
      end
    end
  end
end
