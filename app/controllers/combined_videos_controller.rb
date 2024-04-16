class CombinedVideosController < ApplicationController
  def index
    @search_params = search_params
    @q = YoutubeVideo.ransack(@search_params)
    @youtube_videos = @q.result(distinct: true)

    @up_q = Video.ransack(@search_params)
    @videos = @up_q.result(distinct: true)

    combined_videos = (@youtube_videos.to_a + @videos.to_a)

    sort_key = params[:sort_key] || 'created_at'
    sort_order = params[:sort_order] || 'desc'
    combined_videos.sort_by! { |video| video.send(sort_key) }
    combined_videos.reverse! if sort_order == 'desc'

    @paginated_videos = Kaminari.paginate_array(combined_videos).page(params[:page]).per(10)
  end



  def favorites
    @liked_videos = current_user.liked_videos.includes(:likes).page(params[:page]).per(10)
  end

  private
  
  def search_params
    params.fetch(:q, {}).permit(:title_cont, :created_at, :likes_count, :notes_count)
  end
end
