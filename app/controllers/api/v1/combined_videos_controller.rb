module Api
  module V1
    class CombinedVideosController < ApiController
      # すべてのアクションの前にユーザー認証を実行
      before_action :authenticate_user!

      # ユーザーのいいね動画を取得するアクション
      def favorites
        @user = current_user # 現在のユーザーを取得
        @likes = @user.likes.includes(likeable: :notes) # ユーザーのいいねを取得し、likeableと一緒に読み込む
        liked_youtube_videos = @likes.where(likeable_type: "YoutubeVideo").map(&:likeable) # YouTube動画に対するいいねを取得
      
        # パラメータに基づいて動画をソート
        @youtube_videos = case params[:sort]
                          when 'likes_desc'
                            liked_youtube_videos.sort_by(&:likes_count).reverse
                          when 'notes_desc'
                            liked_youtube_videos.sort_by(&:notes_count).reverse
                          when 'created_at_desc'
                            liked_youtube_videos.sort_by(&:created_at).reverse
                          else
                            liked_youtube_videos.sort_by(&:created_at).reverse # デフォルトは作成日の降順
                          end
      
        # ページネーションを適用
        @paginated_videos = Kaminari.paginate_array(@youtube_videos).page(params[:page]).per(params[:per_page] || 9)
      
        # JSON形式で応答
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
              notes: video.notes.map { |note|
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

      # お気に入り動画のカウントを取得
      def index
        # 現在のユーザーが指定されたlikeable_typeおよびlikeable_idに対して行ったいいねを取得
        likes = current_user.likes.where(likeable_type: params[:likeable_type], likeable_id: params[:likeable_id])
        render json: likes
      end

      # 動画の順序を保存するアクション
      def save_order
        video_ids = params[:video_ids]
        ActiveRecord::Base.transaction do
          video_ids.each_with_index do |id, index|
            video = current_user.youtube_videos.find(id)
            video.update!(sort_order: index)
          end
        end
        render json: { message: 'Order saved successfully' }, status: :ok
      rescue => e
        Rails.logger.error "Save order error: #{e.message}"
        render json: { error: 'Failed to save order', message: e.message }, status: :unprocessable_entity
      end
      
    end
  end
end
