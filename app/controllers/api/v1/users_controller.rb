module Api
  module V1
    class UsersController < ApiController
      include Users::UserHelper
      include FavoritesVideos::FavoritesHelper

      before_action :authenticate_user!, except: [:create, :auth_create]

      # POST /api/v1/users
      # 新しいユーザーを作成するアクション
      def create
        @user = User.new(user_params)  # ユーザーのパラメータを使用して新しいユーザーオブジェクトを作成
        if @user.save
          render json: generate_jwt_and_render_user(@user), status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/users/auth_create
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

      # GET /api/v1/users/show
      # 現在のユーザーの情報を表示するアクション
      def show
        render json: current_user.as_json(only: [:id, :email, :name, :role]), status: :ok 
      end

      # GET /api/v1/users/mypage
      # マイページ情報を取得するアクション
      def mypage
        user = current_user
        response_data = generate_response_data(user)
        render json: response_data
      end

      # GET /api/v1/users/generate_shuffle_playlist
      # シャッフルプレイリストURLを生成するアクション
      def generate_shuffle_playlist
        user = current_user
        youtube_video_likes = user.likes.includes(likeable: :youtube_video).where(likeable_type: 'YoutubeVideo').order(created_at: :desc)
      
        # 各likeable（YoutubeVideo）のtitleやidなどを返す
        youtube_videos = youtube_video_likes.map do |like|
          video = like.likeable
          {
            id: video.id,
            title: video.title,
            youtube_id: video.youtube_id,
            created_at: like.created_at
          }
        end
      
        shuffled_youtube_videos = youtube_videos.shuffle
      
        shuffled_youtube_playlist_url = "https://www.youtube.com/embed?playlist=#{shuffled_youtube_videos.map { |v| v[:youtube_id] }.join(',')}&loop=1"
      
        render json: { shuffled_youtube_playlist_url: shuffled_youtube_playlist_url, youtube_videos: shuffled_youtube_videos }, status: :ok
      end

      # PATCH/PUT /api/v1/users/update
      # ユーザー情報を更新するアクション
      def update
        if current_user.update(user_params)
          render json: { success: true, user: current_user.slice(:id, :email, :name, :avatar_url, :role) }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/users/my_notes
      # ノートと動画を取得するアクション
      def my_notes
        user = current_user
        sort_option = params[:sort] || 'created_at_desc'
        response_data = notes_with_videos(user, sort_option)
        render json: response_data
      end

      def update_playlist_order
        video_ids = params[:video_ids]  # video_ids を取得
        unless video_ids.present?
          render json: { message: 'No video_ids provided' }, status: :bad_request
          return
        end
      
        # トランザクションを使用して順序を更新
        ActiveRecord::Base.transaction do
          video_ids.each_with_index do |id, index|
            # ユーザーがいいねした動画を取得
            like = current_user.likes.find_by(likeable_id: id, likeable_type: 'YoutubeVideo')
            
            if like
              video = YoutubeVideo.find(like.likeable_id)
              video.update!(sort_order: index)  # 新しい順序を更新
            else
              Rails.logger.debug "No like found for video_id #{id} for user #{current_user.id}"
            end
          end
        end
      
        render json: { message: 'Playlist order updated successfully' }, status: :ok
      rescue => e
        Rails.logger.error "Error updating playlist order: #{e.message}"
        render json: { message: 'Error updating playlist order', error: e.message }, status: :unprocessable_entity
      end

      # GET /api/v1/users/like_note
      def like_note
        user = current_user
        response_data = generate_response_data_note(user)
        render json: response_data
      end

      
      private

      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation, :avatar)
      end
    end
  end
end
