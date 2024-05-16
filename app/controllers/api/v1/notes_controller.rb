module Api
  module V1
    class NotesController < ApiController
      before_action :set_video, only: [:create]
      before_action :set_note, only: [:update, :destroy]

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

      # GET /api/notes
      def index
        filter = params[:filter]
        Rails.logger.debug "Listing notes with filter: #{filter}"
      
        if filter == 'my_notes'
          @notes = current_user.notes.order(created_at: :desc).page(params[:page]).per(10)
        elsif filter == 'all_notes'
          @notes = Note.where(is_visible: true).order(created_at: :desc).page(params[:page]).per(10)
        else
          @notes = current_user.notes.order(created_at: :desc).page(params[:page]).per(10)
        end
        render json: @notes.as_json(include: { user: { only: [:id, :name, :avatar] } })
      end

      private

      def set_video
        @video = params[:youtube_video_id] ? YoutubeVideo.find_by(id: params[:youtube_video_id]) : Video.find_by(id: params[:video_id])
        Rails.logger.debug "Video set for note operations: #{@video&.id}"
      end
      
      def set_note
        @note = Note.find(params[:id])
        Rails.logger.debug "Note set for operations: #{@note&.id}"
      end

      def note_params
        params.require(:note).permit(:content, :video_timestamp, :is_visible)
      end
    end
  end
end
