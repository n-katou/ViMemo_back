class ApplicationController < ActionController::Base
  before_action :set_ransack_search_object, :validate_session
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
    Rails.logger.debug "Checking session: #{session.to_hash.inspect}"  # セッションの状態をログ出力

    unless session[:user_id] && User.exists?(session[:user_id])
      Rails.logger.debug "Invalid session. Redirecting to login page."  # セッションが無効であることをログに記録
      flash[:alert] = "ログインしてください。"
      redirect_to login_path
    else
      Rails.logger.debug "Valid session for user_id: #{session[:user_id]}"  # 有効なセッションであることをログに記録
    end
  end
end
