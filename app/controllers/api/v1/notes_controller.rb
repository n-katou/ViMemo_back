module Api
  module V1
    class NotesController < ApiController
      include Notes::NotesHelper

      # GET /api/v1/notes
      # ユーザーのノートをフィルタリングおよびソートして一覧表示するアクション
      def index
        filter = params[:filter]
        sort = params[:sort]
        order_option = order_option(sort)
        @notes = if filter == 'my_notes'
                   current_user.notes.includes(:youtube_video).order(order_option).page(params[:page]).per(12)
                 else
                   Note.where(is_visible: true).includes(:youtube_video).order(order_option).page(params[:page]).per(12)
                 end
        render json: {
          notes: @notes.as_json(include: {
            user: { only: [:id, :name, :avatar] },
            youtube_video: { only: [:id, :title] }
          }),
          current_page: @notes.current_page,
          total_pages: @notes.total_pages
        }
      end

      # POST /api/notes
      # 新しいノートを作成するアクション
      def create
        if @video
          @note = @video.notes.build(note_params)
          @note.user_id = current_user.id
          @note.video_timestamp = format_video_timestamp(params[:video_timestamp_minutes].to_i, params[:video_timestamp_seconds].to_i)

          # 一番下に表示するために最大のsort_orderを設定
          max_sort_order = @video.notes.maximum(:sort_order) || 0
          @note.sort_order = max_sort_order + 1

          if @note.save
            render json: @note.as_json(include: { user: { only: [:id, :name, :avatar] } }), status: :created
          else
            render json: @note.errors, status: :unprocessable_entity
          end
        else
          render json: { error: "Video not found." }, status: :not_found
        end
      end

      # PATCH/PUT /api/notes/:id
      # 既存のノートを更新するアクション
      def update
        @note.video_timestamp = format_video_timestamp(params[:video_timestamp_minutes].to_i, params[:video_timestamp_seconds].to_i)

        if @note.update(note_params)
          render json: @note.as_json(include: { user: { only: [:id, :name, :avatar] } }), status: :ok
        else
          render json: @note.errors, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/notes/:id
      # 指定されたノートを削除するアクション
      def destroy
        if @note.destroy
          render json: { message: "Note destroyed successfully." }, status: :ok
        else
          render json: @note.errors, status: :unprocessable_entity
        end
      end

      # POST /api/notes/save_sort_order
      # ノートのソート順を保存するアクション
      def save_sort_order
        sorted_note_ids = params[:sorted_notes].map { |note| note[:id] }
        save_sorted_order(sorted_note_ids)
        render json: { message: "Sort order saved successfully." }, status: :ok
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: "Note not found." }, status: :not_found
      rescue => e
        render json: { error: "Error saving sort order." }, status: :unprocessable_entity
      end
    end
  end
end
