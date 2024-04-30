class Api::V1::SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    token = params[:token]  # Next.jsから送られてくるトークン
    user = authenticate_user_from_token(token)

    if user
      reset_session
      auto_login(user)
      render json: { success: true, user_id: user.id }
    else
      render json: { success: false }, status: :unauthorized
    end
  end

  private

  def authenticate_user_from_token(token)
    # トークンを検証し、ユーザーを見つけるロジック
    # 例: JWTをデコードする、Google APIを使ってトークンの有効性を確認する、など
  end
end
