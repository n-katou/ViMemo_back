class VideosController < ApplicationController
  before_action :set_video, only: [:show, :edit, :update, :destroy]

  # GET /up_videos
  def index
    @videos = Video.page(params[:page]).per(10)
    case params[:sort]
    when 'likes_desc'
      @videos = @videos.order(likes_count: :desc)
    when 'notes_desc'
      @videos = @videos.order(notes_count: :desc)
    else
      @videos = @videos.order(created_at: :desc)
    end
  end

  # GET /up_videos/:id
  def show
    @video = Video.find(params[:id])
    @likeable = @video
    @user_like = @likeable.likes.find_by(user: current_user)
    # ログインしているかどうかを確認
    if current_user
      @notes = @video.notes
    else
      @notes = @video.notes.where(is_visible: true)
    end
  end

  # GET /up_videos/new
  def new
    @video = Video.new
  end

  # POST /up_videos
  def create
    @video = Video.new(video_params)
    @video.user_id = current_user.id  # 現在のユーザーのIDを設定
  
    if @video.save
      redirect_to videos_path, notice: 'ビデオのアップロードに成功しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /up_videos/:id/edit
  def edit
  end

  # PATCH/PUT /up_videos/:id
  def update
    if @video.update(video_params)
      redirect_to videos_path, notice: 'Up video was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /up_videos/:id
  def destroy
    @video.destroy
    redirect_to videos_path, notice: 'Up video was successfully destroyed.'
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_video
    @video = Video.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def video_params
    params.require(:video).permit(:title, :description, :duration, :file_path, :is_visible)
  end
end
