class NotesController < ApplicationController
  before_action :set_video, only: [:edit, :update, :destroy, :create]
  before_action :set_youtube_video, only: [:edit, :update, :show]
  before_action :set_note, only: [:update]

  def create
    if @video
      @note = @video.notes.build(note_params)
      @note.user_id = current_user.id
      minutes = params[:video_timestamp_minutes].to_i
      seconds = params[:video_timestamp_seconds].to_i
      @note.video_timestamp = format("%02d:%02d", minutes, seconds)
  
      respond_to do |format|
        if @note.save
          format.turbo_stream { render "create", locals: { note: @note, video: @video } }
          format.html { redirect_to redirect_path, notice: t('notes.created_successfully') }
        else
          format.turbo_stream { render turbo_stream: turbo_stream.replace("errors", partial: "shared/error_messages", locals: { object: @note }) }
          format.html { render 'youtube_videos/show', status: :unprocessable_entity }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("errors", partial: "shared/error_messages", locals: { object: @video, default_message: t('notes.video_not_found') }) }
        format.html { redirect_to youtube_videos_path, alert: t('notes.video_not_found') }
      end
    end
  end

  def destroy
    @note = Note.find(params[:id])
    @note.destroy
  
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to youtube_video_path(@youtube_video), notice: t('notes.destroyed_successfully') }
    end
  end

  def update
    if @note.update(note_params)
      redirect_to youtube_video_path(@note.youtube_video), notice: t('notes.updated_successfully')
    else
      flash.now[:alert] = t('notes.update_failed')
      render :edit
    end
  end

  def edit
    @note = @video.notes.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  private

  def set_video
    @video = params[:youtube_video_id] ? YoutubeVideo.find_by(id: params[:youtube_video_id]) : Video.find_by(id: params[:video_id])
  end
  
  def set_youtube_video
    @youtube_video = YoutubeVideo.find_by(id: params[:youtube_video_id])
  end

  def set_note
    @note = Note.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:content, :video_timestamp, :is_visible)
  end

  def redirect_path
    @video.is_a?(YoutubeVideo) ? youtube_video_path(@video) : video_path(@video)
  end
end
