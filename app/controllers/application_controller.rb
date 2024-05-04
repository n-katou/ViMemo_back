class ApplicationController < ActionController::Base
  before_action :require_login, :set_ransack_search_object
  before_action :prevent_double_login, only: [:login, :login_form]
  layout 'layouts/application'
  add_flash_types :success, :danger

  private

  def not_authenticated
    redirect_to login_path
  end

  def set_ransack_search_object
    @q = YoutubeVideo.ransack(params[:q])
  end

  def prevent_double_login
    if logged_in?
      redirect_to root_path, notice: 'You are already logged in.'
    end
  end
end
