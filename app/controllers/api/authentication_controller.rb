class Api::AuthenticationController < ApplicationController
  require 'google-id-token'
  skip_before_action :verify_authenticity_token, :require_login

  def authenticate
    token = params[:token]
    if token.blank?
      Rails.logger.error "Authentication attempt without token"
      return render json: { error: 'No token provided' }, status: :bad_request
    end

    begin
      validator = GoogleIDToken::Validator.new
      aud = ENV["GOOGLE_CLIENT_ID"] # ここを環境変数から取得するように変更
      payload = validator.check(token, aud, aud)
      if payload
        session[:user_id] = payload['sub'] 
        Rails.logger.info "Session ID: #{request.session.id}"
        Rails.logger.info "Authentication successful for user_id: #{payload['sub']}"
        render json: { success: true, user_id: payload['sub'] }
      else
        Rails.logger.error "Invalid token received"
        render json: { error: 'Invalid token' }, status: :unauthorized
      end
    rescue GoogleIDToken::ValidationError => error
      Rails.logger.error "Google ID Token validation error: #{error.message}"
      render json: { error: error.message }, status: :unauthorized
    rescue => e
      Rails.logger.error "Unexpected error during authentication: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end
end
