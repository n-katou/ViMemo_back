class YoutubeVideosController < ApplicationController
  require 'httparty'
  require 'cgi'

  def fetch_videos_by_genre
    genre = params[:genre]
    api_key = ENV['YOUTUBE_API_KEY']
  
    encoded_genre = CGI.escape(genre)
    search_url = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=#{encoded_genre}&type=video&key=#{api_key}&maxResults=10"
    search_response = HTTParty.get(search_url)
    
    if search_response.success?
      youtube_videos_data = search_response.parsed_response["items"]
      
      youtube_videos_data.each do |item|
        youtube_id = item["id"]["videoId"]
  
        # videosエンドポイントを使用して動画の詳細情報を取得
        video_url = "https://www.googleapis.com/youtube/v3/videos?id=#{youtube_id}&part=contentDetails&key=#{api_key}"
        video_response = HTTParty.get(video_url)
  
        if video_response.success?
          duration = video_response.parsed_response["items"].first["contentDetails"]["duration"]
  
          snippet = item["snippet"]
          YoutubeVideo.find_or_create_by(youtube_id: youtube_id) do |youtube_video|
            youtube_video.title = snippet["title"]
            youtube_video.description = snippet["description"]
            youtube_video.published_at = snippet["publishedAt"]
            youtube_video.duration = parse_duration(duration) # ISO 8601の持続時間を秒に変換
            youtube_video.user_id = current_user.id 
          end
        end
      end
      
      render json: { status: 'Success', message: "#{youtube_videos_data.length} videos fetched and saved successfully." }, status: :ok
    else
      render json: { status: 'Error', message: 'Failed to fetch videos from YouTube' }, status: :bad_request
    end
  end
  
  # ISO 8601持続時間形式（PT#H#M#S）を秒に変換
  def parse_duration(duration)
    match = duration.match(/PT(\d+H)?(\d+M)?(\d+S)?/)
    return 0 unless match # matchがnilの場合は0を返す
  
    hours = (match[1]&.chomp('H')&.to_i || 0) * 3600
    minutes = (match[2]&.chomp('M')&.to_i || 0) * 60
    seconds = (match[3]&.chomp('S')&.to_i || 0)
  
    hours + minutes + seconds
  end

  # ビデオの一覧を表示するアクション
  def index
    @q = YoutubeVideo.ransack(params[:q])
    @youtube_videos = @q.result(distinct: true).order(created_at: :desc).page(params[:page])
  end

  # 特定のビデオを表示するアクション
  def show
    @youtube_video = YoutubeVideo.find(params[:id])
  
    # ログインしているかどうかを確認
    if current_user
      @notes = @youtube_video.notes
    else
      @notes = @youtube_video.notes.where(is_visible: true)
    end
  end

  def destroy
    @youtube_video = YoutubeVideo.find_by(id: params[:id])
    if @youtube_video
      @youtube_video.destroy
      redirect_to youtube_videos_path, success: t('defaults.flash_message.deleted', item: YoutubeVideo.model_name.human), status: :see_other
    else
      # ビデオが見つからない場合の処理
      redirect_to youtube_videos_path, alert: 'Video not found', status: :not_found
    end
  end

end
