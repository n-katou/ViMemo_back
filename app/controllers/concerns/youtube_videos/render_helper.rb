module YoutubeVideos
  module RenderHelper
    extend ActiveSupport::Concern

    included do
      # ページネーションのメタデータを取得するメソッド
      def pagination_metadata(videos)
        {
          current_page: videos.current_page,
          total_pages: videos.total_pages,
          next_page: videos.next_page,
          prev_page: videos.prev_page
        }
      end

      # YouTube動画のデータを取得するメソッド
      def video_data(video)
        {
          id: video.id,
          title: video.title,
          description: video.description,
          published_at: video.published_at,
          youtube_id: video.youtube_id,
          duration: video.duration,
          likes_count: video.likes_count,
          notes_count: video.notes_count,
          user: user_data(video.user),
          likes: video.likes.map { |like| like_data(like) },
          notes: video.notes.map { |note| note_data(note) }
        }
      end

      # ユーザーデータを取得するメソッド
      def user_data(user)
        {
          id: user.id,
          name: user.name,
          # avatar: user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg"
          avatar: user.avatar.url || "/default-avatar.jpg",
        }
      end

      # いいねデータを取得するメソッド
      def like_data(like)
        {
          id: like.id,
          user_id: like.user_id,
          likeable_id: like.likeable_id,
          likeable_type: like.likeable_type
        }
      end

      # ノートデータを取得するメソッド
      def note_data(note)
        {
          id: note.id,
          content: note.content,
          video_timestamp: note.video_timestamp,
          is_visible: note.is_visible,
          likes_count: note.likes_count,
          sort_order: note.sort_order,
          created_at: note.created_at,
          user: user_data(note.user),
          youtube_video: { id: note.youtube_video.id, youtube_id: note.youtube_video.youtube_id, title: note.youtube_video.title },
          likes: note.likes.map { |like| like_data(like) }
        }
      end

      # YouTube動画のノートを取得するメソッド
      def fetch_notes(youtube_video)
        if current_user
          youtube_video.notes.where('is_visible = ? OR user_id = ?', true, current_user.id).includes(:user, :likes).order(:sort_order)
        else
          youtube_video.notes.where(is_visible: true).includes(:user, :likes).order(:sort_order)
        end
      end

      # 検索クエリに基づいて動画を検索するメソッド
      def search_videos(query)
        YoutubeVideo.where("LOWER(title) LIKE ?", "%#{query.downcase}%").limit(10)
      end

      # ソートされた動画を取得するメソッド
      def fetch_sorted_videos(videos)
        case params[:sort]
        when 'likes_desc'
          videos.order(likes_count: :desc)
        when 'notes_desc'
          videos.order(notes_count: :desc)
        when 'published_at_desc'
          videos.order(published_at: :desc)
        else
          videos.order(created_at: :desc)
        end
      end
    end
  end
end
