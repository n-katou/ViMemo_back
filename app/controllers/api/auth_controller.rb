module Api
  class AuthController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      user = User.find_by(email: params[:email])
      if user && validate_google_token(params[:token], user)
        render json: { status: "success", user: user }
      else
        render json: { status: "error", message: "Authentication failed" }, status: :unauthorized
      end
    end

    private

    def validate_google_token(token, user)
      # ここにGoogleトークン検証ロジックを実装
      # GoogleのAPIを使用してトークンの有効性を検証する例
      url = "https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=#{token}"
      response = HTTParty.get(url)
      if response.ok? && response.parsed_response['email'] == user.email
        true
      else
        false
      end
    end
  end
end
