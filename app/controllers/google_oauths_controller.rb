class GoogleOauthsController < ApplicationController
  skip_before_action :require_login
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

  def callback
    Rails.logger.info "Received params: #{params.inspect}"

    # GoogleOAuthServiceを使用するフローと、JSONデータによるユーザー認証を組み合わせる
    if params[:code].present?
      # Google認証コードがある場合、GoogleOauthServiceを使用
      service = GoogleOauthService.new(params[:code], params[:code_verifier])
      @user = service.authenticate
    else
      # パラメータから直接ユーザーデータを取得し、ユーザーを探すまたは作成
      user_data = params.fetch(:user, {}).permit(:email, :name, :id, :image)
      access_token = params[:accessToken]
      refresh_token = params[:refreshToken]

      @user = User.find_or_create_by(email: user_data[:email]) do |u|
        u.name = user_data[:name]
        u.password = SecureRandom.hex(10)  # 安全なランダムパスワードを生成
        u.password_confirmation = u.password
      end
    end

    # ユーザーの認証処理の結果に応じて応答
    respond_to do |format|
      if @user&.persisted?
        reset_session
        auto_login(@user)
        Rails.logger.info "Login successful for user: #{@user.email}"
        format.html { redirect_to root_path, notice: t('auth.login_success') }
        format.json { render json: { status: 'success', message: 'Logged in successfully', user: { email: @user.email, name: @user.name } } }
      else
        # エラーメッセージの取得
        error_message = @user&.errors&.full_messages&.join(", ") || service&.error_message || "Unknown error occurred"
        Rails.logger.error("Login process failed: #{error_message}")
        format.html { redirect_to login_path, alert: t('auth.login_failed') }
        format.json { render json: { status: 'error', message: error_message }, status: :unauthorized }
      end
    end
  end
end
