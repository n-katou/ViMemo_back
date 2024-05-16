class Api::V1::YoutubeVideosController < ApplicationController
  require 'httparty'
  require 'cgi'

  skip_before_action :require_login, only: [:index, :show]

  def fetch_videos_by_genre
    genre = params[:genre]
    api_key = ENV['YOUTUBE_API_KEY']
    encoded_genre = CGI.escape(genre)
    search_url = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=#{encoded_genre}&type=video&key=#{api_key}&maxResults=10"
    search_response = HTTParty.get(search_url)
  
    if search_response.success?
      youtube_videos_data = search_response.parsed_response["items"]
      newly_created_count = 0
  
      youtube_videos_data.each do |item|
        youtube_id = item["id"]["videoId"]
        video_url = "https://www.googleapis.com/youtube/v3/videos?id=#{youtube_id}&part=contentDetails&key=#{api_key}"
        video_response = HTTParty.get(video_url)
      
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
  
      flash[:success] = t('flash_messages.videos_fetched_success', count: newly_created_count)
      redirect_to youtube_videos_path
    else
      flash[:error] = t('flash_messages.fetch_videos_failed')
      redirect_to youtube_videos_path
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
    @youtube_videos = @q.result(distinct: true).includes(:notes)
  
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
  
    @youtube_videos = @youtube_videos.page(params[:page])

    pagination_metadata = {
      current_page: @youtube_videos.current_page,
      total_pages: @youtube_videos.total_pages,
      next_page: @youtube_videos.next_page,
      prev_page: @youtube_videos.prev_page
    }
    render json: { videos: @youtube_videos, pagination: pagination_metadata }, status: :ok
  end
  
  def show
    @youtube_video = YoutubeVideo.includes(:user, notes: :user).find(params[:id])
  
    @notes = if current_user
               @youtube_video.notes
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
          avatar: avatar_url(@youtube_video.user.avatar.url) # S3 URLを生成
        }
      },
      notes: @notes.map { |note| {
        id: note.id,
        content: note.content,
        video_timestamp: note.video_timestamp,
        is_visible: note.is_visible,
        likes_count: note.likes_count,
        user: {
          id: note.user.id,
          name: note.user.name,
          avatar: note.user.avatar.url # S3 URLを生成
        }
      } }
    }
  end

  def destroy
    @youtube_video = YoutubeVideo.find_by(id: params[:id])
    if @youtube_video
      @youtube_video.destroy
      redirect_to admin_videos_path, success: t('defaults.flash_message.deleted', item: YoutubeVideo.model_name.human), status: :see_other
    else
      redirect_to youtube_videos_path, alert: 'Video not found', status: :not_found
    end
  end

  private

  def avatar_url(path)
    "#{ENV['S3_BASE_URL']}/#{path}"
  end
end
