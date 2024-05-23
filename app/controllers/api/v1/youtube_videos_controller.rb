module Api
  module V1
    class YoutubeVideosController < ApiController
      skip_before_action :authenticate_user!, only: [:index, :likes, :autocomplete, :show]
      before_action :optional_authenticate_user!, only: [:show]

      def fetch_videos_by_genre
        genre = params[:genre]
        api_key = ENV['YOUTUBE_API_KEY']
        encoded_genre = CGI.escape(genre)
        search_url = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=#{encoded_genre}&type=video&key=#{api_key}&maxResults=5"
        
        search_response = HTTParty.get(search_url)
        Rails.logger.info("YouTube API search response: #{search_response.body}")

        if search_response.success?
          youtube_videos_data = search_response.parsed_response["items"]
          newly_created_count = 0

          youtube_videos_data.each do |item|
            youtube_id = item["id"]["videoId"]
            video_url = "https://www.googleapis.com/youtube/v3/videos?id=#{youtube_id}&part=contentDetails&key=#{api_key}"
            video_response = HTTParty.get(video_url)
            Rails.logger.info("YouTube API video response: #{video_response.body}")

            if video_response.success?
              duration = video_response.parsed_response["items"].first["contentDetails"]["duration"]
              snippet = item["snippet"]
              video = YoutubeVideo.find_or_initialize_by(youtube_id: youtube_id)
              if video.new_record?
                video.title = snippet["title"]
                video.description = snippet["description"]
                video.published_at = snippet["publishedAt"]
                video.duration = parse_duration(duration) # ISO 8601の持続時間を秒に変換
                video.user_id = current_user.id 
                video.save
                newly_created_count += 1
              end
            end
          end

          render json: { youtube_videos_data: youtube_videos_data, newly_created_count: newly_created_count }, status: :ok
        else
          Rails.logger.error("Failed to fetch YouTube videos: #{search_response.body}")
          render json: { error: 'Failed to fetch YouTube videos' }, status: :bad_request
        end
      end

      def parse_duration(duration)
        match = duration.match(/PT(\d+H)?(\d+M)?(\d+S)?/)
        return 0 unless match # matchがnilの場合は0を返す

        hours = (match[1]&.chomp('H')&.to_i || 0) * 3600
        minutes = (match[2]&.chomp('M')&.to_i || 0) * 60
        seconds = (match[3]&.chomp('S')&.to_i || 0)

        hours + minutes + seconds
      end

      def index
        @q = YoutubeVideo.ransack(params[:q])
        @youtube_videos = @q.result(distinct: true).includes(:user, notes: :user, likes: :user)

        @youtube_videos = case params[:sort]
                          when 'likes_desc'
                            @youtube_videos.order(likes_count: :desc)
                          when 'notes_desc'
                            @youtube_videos.order(notes_count: :desc)
                          when 'created_at_desc'
                            @youtube_videos.order(created_at: :desc)
                          else
                            @youtube_videos.order(created_at: :desc) # デフォルト
                          end

        @youtube_videos = @youtube_videos.page(params[:page]).per(params[:per_page] || 9)

        pagination_metadata = {
          current_page: @youtube_videos.current_page,
          total_pages: @youtube_videos.total_pages,
          next_page: @youtube_videos.next_page,
          prev_page: @youtube_videos.prev_page
        }

        render json: { 
          videos: @youtube_videos.map { |video|
            {
              id: video.id,
              title: video.title,
              description: video.description,
              published_at: video.published_at,
              youtube_id: video.youtube_id,
              duration: video.duration,
              likes_count: video.likes_count,
              notes_count: video.notes_count,
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
          pagination: pagination_metadata 
        }, status: :ok
      end
      
      def show
        @youtube_video = YoutubeVideo.includes(:user, notes: :user, likes: :user).find(params[:id])
      
        Rails.logger.debug "Current User in show action: #{current_user.inspect}"
      
        @notes = if current_user
                   @youtube_video.notes.where('is_visible = ? OR user_id = ?', true, current_user.id)
                 else
                   @youtube_video.notes.where(is_visible: true)
                 end
      
        render json: {
          youtube_video: {
            id: @youtube_video.id,
            title: @youtube_video.title,
            description: @youtube_video.description,
            published_at: @youtube_video.published_at,
            youtube_id: @youtube_video.youtube_id,
            duration: @youtube_video.duration,
            likes_count: @youtube_video.likes_count,
            notes_count: @youtube_video.notes_count,
            user: {
              id: @youtube_video.user.id,
              name: @youtube_video.user.name,
              avatar: @youtube_video.user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg"
            },
            likes: @youtube_video.likes.map { |like| { id: like.id, user_id: like.user_id, likeable_id: like.likeable_id, likeable_type: like.likeable_type } }
          },
          notes: @notes.map { |note| {
            id: note.id,
            content: note.content,
            video_timestamp: note.video_timestamp,
            is_visible: note.is_visible,
            likes_count: note.likes_count,
            created_at: note.created_at,
            user: {
              id: note.user.id,
              name: note.user.name,
              avatar: note.user.avatar.url || "#{ENV['S3_BASE_URL']}/default-avatar.jpg"
            },
            likes: note.likes.map { |like| { id: like.id, user_id: like.user_id, likeable_id: like.likeable_id, likeable_type: like.likeable_type } }
          } }
        }
      end

      def likes
        video = YoutubeVideo.find(params[:id])
        likes = video.likes.map { |like| 
          { id: like.id, user_id: like.user_id, likeable_id: like.likeable_id, likeable_type: like.likeable_type }
        }
        render json: { likes_count: video.likes_count, likes: likes }, status: :ok
      end

      def autocomplete
        # クエリが与えられている場合のみ処理する
        if params[:query].present?
          query = params[:query].downcase
          @youtube_videos = YoutubeVideo.where("LOWER(title) LIKE ?", "%#{query}%").limit(10)
        else
          @youtube_videos = []
        end

        render json: @youtube_videos.map { |video|
          {
            id: video.id,
            title: video.title
          }
        }, status: :ok
      end

      private
      
      def optional_authenticate_user!
        if request.headers['Authorization'].present?
          authenticate_user!
        end
      end
    end
  end
end
