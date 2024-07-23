module Api
  module V1
    class FavoritesVideosController < ApiController
      # すべてのアクションの前にユーザー認証を実行
      before_action :authenticate_user!

      # GET /api/v1/favorites
      # ユーザーのいいね動画を取得するアクション
      def index
        @user = current_user
        @likes = @user.likes.where(likeable_type: "YoutubeVideo")
        
        # 動画IDを取得して、関連する動画を一括で取得
        video_ids = @likes.map(&:likeable_id)
        liked_youtube_videos = YoutubeVideo.where(id: video_ids).includes(:user, :likes).sort_by(&:sort_order)
        
        @paginated_videos = Kaminari.paginate_array(liked_youtube_videos).page(params[:page]).per(params[:per_page] || 9)
        
        render json: {
          videos: @paginated_videos.map { |video|
            {
              id: video.id,
              title: video.title,
              published_at: video.published_at,
              youtube_id: video.youtube_id,
              duration: video.duration,
              likes_count: video.likes_count,
              notes_count: video.notes_count,
              sort_order: video.sort_order, # 並び替え順序を追加
              notes: video.notes.includes(:user).map { |note| # includes(:user)を追加
                {
                  id: note.id,
                  content: note.content,
                  video_timestamp: note.video_timestamp,
                  youtube_video_id: video.id,
                  created_at: note.created_at,
                  user: {
                    id: note.user.id,
                    name: note.user.name,
                    avatar: note.user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg"
                  }
                }
              },
              user: {
                id: video.user.id,
                name: video.user.name,
                avatar: video.user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg"
              },
              likes: video.likes.map { |like|
                { id: like.id, user_id: like.user_id, likeable_id: like.likeable_id, likeable_type: like.likeable_type }
              }
            }
          },
          pagination: {
            current_page: @paginated_videos.current_page,
            total_pages: @paginated_videos.total_pages,
            next_page: @paginated_videos.next_page,
            prev_page: @paginated_videos.prev_page
          }
        }, status: :ok
      end
      
      # GET /api/v1/favorites_count
      # お気に入り動画のカウントを取得するアクション
      def favorites_count
        # 現在のユーザーが指定されたlikeable_typeおよびlikeable_idに対して行ったいいねを取得
        likes = current_user.likes.where(likeable_type: params[:likeable_type], likeable_id: params[:likeable_id])
        render json: likes
      end

      # POST /api/v1/favorites/save_order
      # 動画の順序を保存するアクション
      def save_order
        video_ids = params[:video_ids]
        Rails.logger.debug "Received video order: #{video_ids}" # 追加: 受信した動画IDの順序をログ出力
        
        # トランザクションを使用してデータベース操作を一貫性のあるものにする
        ActiveRecord::Base.transaction do
          video_ids.each_with_index do |id, index|
            # 現在のユーザーが「いいね」したYoutubeVideoを取得
            like = current_user.likes.find_by(likeable_type: "YoutubeVideo", likeable_id: id)
            video = like&.likeable

            unless video
              # 動画が見つからなかった場合、エラーメッセージをログに記録し、例外を発生させる
              Rails.logger.error "Video not found: #{id} for user #{current_user.id}"
              raise ActiveRecord::RecordNotFound, "Couldn't find YoutubeVideo with 'id'=#{id} [WHERE user_id=#{current_user.id}]"
            end

            # 動画の並び順を更新
            video.update!(sort_order: index)
          end
        end

        # 成功メッセージを返す
        render json: { message: 'Order saved successfully' }, status: :ok
      rescue => e
        # エラーメッセージをログに記録し、エラーレスポンスを返す
        Rails.logger.error "Save order error: #{e.message}"
        render json: { error: 'Failed to save order', message: e.message }, status: :unprocessable_entity
      end      
    end
  end
end
