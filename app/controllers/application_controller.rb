class ApplicationController < ActionController::Base
  before_action :require_login, :set_ransack_search_object, :validate_session
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

  # セッション検証メソッドを追加
  def validate_session
    # session[:user_id]が存在し、対応するユーザーがデータベースに存在するか確認
    unless session[:user_id] && User.exists?(session[:user_id])
      # セッションが無効な場合、ユーザーをログインページにリダイレクト
      flash[:alert] = "ログインしてください。"
      redirect_to login_path
    end
  end
end
