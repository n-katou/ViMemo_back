class ApplicationController < ActionController::Base
  before_action :require_login, :set_ransack_search_object
  layout 'layouts/application'
  add_flash_types :success, :danger

  private

  def not_authenticated
    redirect_to login_path
  end

  def set_ransack_search_object
    @q = YoutubeVideo.ransack(params[:q])
  end
end
