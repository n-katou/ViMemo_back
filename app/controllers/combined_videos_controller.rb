class CombinedVideosController < ApplicationController
  def index
    @q = YoutubeVideo.ransack(params[:q])
    @youtube_videos = @q.result(distinct: true)

    @up_q = Video.ransack(params[:q])
    @videos = @up_q.result(distinct: true)

    combined_videos = (@youtube_videos.to_a + @videos.to_a).sort_by(&:created_at).reverse
    @paginated_videos = Kaminari.paginate_array(combined_videos).page(params[:page]).per(10)
  end

  def favorites
    @liked_videos = current_user.liked_videos.includes(:likes).page(params[:page]).per(10)
  end
end
