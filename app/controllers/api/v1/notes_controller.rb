module Api
  module V1
    class NotesController < ApiController
      before_action :set_video, only: [:create]
      before_action :set_note, only: [:update, :destroy]

      # POST /api/notes
      def create
        if @video
          @note = @video.notes.build(note_params)
          @note.user_id = current_user.id
          minutes = params[:video_timestamp_minutes].to_i
          seconds = params[:video_timestamp_seconds].to_i
          @note.video_timestamp = format("%02d:%02d", minutes, seconds)
      
          if @note.save
            render json: @note, status: :created
          else
            render json: @note.errors, status: :unprocessable_entity
          end
        else
          render json: { error: "Video not found." }, status: :not_found
        end
      end

      # DELETE /api/notes/:id
      def destroy
        if @note.destroy
          render json: { message: "Note destroyed successfully." }, status: :ok
        else
          render json: @note.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/notes/:id
      def update
        minutes = params[:video_timestamp_minutes].to_i
        seconds = params[:video_timestamp_seconds].to_i
        @note.video_timestamp = format("%02d:%02d", minutes, seconds)
      
        if @note.update(note_params)
          render json: @note, status: :ok
        else
          render json: @note.errors, status: :unprocessable_entity
        end
      end

      # GET /api/notes
      def index
        filter = params[:filter]
      
        if filter == 'my_notes'
          @notes = current_user.notes.order(created_at: :desc).page(params[:page]).per(10)
        elsif filter == 'all_notes'
          @notes = Note.where(is_visible: true).order(created_at: :desc).page(params[:page]).per(10)
        else
          @notes = current_user.notes.order(created_at: :desc).page(params[:page]).per(10)
        end
        render json: @notes
      end

      private

      def set_video
        @video = params[:youtube_video_id] ? YoutubeVideo.find_by(id: params[:youtube_video_id]) : Video.find_by(id: params[:video_id])
      end
      
      def set_note
        @note = Note.find(params[:id])
      end

      def note_params
        params.require(:note).permit(:content, :video_timestamp, :is_visible)
      end
    end
  end
end
