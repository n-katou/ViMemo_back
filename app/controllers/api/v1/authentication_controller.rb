require 'net/http'
require 'json'
require 'jwt'

class Api::AuthenticationController < ApplicationController
  before_action :authenticate_request
  skip_before_action :verify_authenticity_token
  skip_before_action :require_login

  def userdata
    user = User.find_by(email: params[:email])
    if user
      render json: { status: 'success', data: user.as_json(only: [:id, :name, :email]) }, status: :ok
    else
      render json: { status: 'error', message: 'User not found' }, status: :not_found
    end
  end

  private

  def authenticate_request
    token = request.headers['Authorization']&.split(' ')&.last
    if token
      begin
        jwks_json = fetch_google_public_keys
        jwks_keys = JSON.parse(jwks_json)['keys']
        jwk_loader = ->(options) { jwks_keys.find { |k| k['kid'] == options[:kid] } }
  
        decoded_token = JWT.decode(token, nil, true, algorithm: 'RS256', jwks: jwk_loader).first
        if valid_token?(decoded_token)
          @current_user = User.find_by(email: decoded_token['email'])
          return true
        end
      rescue JWT::DecodeError => e
        Rails.logger.error "Token decode error: #{e.message}"
        render json: { error: 'Token is invalid' }, status: :unauthorized
        return
      end
    end
    render json: { error: 'No token provided' }, status: :unauthorized
  end
  
  def fetch_google_public_keys
    uri = URI('https://www.googleapis.com/oauth2/v3/certs')
    response = Net::HTTP.get(uri)
    JSON.parse(response)['keys']
  end
  
  def valid_token?(decoded_token)
    # ここでトークンのクレーム（発行者、有効期限など）の検証を行う
    decoded_token['iss'] == 'https://securetoken.google.com/vimemo-63237' &&
    decoded_token['aud'] == 'vimemo-63237' &&
    Time.now < Time.at(decoded_token['exp'].to_i)
  end
end
