class Admin::VideosController < Admin::BaseController
  before_action :set_video, only: %i[show ]
    def index
        @search_params = search_params
  
        @q = YoutubeVideo.ransack(@search_params)
        @youtube_videos = @q.result(distinct: true)
      
        @up_q = Video.ransack(@search_params)
        @videos = @up_q.result(distinct: true)
      
        combined_videos = (@youtube_videos.to_a + @videos.to_a)
      
        @paginated_videos = Kaminari.paginate_array(combined_videos).page(params[:page]).per(10)
    end

    def show; end


    private

    def set_video
        @video = YoutubeVideo.find(params[:id])
    end

    def video_params
        params.require(:video).permit(:email, :password, :password_confirmation, :name, :avatar, :role, :is_valid)
    end

    def search_params
        params.fetch(:q, {}).permit(:title_cont, :created_at, :likes_count, :notes_count, :sort_key, :sort_order)
    end
        
end