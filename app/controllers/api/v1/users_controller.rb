require 'jwt'
require 'net/http'
require 'openssl'

module Api
  module V1
    class UsersController < ApiController
      include JwtHandler  # JWT処理のモジュールをインクルード
      skip_before_action :authenticate_user!, only: [:create, :auth_create]

      def create
        @user = User.new(user_params)
        if @user.save
          render json: { message: I18n.t('users.create.success'), user: @user }, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def auth_create
        user = User.find_by(email: user_params[:email])
      
        if user
          if user.valid_password?(user_params[:password])
            token = generate_jwt(user.id)  # JWTを生成
            render json: { message: "ログイン成功", token: token }, status: :ok
          else
            render json: { error: "パスワードが間違っています" }, status: :unprocessable_entity
          end
        else
          user = User.new(user_params)
          if user.save
            token = generate_jwt(user.id)  # JWTを生成
            render json: { message: "登録成功", token: token }, status: :created
          else
            render json: { error: user.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      def logout
        if current_user.update(auth_token: nil)  # 現在のユーザーのauth_tokenをクリア
          render json: { message: "Logged out successfully." }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      end
    end
  end
end
