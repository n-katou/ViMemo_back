class Api::V1::UsersController < ApplicationController
  include FirebaseAuthConcern
  skip_before_action :verify_authenticity_token
  before_action :set_auth, only: %i[create]
  skip_before_action :require_login

  def create
    Rails.logger.debug "Received auth: #{@auth}"
    if @auth.nil? || @auth[:error]
      Rails.logger.error "Authentication failed with: #{@auth[:error]}"
      render json: { error: 'Authentication failed' }, status: :unauthorized
    else
      create_user(@auth)
    end
  end

  def verify_token
    id_token = params[:idToken]
    begin
      # Firebase Admin SDKの設定
      firebase_project_id = "vimemo-63237"
      validator = Google::Auth::IDTokens::Validator.new
      claims = validator.check id_token, firebase_project_id
      # ユーザー情報の取得
      user_email = claims['email']
      # 以降、ユーザー情報をもとに自身のデータベースのユーザーと照合または登録
      @user = User.find_or_create_by(email: user_email)
      render json: { status: 'success', user: @user.as_json }
    rescue Google::Auth::IDTokens::ValidationError => e
      render json: { status: 'error', message: 'Invalid token' }, status: :unauthorized
    end
  end

  private

  def create_user(auth)
    if auth[:uid].nil? || auth[:email].nil?
      Rails.logger.error "Invalid authentication data: #{auth.inspect}"
      render json: { error: 'Invalid authentication data' }, status: :unprocessable_entity
      return
    end
    
    user = User.find_or_create_by_uid(auth)
    
    if user.persisted?
      Rails.logger.info "User created or found: #{user.inspect}"
      render json: { message: '登録しました', user: user.as_json }, status: :created
    else
      Rails.logger.error "User validation failed: #{user.errors.full_messages}"
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def set_auth
    @auth = authenticate_token
    Rails.logger.debug "Auth set with: #{@auth}"
  end
end
