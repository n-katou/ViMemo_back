module Api
  module V1
    class YoutubeVideosController < ApiController
      include YoutubeVideos::FetchVideosHelper
      include YoutubeVideos::RenderHelper
      include YoutubeVideos::AuthenticationHelper

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
    end
  end
end
