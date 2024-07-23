class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[edit update show destroy]

  def index
    @q = YoutubeVideo.ransack(params[:q])
    @videos = @q.result(distinct: true).order(created_at: :desc).page(params[:page])
    @users = User.all.order(id: :asc).page(params[:page]).per(10)
  end

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), success: t('defaults.flash_message.updated', item: User.model_name.human)
    else
      flash.now['danger'] = t('defaults.not_updated', item: User.model_name.human)
      render :edit
    end
  end

  def show; end

  def destroy
    @user = User.find(params[:id])
    @user.likes.destroy_all
    @user.notes.destroy_all
    @user.youtube_videos.destroy_all
    @user.destroy!
    redirect_to admin_users_path, success: t('defaults.flash_message.deleted', item: User.model_name.human), status: :see_other
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :avatar, :role, :is_valid)
  end
end
