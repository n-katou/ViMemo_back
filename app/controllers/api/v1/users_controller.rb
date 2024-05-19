require 'jwt'
require 'net/http'
require 'openssl'

module Api
  module V1
    class UsersController < ApiController
      include JwtHandler  # JWT処理のモジュールをインクルード
      before_action :authenticate_user!, except: [:create, :auth_create]

      def create
        @user = User.new(user_params)
        if @user.save
          token = generate_jwt(@user.id)  
          decoded_token = decode_jwt(token) # トークン生成のメソッド、適宜実装が必要
          Rails.logger.info "Generated Token: #{token}"
          render json: { success: true, token: token, user: @user.slice(:id, :email, :name) }, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def auth_create
        user = User.find_by(email: user_params[:email])
      
        if user
          if user.valid_password?(user_params[:password])
            token = generate_jwt(user.id)  # JWTを生成
            Rails.logger.info "Generated Token: #{token}"
            render json: { success: true, token: token, user: user.slice(:id, :email, :name) }, status: :ok
          else
            render json: { error: "パスワードが間違っています" }, status: :unprocessable_entity
          end
        else
          user = User.new(user_params)
          if user.save
            token = generate_jwt(user.id)  # JWTを生成
            render json: { success: true, token: token, user: user.slice(:id, :email, :name) }, status: :ok
          else
            render json: { error: user.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      def show
        render json: current_user.as_json(only: [:id, :email, :name]), status: :ok
      end

      def mypage
        user = current_user
        youtube_video_likes = user.likes.includes(:likeable).where(likeable_type: 'YoutubeVideo').order(created_at: :desc)
        youtube_video_ids = youtube_video_likes.map { |like| like.likeable.youtube_id }
        youtube_playlist_url = "https://www.youtube.com/embed?playlist=#{youtube_video_ids.join(',')}&loop=1"
      
        note_likes = user.likes.includes(likeable: { user: {}, youtube_video: {} }).where(likeable_type: 'Note').order(created_at: :desc).limit(6)
      
        render json: {
          youtube_video_likes: youtube_video_likes,
          note_likes: note_likes.map { |like| 
            {
              id: like.id,
              likeable_id: like.likeable_id,
              likeable_type: like.likeable_type,
              created_at: like.created_at,
              updated_at: like.updated_at,
              user_id: like.user_id,
              likeable: {
                id: like.likeable.id,
                content: like.likeable.content,
                video_timestamp: like.likeable.video_timestamp,
                is_visible: like.likeable.is_visible,
                likes_count: like.likeable.likes_count,
                youtube_video_id: like.likeable.youtube_video&.id, # ここで動画IDを返す
                user: {
                  id: like.likeable.user.id,
                  name: like.likeable.user.name,
                  avatar_url: like.likeable.user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg"
                }
              }
            }
          },
          youtube_playlist_url: youtube_playlist_url,
          avatar_url: user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg",
          role: user.role  # roleを追加して返す
        }
      end
      

      private

      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      end

    end
  end
end
