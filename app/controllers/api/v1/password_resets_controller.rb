module Api
  module V1
    class PasswordResetsController < ApiController
      skip_before_action :authenticate_user!, only: [:create, :edit, :update]

      # POST /api/v1/password_resets
      # 指定されたメールアドレスにパスワードリセットの案内を送信するアクション
      def create
        @user = User.find_by(email: params[:email])
        if @user
          @user.deliver_reset_password_instructions!
          render json: { message: 'パスワードリセットの案内をメールで送信しました' }, status: :ok
        else
          render json: { error: 'メールアドレスが見つかりません' }, status: :not_found
        end
      end

      # GET /api/v1/password_resets/:id/edit
      # パスワードリセットのトークンを検証するアクション
      def edit
        @token = params[:id]
        @user = User.load_from_reset_password_token(@token)
        if @user
          render json: { message: 'トークンが有効です' }, status: :ok
        else
          render json: { error: '無効なトークンです' }, status: :not_found
        end
      end

      # PATCH/PUT /api/v1/password_resets/:id
      # パスワードをリセットするアクション
      def update
        @token = params[:id]
        @user = User.load_from_reset_password_token(@token)

        if @user.blank?
          render json: { error: '無効なトークンです' }, status: :not_found
          return
        end

        @user.password_confirmation = params[:user][:password_confirmation]
        if @user.change_password(params[:user][:password])
          render json: { message: 'パスワードが正常にリセットされました' }, status: :ok
        else
          render json: { error: 'パスワードリセットに失敗しました' }, status: :unprocessable_entity
        end
      end
    end
  end
end
