module Api
  module V1
    class ApiController < ActionController::API
      before_action :authenticate_user!


      protected

      def authenticate_user!
        token = request.headers['Authorization'].to_s.split(' ').last
        decoded_token = decode_jwt(token)
        @current_user = User.find_by(auth_token: decoded_token[:auth_token])
        
        unless @current_user
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end

      def decode_jwt(token)
        # 以下のJWT.decodeは仮のメソッドです。使用するライブラリによって変更してください。
        JWT.decode(token, nil, false)[0]
      end

      def current_user
        @current_user
      end
      
    end
  end
end
