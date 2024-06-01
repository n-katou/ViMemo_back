module Api
  module V1
    # APIの基本コントローラークラス
    class ApiController < ActionController::API
      # JWTハンドラーをインクルード
      include JwtHandler

      # すべてのアクションの前にユーザー認証を実行
      before_action :authenticate_user!

      protected

      # ユーザー認証メソッド
      def authenticate_user!
        # リクエストヘッダーからJWTトークンを取得
        token = request.headers['Authorization']&.split(' ')&.last
        # トークンをデコード
        decoded_token = decode_jwt(token)
        if decoded_token.present?
          # トークンからユーザーIDを取得し、ユーザーを検索
          @current_user = User.find_by(id: decoded_token[:user_id])
          # ユーザーが見つからない場合、404エラーを返す
          render json: { error: 'User not found' }, status: :not_found unless @current_user
        else
          # トークンが無効または存在しない場合、401エラーを返す
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end
    
      # 現在のユーザーを返すメソッド
      def current_user
        @current_user
      end
    end
  end
end
