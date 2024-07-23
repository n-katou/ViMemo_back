module Api
  module V1
    class FavoritesVideosController < ApiController
      include FavoritesVideos::FavoritesHelper

      before_action :authenticate_user!

      # GET /api/v1/favorites
      # ユーザーのいいね動画を取得するアクション
      def index
        @user = current_user
        render json: fetch_favorites_response(@user, params[:page], params[:per_page]), status: :ok
      end
      
      # GET /api/v1/favorites_count
      # お気に入り動画のカウントを取得するアクション
      def favorites_count
        likes = count_favorites(current_user, params[:likeable_type], params[:likeable_id])
        render json: likes
      end

      # POST /api/v1/favorites/save_order
      # 動画の順序を保存するアクション
      def save_order
        video_ids = params[:video_ids]
        save_video_order(current_user, video_ids)

        # 成功メッセージを返す
        render json: { message: 'Order saved successfully' }, status: :ok
      rescue => e
        render json: { error: 'Failed to save order', message: e.message }, status: :unprocessable_entity
      end
    end
  end
end
