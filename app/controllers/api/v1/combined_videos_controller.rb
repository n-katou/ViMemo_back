module Api
  module V1
    class CombinedVideosController < ApiController
      before_action :authenticate_user!

      def favorites
        @user = current_user
        @likes = @user.likes.includes(:likeable)

        liked_youtube_videos = @likes.where(likeable_type: "YoutubeVideo").map(&:likeable)

        sort_key = params[:sort_key] || 'created_at'
        sort_order = params[:sort_order] || 'desc'

        liked_youtube_videos.sort_by! { |video| video.send(sort_key) }
        liked_youtube_videos.reverse! if sort_order == 'desc'

        @paginated_videos = Kaminari.paginate_array(liked_youtube_videos).page(params[:page]).per(params[:per_page] || 9)

        render json: {
          videos: @paginated_videos.map { |video|
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
          pagination: {
            current_page: @paginated_videos.current_page,
            total_pages: @paginated_videos.total_pages,
            next_page: @paginated_videos.next_page,
            prev_page: @paginated_videos.prev_page
          }
        }, status: :ok
      end

      def index
        likes = current_user.likes.where(likeable_type: params[:likeable_type], likeable_id: params[:likeable_id])
        render json: likes
      end
    end
  end
end
