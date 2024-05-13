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
          token = generate_jwt(@user.id)  
          decoded_token = decode_jwt(token) # トークン生成のメソッド、適宜実装が必要
          Rails.logger.info "Generated Token: #{token}"
          render json: { success: true, token: token, user: @user.slice(:id, :email, :name) }, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def auth_create
        user = User.find_by(email: user_params[:email])
      
        if user
          if user.valid_password?(user_params[:password])
            token = generate_jwt(user.id)  # JWTを生成
            Rails.logger.info "Generated Token: #{token}"
            render json: { success: true, token: token, user: user.slice(:id, :email, :name) }, status: :ok
          else
            render json: { error: "パスワードが間違っています" }, status: :unprocessable_entity
          end
        else
          user = User.new(user_params)
          if user.save
            token = generate_jwt(user.id)  # JWTを生成
            render json: { success: true, token: token, user: user.slice(:id, :email, :name) }, status: :ok
          else
            render json: { error: user.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      def show
        render json: current_user.as_json(only: [:id, :email, :name]), status: :ok
      end

      private

      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      end

    end
  end
end
