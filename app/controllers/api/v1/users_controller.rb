module Api
  module V1
    class UsersController < ApiController
      include JwtHandler
      include Users::UserHelper
      before_action :authenticate_user!, except: [:create, :auth_create]

      # 新しいユーザーを作成するアクション
      def create
        @user = User.new(user_params)  # ユーザーのパラメータを使用して新しいユーザーオブジェクトを作成
        if @user.save
          render json: generate_jwt_and_render_user(@user), status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # 認証付きユーザーを作成またはログインするアクション
      def auth_create
        user = User.find_by(email: user_params[:email])  # メールアドレスでユーザーを検索

        if user
          if user.valid_password?(user_params[:password])
            render json: generate_jwt_and_render_user(user), status: :ok
          else
            render json: { error: "パスワードが間違っています" }, status: :unprocessable_entity
          end
        else
          user = User.new(user_params)  # ユーザーが存在しない場合は新しいユーザーを作成
          if user.save
            render json: generate_jwt_and_render_user(user), status: :ok
          else
            render json: { error: user.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      # 現在のユーザーの情報を表示するアクション
      def show
        render json: current_user.as_json(only: [:id, :email, :name, :role]), status: :ok 
      end

      # マイページ情報を取得するアクション
      def mypage
        user = current_user
        response_data = generate_response_data(user)
        render json: response_data
      end

      # シャッフルプレイリストURLを生成するアクション
      def generate_shuffle_playlist
        user = current_user
        youtube_video_likes = user.likes.includes(:likeable).where(likeable_type: 'YoutubeVideo').order(created_at: :desc)
        shuffled_youtube_video_ids = youtube_video_likes.map { |like| like.likeable.youtube_id }.shuffle
        shuffled_youtube_playlist_url = "https://www.youtube.com/embed?playlist=#{shuffled_youtube_video_ids.join(',')}&loop=1"

        render json: { shuffled_youtube_playlist_url: shuffled_youtube_playlist_url }, status: :ok
      end

      # ユーザー情報を更新するアクション
      def update
        if current_user.update(user_params)
          render json: { success: true, user: current_user.slice(:id, :email, :name, :avatar_url, :role) }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # ノートと動画を取得するアクション
      def my_notes
        user = current_user
        sort_option = params[:sort] || 'created_at_desc'
        response_data = notes_with_videos(user, sort_option)
        render json: response_data
      end

      private

      # ユーザーパラメータを許可するストロングパラメータ
      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation, :avatar)
      end
    end
  end
end
