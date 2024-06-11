module Api
  module V1
    class UsersController < ApiController
      include JwtHandler
      before_action :authenticate_user!, except: [:create, :auth_create]  # createとauth_createを除く全てのアクションで認証を要求

      # 新しいユーザーを作成するアクション
      def create
        @user = User.new(user_params)  # ユーザーのパラメータを使用して新しいユーザーオブジェクトを作成
        if @user.save
          token = generate_jwt(@user.id)  # ユーザーIDを基にJWTを生成
          decoded_token = decode_jwt(token) # トークンをデコード（必要に応じて）
          render json: { success: true, token: token, user: @user.slice(:id, :email, :name) }, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # 認証付きユーザーを作成またはログインするアクション
      def auth_create
        user = User.find_by(email: user_params[:email])  # メールアドレスでユーザーを検索

        if user
          if user.valid_password?(user_params[:password])
            token = generate_jwt(user.id)  # JWTを生成
            render json: { success: true, token: token, user: user.slice(:id, :email, :name) }, status: :ok
          else
            render json: { error: "パスワードが間違っています" }, status: :unprocessable_entity
          end
        else
          user = User.new(user_params)  # ユーザーが存在しない場合は新しいユーザーを作成
          if user.save
            token = generate_jwt(user.id)  # JWTを生成
            render json: { success: true, token: token, user: user.slice(:id, :email, :name) }, status: :ok
          else
            render json: { error: user.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      # 現在のユーザーの情報を表示するアクション
      # google_auth2ログイン用
      def show
        render json: current_user.as_json(only: [:id, :email, :name, :role]), status: :ok  # 現在のユーザーの情報をJSON形式で返す
      end

      # マイページ情報を取得するアクション
      def mypage
        user = current_user
        youtube_video_likes = user.likes.includes(:likeable).where(likeable_type: 'YoutubeVideo').joins('INNER JOIN youtube_videos ON likes.likeable_id = youtube_videos.id').order('youtube_videos.sort_order ASC')
        youtube_video_ids = youtube_video_likes.map { |like| like.likeable.youtube_id }
        youtube_playlist_url = "https://www.youtube.com/embed?playlist=#{youtube_video_ids.join(',')}&loop=1"
      
        note_likes = user.likes.includes(likeable: { user: {}, youtube_video: {} }).where(likeable_type: 'Note').order(created_at: :desc)
      
        response_data = {
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
                youtube_video_id: like.likeable.youtube_video&.id,
                youtube_video_title: like.likeable.youtube_video&.title,
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
          role: user.role,  # roleを追加して返す
          email: user.email,  # emailを追加
          name: user.name  # nameを追加
        }
      
        Rails.logger.info "Response Data: #{response_data.to_json}"  # レスポンスデータをログに出力
      
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
          render json: { success: true, user: current_user.slice(:id, :email, :name, :avatar_url, :role) }, status: :ok  # 更新成功時のレスポンス
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity  # 更新失敗時のレスポンス
        end
      end

      # ノートと動画を取得するアクション
      def notes_with_videos
        sort_option = params[:sort] || 'created_at_desc'
      
        sort_column, sort_direction = if sort_option.match(/(.*)_(asc|desc)/)
                                        [$1, $2]
                                      else
                                        ['created_at', 'desc']
                                      end
      
        Rails.logger.debug "Sort Column: #{sort_column}, Sort Direction: #{sort_direction}"
      
        sort_column = 'created_at' unless %w[created_at].include?(sort_column)
        sort_direction = 'desc' unless %w[asc desc].include?(sort_direction)
      
        notes = current_user.notes.includes(:youtube_video).order("#{sort_column} #{sort_direction}")
        notes_with_videos = notes.map do |note|
          {
            id: note.id,
            content: note.content,
            video_timestamp: note.video_timestamp,
            youtube_video_id: note.youtube_video_id,
            created_at: note.created_at,
            video_title: note.youtube_video.title
          }
        end
        render json: { notes: notes_with_videos }
      end

      private

      # ユーザーパラメータを許可するストロングパラメータ
      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation, :avatar)
      end
    end
  end
end
