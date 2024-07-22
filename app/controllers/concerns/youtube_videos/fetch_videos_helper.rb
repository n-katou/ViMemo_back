module YoutubeVideos
  module FetchVideosHelper
    extend ActiveSupport::Concern

    included do
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

      # 動画の持続時間をパースするメソッド
      def parse_duration(duration)
        match = duration.match(/PT(\d+H)?(\d+M)?(\d+S)?/)
        return 0 unless match
        hours, minutes, seconds = match.captures.map { |t| t.to_i }
        hours * 3600 + minutes * 60 + seconds
      end
    end
  end
end
