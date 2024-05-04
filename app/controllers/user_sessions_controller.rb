class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create, :destroy]
  protect_from_forgery except: :destroy 

  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: { message: "ログインが必要です" } }
    end
  end

  def create
    @user = login(params[:email], params[:password])
    if @user
      redirect_to youtube_videos_path, success: t('user_sessions.create.success')
    else
      flash.now[:danger] = t('user_sessions.create.failure')
      render :new, status: :unprocessable_entity
    end
  end


  def destroy
    logout
    redirect_to root_path, notice: t('user_sessions.destroy.success'), status: :see_other
  end
end
