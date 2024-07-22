module Api
  module V1
    class YoutubeVideosController < ApiController
      # 認証が必要ないアクションを指定
      skip_before_action :authenticate_user!, only: [:index, :likes, :autocomplete, :show]
      before_action :optional_authenticate_user!, only: [:show]

      # ジャンル別にYouTube動画を取得するアクション
      def fetch_videos_by_genre
        if user_can_fetch_videos?
          genre = params[:genre]
          api_key = ENV['YOUTUBE_API_KEY']
          encoded_genre = CGI.escape(genre)
          search_url = youtube_search_url(encoded_genre, api_key)
          search_response = HTTParty.get(search_url)

          if search_response.success?
            handle_successful_search(search_response, api_key)
          else
            render json: { success: false, message: 'ビデオの取得に失敗しました。' }, status: :unprocessable_entity
          end
        else
          render json: { success: false, message: 'ビデオは1日に1回しか取得できません。' }, status: :forbidden
        end
      end

      # YouTube動画の一覧を表示するアクション
      def index
        @q = YoutubeVideo.ransack(params[:q])
        @youtube_videos = fetch_sorted_videos(@q.result(distinct: true))
        @youtube_videos = @youtube_videos.page(params[:page]).per(params[:per_page] || 9)
        
        render json: {
          videos: @youtube_videos.map { |video| video_data(video) },
          pagination: pagination_metadata(@youtube_videos)
        }, status: :ok
      end

      # 特定のYouTube動画を表示するアクション
      def show
        @youtube_video = YoutubeVideo.includes(:user, :likes).find(params[:id])
        @notes = fetch_notes(@youtube_video)
        
        render json: {
          youtube_video: video_data(@youtube_video),
          notes: @notes.map { |note| note_data(note) }
        }
      end

      # 特定のYouTube動画のいいねを表示するアクション
      def likes
        video = YoutubeVideo.find(params[:id])
        render json: { likes_count: video.likes_count, likes: video.likes.map { |like| like_data(like) } }, status: :ok
      end

      # 自動補完のためのアクション
      def autocomplete
        @youtube_videos = params[:query].present? ? search_videos(params[:query]) : []
        render json: @youtube_videos.map { |video| { id: video.id, title: video.title } }, status: :ok
      end

      private

      # ユーザーの認証をオプションにするメソッド
      def optional_authenticate_user!
        authenticate_user! if request.headers['Authorization'].present?
      end

      # 動画の持続時間をパースするメソッド
      def parse_duration(duration)
        match = duration.match(/PT(\d+H)?(\d+M)?(\d+S)?/)
        return 0 unless match
        hours, minutes, seconds = match.captures.map { |t| t.to_i }
        hours * 3600 + minutes * 60 + seconds
      end

      # ユーザーが動画を取得可能か確認するメソッド
      def user_can_fetch_videos?
        current_user.can_fetch_videos? || current_user.admin?
      end

      # YouTube検索URLを生成するメソッド
      def youtube_search_url(encoded_genre, api_key)
        "https://www.googleapis.com/youtube/v3/search?part=snippet&q=#{encoded_genre}&type=video&key=#{api_key}&maxResults=10"
      end

      # YouTube検索の成功時に処理を行うメソッド
      def handle_successful_search(search_response, api_key)
        youtube_videos_data = search_response.parsed_response["items"]
        newly_created_count, fetched_videos = 0, []

        youtube_videos_data.each do |item|
          youtube_id = item["id"]["videoId"]
          video_response = HTTParty.get(video_details_url(youtube_id, api_key))

          if video_response.success?
            duration = video_response.parsed_response["items"].first["contentDetails"]["duration"]
            snippet = item["snippet"]
            video = YoutubeVideo.find_or_initialize_by(youtube_id: youtube_id)
            if video.new_record?
              create_new_video(video, snippet, duration)
              newly_created_count += 1
            end
            fetched_videos << format_video_data(snippet, duration)
          end
        end

        record_video_fetch if current_user.general?

        render json: {
          success: true,
          youtube_videos_data: fetched_videos,
          newly_created_count: newly_created_count,
          last_video_fetch_date: current_user.last_video_fetch_date,
          video_fetch_count: current_user.video_fetch_count
        }
      end

      # YouTube動画詳細のURLを生成するメソッド
      def video_details_url(youtube_id, api_key)
        "https://www.googleapis.com/youtube/v3/videos?id=#{youtube_id}&part=contentDetails&key=#{api_key}"
      end

      # 新しいYouTube動画を作成するメソッド
      def create_new_video(video, snippet, duration)
        video.title = snippet["title"]
        video.description = snippet["description"]
        video.published_at = snippet["publishedAt"]
        video.duration = parse_duration(duration)
        video.user_id = current_user.id
        video.save
      end

      # 動画データをフォーマットするメソッド
      def format_video_data(snippet, duration)
        {
          title: snippet["title"],
          description: snippet["description"],
          published_at: snippet["publishedAt"],
          duration: parse_duration(duration)
        }
      end

      # 動画取得の記録を行うメソッド
      def record_video_fetch
        current_user.record_video_fetch
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

      # ページネーションのメタデータを取得するメソッド
      def pagination_metadata(videos)
        {
          current_page: videos.current_page,
          total_pages: videos.total_pages,
          next_page: videos.next_page,
          prev_page: videos.prev_page
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
          avatar: user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg"
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
    end
  end
end
