class VideosController < ApplicationController
  before_action :set_video, only: [:show, :edit, :update, :destroy]

  def index
    @q = Video.ransack(params[:q])
    @videos = @q.result(distinct: true).includes(:notes)

    # ソート条件を設定
    @videos = case params[:sort]
              when 'likes_desc'
                @videos.order(likes_count: :desc)
              when 'notes_desc'
                @videos.order(notes_count: :desc)
              else
                @videos.order(created_at: :desc) # デフォルトで新しい投稿順
              end

    # ページネーションを追加
    @videos = @videos.page(params[:page])

    # 安全にパラメータをフィルタリング
    @filtered_q_params = params[:q]&.permit(:notes_content_cont)
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
