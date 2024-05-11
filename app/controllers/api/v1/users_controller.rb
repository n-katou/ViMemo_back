require 'jwt'
require 'net/http'
require 'openssl'

module Api
  module V1
    class UsersController < ApiController
      def create
        user = User.find_by(email: user_params[:email])
    
        if user
          render json: { error: 'User already exists with this email address.' }, status: :unprocessable_entity
        else
          user = User.new(user_params)
          if user.save
            render json: user, status: :created
          else
            render json: user.errors, status: :unprocessable_entity
          end
        end
      end

      private

      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      end

      def decode_unverified(token)
        JWT.decode(token, nil, false) # 第三引数にfalseを指定して検証をスキップ
      end

      def fetch_public_key(kid)
        jwks_uri = URI("https://www.googleapis.com/oauth2/v3/certs")
        jwks_raw = Net::HTTP.get(jwks_uri)
        jwks_keys = JSON.parse(jwks_raw)['keys']
        jwk = jwks_keys.find { |key| key['kid'] == kid }

        if jwk.nil?
          raise 'Public key not found.'
        end

        OpenSSL::X509::Certificate.new(Base64.decode64(jwk['x5c'].first)).public_key
      end
    end
  end
end
