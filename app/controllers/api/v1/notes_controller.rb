module Api
  module V1
    class NotesController < ApiController
      before_action :set_video, only: [:create]
      before_action :set_note, only: [:update, :destroy]
      before_action :authorize_user!, only: [:update, :destroy]

      # POST /api/notes
      def create
        Rails.logger.debug "Creating note for video ID: #{@video&.id}, by user ID: #{current_user&.id}"
        if @video
          @note = @video.notes.build(note_params)
          @note.user_id = current_user.id
          minutes = params[:video_timestamp_minutes].to_i
          seconds = params[:video_timestamp_seconds].to_i
          @note.video_timestamp = format("%02d:%02d", minutes, seconds)

          if @note.save
            Rails.logger.debug "Note saved successfully: #{@note}"
            render json: @note.as_json(include: { user: { only: [:id, :name, :avatar] } }), status: :created
          else
            Rails.logger.error "Note save failed: #{@note.errors.full_messages}"
            render json: @note.errors, status: :unprocessable_entity
          end
        else
          Rails.logger.error "Video not found for given ID."
          render json: { error: "Video not found." }, status: :not_found
        end
      end

      # DELETE /api/notes/:id
      def destroy
        Rails.logger.debug "Deleting note ID: #{@note&.id}"
        if @note.destroy
          Rails.logger.debug "Note destroyed successfully."
          render json: { message: "Note destroyed successfully." }, status: :ok
        else
          Rails.logger.error "Note destruction failed: #{@note.errors.full_messages}"
          render json: @note.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/notes/:id
      def update
        minutes = params[:video_timestamp_minutes].to_i
        seconds = params[:video_timestamp_seconds].to_i
        @note.video_timestamp = format("%02d:%02d", minutes, seconds)

        if @note.update(note_params)
          Rails.logger.debug "Note updated successfully: #{@note}"
          render json: @note.as_json(include: { user: { only: [:id, :name, :avatar] } }), status: :ok
        else
          Rails.logger.error "Note update failed: #{@note.errors.full_messages}"
          render json: @note.errors, status: :unprocessable_entity
        end
      end

      # GET /api/v1/notes
      def index
        Rails.logger.debug "Request received to list user notes"
        filter = params[:filter]
        sort = params[:sort]
        Rails.logger.debug "Listing notes with filter: #{filter} and sort: #{sort}"

        order_option = case sort
                       when 'created_at_asc'
                         { created_at: :asc }
                       when 'created_at_desc'
                         { created_at: :desc }
                       else
                         { created_at: :desc }
                       end

        if filter == 'my_notes'
          @notes = current_user.notes.includes(:youtube_video).order(order_option).page(params[:page]).per(12)
        else
          @notes = Note.where(is_visible: true).includes(:youtube_video).order(order_option).page(params[:page]).per(12)
        end

        Rails.logger.debug "Notes found: #{@notes.pluck(:id)}"
        render json: {
          notes: @notes.as_json(include: {
            user: { only: [:id, :name, :avatar] },
            youtube_video: { only: [:id, :title] }
          }),
          current_page: @notes.current_page,
          total_pages: @notes.total_pages
        }
      end

      private

      def set_video
        @video = YoutubeVideo.find_by(id: params[:youtube_video_id])
        Rails.logger.debug "Video set for note operations: #{@video&.id}"
      end

      def set_note
        @note = Note.find(params[:id])
        Rails.logger.debug "Note set for operations: #{@note&.id}"
      end

      def authorize_user!
        unless @note.user_id == current_user.id
          Rails.logger.error "Unauthorized access attempt by user ID: #{current_user&.id}"
          render json: { error: 'Not Authorized' }, status: :unauthorized
        end
      end

      def note_params
        params.require(:note).permit(:content, :video_timestamp, :is_visible)
      end
    end
  end
end
