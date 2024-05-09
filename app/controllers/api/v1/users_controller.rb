class Api::V1::UsersController < ApplicationController
  include FirebaseAuthConcern
  skip_before_action :verify_authenticity_token
  before_action :set_auth, only: %i[create]
  skip_before_action :require_login

  def create
    create_user(@auth)
  end

  private

  def create_user(auth)
    render json: auth, status: :unauthorized and return unless auth[:data]
    uid = auth[:data][:uid]
    render json: { message: '登録済みです' } and return if User.find_by(uid: uid)

    user = User.new(uid: uid)
    if user.save
      render json: { message: '登録しましました' }
    else
      render json: user.errors.messages, status: :unprocessable_entity
    end
  end

  def set_auth
    @auth = authenticate_token
  end
end
