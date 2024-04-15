class VideosController < ApplicationController
  before_action :set_video, only: [:show, :edit, :update, :destroy]

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

  def show
    @video = Video.find(params[:id])
    @likeable = @video
    @user_like = @likeable.likes.find_by(user: current_user)
    @notes = current_user ? @video.notes : @video.notes.where(is_visible: true)
  end

  def new
    @video = Video.new
  end

  def create
    @video = Video.new(video_params)
    @video.user_id = current_user.id
    if @video.save
      redirect_to videos_path, notice: t('videos.video_uploaded_successfully')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @video.update(video_params)
      redirect_to videos_path, notice: t('videos.video_updated_successfully')
    else
      render :edit
    end
  end

  def destroy
    @video.destroy
    redirect_to videos_path, notice: t('videos.video_destroyed_successfully')
  end

  private

  def set_video
    @video = Video.find(params[:id])
  end

  def video_params
    params.require(:video).permit(:title, :description, :duration, :file_path, :is_visible)
  end
end
