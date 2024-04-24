class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  before_action :set_user, only: %i[update]
  before_action :set_current_user, only: %i[edit mypage]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to root_path, success: t('users.create.success')
    else
      flash.now[:danger] = t('users.create.failure')
      render :new, status: :unprocessable_entity
    end
  end

  def mypage
    @user = current_user
    @youtube_video_likes = @user.likes.includes(:likeable).where(likeable_type: 'YoutubeVideo').order(created_at: :desc)
    youtube_video_ids = @youtube_video_likes.map { |like| like.likeable.youtube_id }
    @youtube_playlist_url = "https://www.youtube.com/embed?playlist=#{youtube_video_ids.join(',')}&loop=1"

    @note_likes = @user.likes.includes(:likeable).where(likeable_type: 'Note').order(created_at: :desc).limit(6)
  end

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to users_mypage_path
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :avatar)
  end

  def set_user
    @user = User.find(params[:id])
  end

  def set_current_user
    @user = current_user
  end
end
