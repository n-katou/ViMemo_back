module Api
  module V1
    class ApiController < ActionController::API
      include JwtHandler
      # before_action :authenticate_user!


      protected

      # def authenticate_user!
      #   token = request.headers['Authorization']&.split(' ')&.last
      #   if token.present?
      #     decoded_token = decode_jwt(token)
      #     @current_user = User.find(decoded_token[:user_id])
      #   else
      #     render json: { error: 'Unauthorized' }, status: :unauthorized
      #   end
      # end

      # # def decode_jwt(token)
      # #   # 以下のJWT.decodeは仮のメソッドです。使用するライブラリによって変更してください。
      # #   JWT.decode(token, nil, false)[0]
      # # end

      # def current_user
      #   @current_user
      # end
      
    end
  end
end
