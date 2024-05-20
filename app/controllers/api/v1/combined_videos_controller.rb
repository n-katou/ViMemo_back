module Api
  module V1
    class CombinedVideosController < ApiController
      def favorites
        @user = current_user
        @likes = @user.likes.includes(:likeable)
      
        # 'likeable_type' を基にして異なるタイプのビデオをフィルタリング
        liked_youtube_videos = @likes.select { |like| like.likeable_type == "YoutubeVideo" }.map(&:likeable)
      
        sort_key = params[:sort_key] || 'created_at'
        sort_order = params[:sort_order] || 'desc'
        
        # ソート処理
        liked_youtube_videos.sort_by! { |video| video.send(sort_key) }
        liked_youtube_videos.reverse! if sort_order == 'desc'
      
        # ページネーション
        @paginated_videos = Kaminari.paginate_array(liked_youtube_videos).page(params[:page]).per(9)
        
        render json: {
          videos: @paginated_videos,
          pagination: {
            current_page: @paginated_videos.current_page,
            total_pages: @paginated_videos.total_pages,
            next_page: @paginated_videos.next_page,
            prev_page: @paginated_videos.prev_page
          }
        }
      end

      private
      
      def search_params
        params.fetch(:q, {}).permit(:title_cont, :created_at, :likes_count, :notes_count, :sort_key, :sort_order)
      end
    end
  end
end
