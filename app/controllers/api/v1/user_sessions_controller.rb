module Api
  module V1
    class UserSessionsController < ApplicationController
      include JwtHandler
      skip_before_action :require_login, only: [:create, :destroy]
      skip_before_action :verify_authenticity_token
      layout false 
      # ユーザーログイン処理
      def create
        user = login(params[:email], params[:password])
        if user
          session[:user_id] = user.id
          token = generate_jwt(user.id)  # JWTトークン生成
          decoded_token = decode_jwt(token)  # トークンをデコード
          Rails.logger.info "Decoded JWT: #{decoded_token}"  # ログ出力
          render json: {
            success: true,
            message: 'ログインに成功しました。',
            user: user.as_json(only: [:id, :email, :name, :auth_token]),
            token: token
          }, status: :ok
        else
          render json: { success: false, error: 'ログインに失敗しました。メールアドレスまたはパスワードが間違っています。' }, status: :unauthorized
        end
      end

      # ユーザーログアウト処理
      def destroy
        if current_user.update(auth_token: nil)  # 現在のユーザーのauth_tokenをクリア
          render json: { message: "Logged out successfully." }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
