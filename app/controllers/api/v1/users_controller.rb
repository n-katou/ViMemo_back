require 'jwt'
require 'net/http'

module Api
  module V1
    class UsersController < ApiController

      def create
        token = params[:firebase_token]
        decoded_token = decode_firebase_token(token)

        if decoded_token.nil?
          render json: { error: 'Invalid token' }, status: :unauthorized
          return
        end

        user_data = decoded_token[:claims]  # IDトークンのクレーム部分にユーザー情報が含まれています。
        @user = User.find_or_create_by_uid(user_data)

        if @user.persisted?
          render json: { token: @user.auth_token, user: @user }, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
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

      def decode_firebase_token(token)
        jwks_uri = URI("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com")
        jwks_raw = Net::HTTP.get(jwks_uri)
        jwks_keys = Array(JSON.parse(jwks_raw)['keys'])
        decoded_token = nil

        jwks_keys.each do |key|
          next unless key['kid'] == decoded_token.header['kid']

          public_key = OpenSSL::X509::Certificate.new(Base64.decode64(key['x5c'].first)).public_key
          decoded_token = JWT.decode(token, public_key, true, { algorithm: 'RS256', verify_iat: true })
          break
        rescue JWT::VerificationError, JWT::DecodeError => e
          Rails.logger.error "Token verification failed: #{e.message}"
          return nil
        end

        decoded_token
      end
    end
  end
end
