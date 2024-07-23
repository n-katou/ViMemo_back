module Api
  module V1
    class LikesController < ApiController
      before_action :authenticate_user!
      before_action :find_likeable, only: [:create, :destroy, :current_user_like]

      # GET /api/v1/likes/current_user_like
      # 現在のユーザーのいいねを取得するアクション
      def current_user_like
        @like = @likeable.likes.find_by(user: current_user)
        if @like
          render json: { like_id: @like.id }, status: :ok
        else
          render json: { like_id: nil }, status: :ok
        end
      end

      # POST /api/v1/likes
      # アイテムに対していいねを作成するアクション
      def create
        existing_like = @likeable.likes.find_by(user: current_user)
        if existing_like
          render json: { success: false, error: 'You have already liked this item.' }, status: :unprocessable_entity
        else
          @like = @likeable.likes.new(user: current_user)
          if @like.save
            render json: { success: true, likes_count: @likeable.likes.count }, status: :created
          else
            render json: { success: false, error: 'Unable to like the item.' }, status: :unprocessable_entity
          end
        end
      end

      # DELETE /api/v1/likes/:id
      # アイテムに対するいいねを削除するアクション
      def destroy
        @like = @likeable.likes.find_by(id: params[:id], user: current_user)
        if @like
          @like.destroy
          render json: { success: true, likes_count: @likeable.likes.count }, status: :ok
        else
          render json: { success: false, error: 'Like not found.' }, status: :not_found
        end
      end
      
      private

      # リクエストされたアイテムを見つけるメソッド
      def find_likeable
        unless params[:likeable_type] && params[:likeable_id]
          render json: { success: false, error: 'Invalid parameters.' }, status: :unprocessable_entity
          return
        end
      
        klass = params[:likeable_type].safe_constantize
        @likeable = klass.find_by(id: params[:likeable_id])
        unless @likeable
          render json: { success: false, error: 'Invalid operation.' }, status: :not_found
        end
      end
    end
  end
end
