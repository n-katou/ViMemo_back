module Api
  module V1
    class ApiController < ActionController::API
      include JwtHandler
      before_action :authenticate_user!


      protected
      def authenticate_user!
        token = request.headers['Authorization']&.split(' ')&.last
        Rails.logger.debug "Authorization header token: #{token}" # デバッグメッセージを追加
        decoded_token = decode_jwt(token)
        Rails.logger.debug "Decoded token: #{decoded_token}" # デバッグメッセージを追加
        if decoded_token.present?
          @current_user = User.find_by(id: decoded_token[:user_id])
          Rails.logger.debug "Authenticated current_user: #{@current_user.inspect}" # デバッグメッセージを追加
          render json: { error: 'User not found' }, status: :not_found unless @current_user
        else
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end
    
      def current_user
        @current_user
      end
    end
  end
end
