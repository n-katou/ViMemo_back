class NotesController < ApplicationController
  before_action :set_video, only: [:edit, :update, :destroy, :create]

  def create
    @youtube_video = YoutubeVideo.find(params[:youtube_video_id])
    @note = @youtube_video.notes.build(note_params)
    @note.user_id = current_user.id 

    respond_to do |format|
      if @note.save
        format.turbo_stream do
          render "create", locals: { note: @note, youtube_video: @youtube_video }
        end
        format.html { redirect_to youtube_video_path(@youtube_video), notice: 'Note was successfully created.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("errors", partial: "shared/error_messages", locals: { object: @note })
        end
        format.html { render 'youtube_videos/show', status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @note = Note.find(params[:id])
    @youtube_video = @note.youtube_video
    @note.destroy
  
    respond_to do |format|
      format.html { redirect_to youtube_video_path(@youtube_video), notice: 'Note was successfully destroyed.' }
      format.turbo_stream
    end
  end

  def update
    @note = Note.find(params[:id])
    if @note.update(note_params)
      redirect_to youtube_video_path(@note.youtube_video), notice: 'メモが更新されました。'
    else
      # エラー処理
      render :edit
    end
  end

  def edit
    @note = @youtube_video.notes.find(params[:id])
    respond_to do |format|
      format.html 
    end
  end

  private

  def set_video
    @youtube_video = YoutubeVideo.find(params[:youtube_video_id])
  end

  def note_params
    params.require(:note).permit(:content, :video_timestamp, :is_visible)
  end
end
