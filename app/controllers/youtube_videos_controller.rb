class YoutubeVideosController < ApplicationController
  require 'httparty'
  require 'cgi'

  skip_before_action :require_login, only: [:index,:show] #FEで認証できるようになったら消す。

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
    @youtube_videos = @q.result(distinct: true).includes(:notes)
  
    # ソートロジック
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
  
    # ページング
    @youtube_videos = @youtube_videos.page(params[:page])

    # ページングメタデータを生成
    pagination_metadata = {
      current_page: @youtube_videos.current_page,
      total_pages: @youtube_videos.total_pages,
      next_page: @youtube_videos.next_page,
      prev_page: @youtube_videos.prev_page
    }
  
    # リクエスト形式に基づいてレスポンスを返す
    respond_to do |format|
      format.html do
        # HTMLビュー用の処理
        @filtered_q_params = params[:q]&.permit(:notes_content_cont)
        render 'index'  # 対応するビューをレンダリング
      end
      format.json do
        # JSON形式のレスポンス
        render json: { videos: @youtube_videos, pagination: pagination_metadata }, status: :ok
      end
    end
  end
  # 特定のビデオを表示するアクション
  def show
    @youtube_video = YoutubeVideo.find(params[:id])
  
    # ログインしているかどうかによってノートの取得条件を分ける
    @notes = if current_user
               @youtube_video.notes
             else
               @youtube_video.notes.where(is_visible: true)
             end
  
    respond_to do |format|
      # HTML形式のレスポンス
      format.html do
        # HTMLビューを表示 (例えば、show.html.erb)
        render 'show'
      end
  
      # JSON形式のレスポンス
      format.json do
        render json: {
          youtube_video: {
            id: @youtube_video.id,
            title: @youtube_video.title,
            published_at: @youtube_video.published_at,
            youtube_id: @youtube_video.youtube_id,
            duration: @youtube_video.duration,
          },
          notes: @notes.map { |note| { id: note.id, content: note.content, is_visible: note.is_visible } }
        }
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { render file: 'public/404.html', status: 404, layout: false } # 404エラーページ
      format.json { render json: { error: "YoutubeVideo not found" }, status: 404 }
    end
  rescue => e
    respond_to do |format|
      format.html { render file: 'public/500.html', status: 500, layout: false } # 500エラーページ
      format.json { render json: { error: e.message }, status: 500 }
    end
  end

  def destroy
    @youtube_video = YoutubeVideo.find_by(id: params[:id])
    if @youtube_video
      @youtube_video.destroy
      redirect_to admin_videos_path, success: t('defaults.flash_message.deleted', item: YoutubeVideo.model_name.human), status: :see_other
    else
      # ビデオが見つからない場合の処理
      redirect_to youtube_videos_path, alert: 'Video not found', status: :not_found
    end
  end
end
