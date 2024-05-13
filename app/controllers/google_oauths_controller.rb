class GoogleOauthsController < ApplicationController
  include JwtHandler
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token, only: [:callback]  # CSRF検証をcallbackのみスキップ

  def oauth
    client_id = ENV['GOOGLE_CLIENT_ID']
    redirect_uri = ENV['GOOGLE_REDIRECT_URI_BACKEND']
    scope = "email profile"
    state = SecureRandom.hex(16)

    oauth_url = "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=#{client_id}&redirect_uri=#{CGI.escape(redirect_uri)}&scope=#{CGI.escape(scope)}&state=#{state}&access_type=offline&prompt=consent"

    if request.headers['Frontend-Request'] == 'true'
      render json: { oauthUrl: oauth_url }, status: :ok
    else
      redirect_to oauth_url, allow_other_host: true
    end
  end
  
  #フロントエンド用
  def callback
    reset_session
    is_frontend = request.headers['Frontend-Request'] == 'true'
  
    if logged_in?
      render json: { message: 'You are already logged in.' }, status: :ok
      return
    end
    if params[:code].present?
      service = GoogleOauthService.new(params[:code], params[:code_verifier], is_frontend)
      @user = service.authenticate
    end

    if @user && @user.persisted?
      session[:user_id] = @user.id
      session_id = request.session_options[:id]
      token = generate_jwt(@user.id)  # JWTトークン生成
      decoded_token = decode_jwt(token)  # トークンをデコード
      Rails.logger.info "Decoded JWT: #{decoded_token}"
      Rails.logger.info "Session after login: #{session.to_hash.inspect}, session ID: #{session_id}"
      # ここでフロントエンドのURLにリダイレクト
      redirect_url = "https://vimemo.vercel.app/mypage?session_id=#{token}"
      # redirect_url = "http://localhost:4000/mypage?session_id=#{token}"
      redirect_to redirect_url, allow_other_host: true
    else
      error_message = @user.errors.full_messages.join(", ") if @user
      Rails.logger.error("Login process failed: #{error_message || 'Authentication failed'}")
      render json: {
        status: 'error',
        message: error_message || 'Authentication failed'
      }, status: :unauthorized
    end
  end

  # バックエンド用
  # def callback
  #   reset_session
  #   is_frontend = request.headers['Frontend-Request'] == 'true'
  
  #   if logged_in?
  #     redirect_to root_path, notice: 'You are already logged in.'
  #     return
  #   end
  #   # GoogleOAuthServiceを使用するフローと、JSONデータによるユーザー認証を組み合わせる
  #   if params[:code].present?
  #     service = GoogleOauthService.new(params[:code], params[:code_verifier], is_frontend)
  #     @user = service.authenticate
  #   else
  #     # パラメータから直接ユーザーデータを取得し、ユーザーを探すまたは作成
  #     user_data = params.fetch(:user, {}).permit(:email, :name, :id, :image)
  #     access_token = params[:accessToken]
  #     refresh_token = params[:refreshToken]
  #     @user = User.find_or_create_by(email: user_data[:email]) do |u|
  #       u.name = user_data[:name]
  #       u.password = SecureRandom.hex(10)  # 安全なランダムパスワードを生成
  #       u.password_confirmation = u.password
  #     end
  #   end
  #   respond_to do |format|
  #     if @user && @user.persisted?
  #       session[:user_id] = @user.id
  #       session_id = request.session_options[:id]
  #       Rails.logger.info "Session after login: #{session.to_hash.inspect}, session ID: #{session_id}"
  #       redirect_url = is_frontend ? "http://localhost:4000?session_id=#{session_id}" : users_mypage_path
  #       format.html { redirect_to redirect_url, notice: t('auth.login_success') }
  #       format.json { render json: { status: 'success', message: 'Logged in successfully', user: { email: @user.email, name: @user.name } } }
  #     else
  #       error_message = @user ? @user.errors.full_messages.join(", ") : "Authentication failed"
  #       Rails.logger.error("Login process failed: #{error_message}")
  #       format.html { redirect_to login_path, alert: error_message }
  #       format.json { render json: { status: 'error', message: error_message }, status: :unauthorized }
  #     end
  #   end
  # end
end
