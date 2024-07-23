module FavoritesVideos
  module FavoritesHelper
    extend ActiveSupport::Concern

    included do
      # いいね動画のレスポンスデータを生成するメソッド
      def fetch_favorites_response(user, page, per_page)
        paginated_videos = fetch_favorites(user, page, per_page)

        {
          videos: paginated_videos.map { |video|
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
            current_page: paginated_videos.current_page,
            total_pages: paginated_videos.total_pages,
            next_page: paginated_videos.next_page,
            prev_page: paginated_videos.prev_page
          }
        }
      end

      # ユーザーのいいね動画を取得するメソッド
      def fetch_favorites(user, page, per_page)
        likes = user.likes.where(likeable_type: "YoutubeVideo")
        
        # 動画IDを取得して、関連する動画を一括で取得
        video_ids = likes.map(&:likeable_id)
        liked_youtube_videos = YoutubeVideo.where(id: video_ids).includes(:user, :likes).sort_by(&:sort_order)
        
        Kaminari.paginate_array(liked_youtube_videos).page(page).per(per_page || 9)
      end

      # 動画の順序を保存するメソッド
      def save_video_order(user, video_ids)
        ActiveRecord::Base.transaction do
          video_ids.each_with_index do |id, index|
            like = user.likes.find_by(likeable_type: "YoutubeVideo", likeable_id: id)
            video = like&.likeable

            unless video
              raise ActiveRecord::RecordNotFound, "Couldn't find YoutubeVideo with 'id'=#{id} [WHERE user_id=#{user.id}]"
            end

            video.update!(sort_order: index)
          end
        end
      end

      # お気に入り動画のカウントを取得するメソッド
      def count_favorites(user, likeable_type, likeable_id)
        user.likes.where(likeable_type: likeable_type, likeable_id: likeable_id)
      end
    end
  end
end
