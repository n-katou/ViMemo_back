class NotesController < ApplicationController
  before_action :set_video, only: [:edit, :update, :destroy, :create]

  def create
    if params[:youtube_video_id]
      @video = YoutubeVideo.find_by(id: params[:youtube_video_id])
    elsif params[:video_id]
      @video = Video.find_by(id: params[:video_id])
    end
  
    if @video
      @note = @video.notes.build(note_params)
      @note.user_id = current_user.id
      # フォームから送信された値を取得してタイムスタンプを計算
      minutes = params[:video_timestamp_minutes].to_i
      seconds = params[:video_timestamp_seconds].to_i
      @note.video_timestamp = format("%02d:%02d", minutes, seconds)

      respond_to do |format|
        if @note.save
          format.turbo_stream do
            render "create", locals: { note: @note, video: @video }
          end
          format.html { redirect_to redirect_path, notice: 'Note was successfully created.' }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("errors", partial: "shared/error_messages", locals: { object: @note })
          end
          format.html { render 'videos/show', status: :unprocessable_entity }
        end
      end
    else
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("errors", partial: "shared/error_messages", locals: { object: @note })
      end
      format.html { render 'youtube_videos/show', status: :unprocessable_entity }
    end
  end

  def destroy
    @note = Note.find(params[:id])
    @youtube_video = @note.youtube_video
    @note.destroy
  
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to youtube_video_path(@youtube_video), notice: 'Note was successfully destroyed.' }
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
    @note = @video.notes.find(params[:id])
    respond_to do |format|
      format.html 
    end
  end

  private

  def set_video
    if params[:youtube_video_id]
      @video = @youtube_video = YoutubeVideo.find_by(id: params[:youtube_video_id])
    elsif params[:video_id]
      @video = Video.find_by(id: params[:video_id])
    end
  end

  def note_params
    params.require(:note).permit(:content, :video_timestamp, :is_visible)
  end

  def redirect_path
    @video.is_a?(YoutubeVideo) ? youtube_video_path(@video) : video_path(@video)
  end
end
