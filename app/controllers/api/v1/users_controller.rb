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

  private

  def create_user(auth)
    if auth.nil? || auth[:uid].nil? || auth[:email].nil?
      Rails.logger.error "Invalid authentication data: #{auth.inspect}"
      render json: { error: 'Invalid authentication data' }, status: :unprocessable_entity
      return
    end
  
    uid = auth[:uid]
    email = auth[:email]
    Rails.logger.debug "Creating user with UID: #{uid} and Email: #{email}"
  
    user = User.find_or_initialize_by(uid: uid)
    user.email = email if user.new_record?
  
    if user.valid?
      user.save
      Rails.logger.info "User saved successfully: #{user.inspect}"
      render json: { message: '登録しました', user: user.as_json }, status: :created
    else
      Rails.logger.error "Validation failed: #{user.errors.full_messages}"
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def set_auth
    @auth = authenticate_token
    Rails.logger.debug "Auth set with: #{@auth}"
  end
end
