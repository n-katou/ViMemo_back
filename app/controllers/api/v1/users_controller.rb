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
    if auth.nil?
      render json: { error: 'Invalid authentication data' }, status: :unprocessable_entity
      return
    end
  
    uid = auth[:uid]
    email = auth[:email]  # email を直接参照する
    user = User.find_by(uid: uid)
  
    if user
      render json: { message: '登録済みです' }, status: :ok
    else
      user = User.new(uid: uid, email: email)  # User オブジェクトの生成時に email も設定
      if user.save
        render json: { message: '登録しました' }, status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def set_auth
    @auth = authenticate_token
    Rails.logger.debug "Auth set with: #{@auth}"
  end
end
