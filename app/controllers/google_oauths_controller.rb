class GoogleOauthsController < ApplicationController
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

  def callback
    reset_session
    is_frontend = request.headers['Frontend-Request'] == 'true'
  
    if logged_in?
      redirect_to root_path, notice: 'You are already logged in.'
      return
    end
  
    service = GoogleOauthService.new(params[:code], params[:code_verifier], is_frontend)
    @user = service.authenticate
  
    respond_to do |format|
      if @user && @user.persisted?
        session[:user_id] = @user.id
        session_id = request.session_options[:id]
        redirect_url = is_frontend ? "http://localhost:4000?session_id=#{session_id}" : users_mypage_path
        format.html { redirect_to redirect_url, notice: 'Logged in successfully.' }
      else
        error_message = @user ? @user.errors.full_messages.join(", ") : "Authentication failed"
        Rails.logger.error("Login process failed: #{error_message}")
        format.html { redirect_to login_path, alert: error_message }
        format.json { render json: { status: 'error', message: error_message }, status: :unauthorized }
      end
    end
  end
end
