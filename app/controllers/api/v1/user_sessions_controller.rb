module Api
  module V1
    class UserSessionsController < ApplicationController
      skip_before_action :require_login, only: [:create, :destroy]
      skip_before_action :verify_authenticity_token
      layout false 
      # ユーザーログイン処理
      def create
        user = login(params[:email], params[:password])
        if user
          session[:user_id] = user.id # セッションにユーザーIDを保存
          render json: {
            success: true,
            message: 'ログインに成功しました。',
            user: user.as_json(only: [:id, :email, :name]),
            token: form_authenticity_token # CSRFトークンまたはセッションIDを返す
          }, status: :ok
        else
          render json: { success: false, error: 'ログインに失敗しました。メールアドレスまたはパスワードが間違っています。' }, status: :unauthorized
        end
      end

      # ユーザーログアウト処理
      def destroy
        if current_user&.update(auth_token: nil)
          logout
          render json: { success: true, message: 'ログアウトに成功しました。' }, status: :ok
        else
          render json: { success: false, error: 'ログアウトに失敗しました。' }, status: :unprocessable_entity
        end
      end
      
    end
  end
end
