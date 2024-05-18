module Api
  module V1
    class LikesController < ApiController
      before_action :authenticate_user!
      before_action :find_likeable, only: [:create, :destroy]

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

      def destroy
        @like = @likeable.likes.find(params[:id])
        if @like
          @like.destroy
          render json: { success: true, likes_count: @likeable.likes.count }, status: :ok
        else
          render json: { success: false, error: 'Like not found.' }, status: :not_found
        end
      end

      private

      def find_likeable
        Rails.logger.debug "Params: #{params.inspect}" # デバッグ用
        klass = params[:likeable_type].safe_constantize
        @likeable = klass.find(params[:likeable_id])
        unless @likeable
          render json: { success: false, error: 'Invalid operation.' }, status: :not_found
        end
      end
    end
  end
end
