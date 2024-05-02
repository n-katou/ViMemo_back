require 'jwt'

class ApplicationController < ActionController::Base
  before_action :require_login, :set_ransack_search_object
  layout 'layouts/application'
  add_flash_types :success, :danger

  protected

  def require_login
    return if current_user

    authenticate_token || not_authenticated
  end

  def current_user
    @current_user ||= authenticate_token
  end

  private

  def authenticate_token
    token = request.headers['Authorization']&.split(' ')&.last
    return nil unless token

    begin
      decoded_token = JWT.decode(token, ENV['NEXTAUTH_SECRET'], true, { algorithm: 'HS256' })
      User.find(decoded_token[0]['userId'])  # userIDはトークンに保存されているユーザーIDフィールドに応じて変更
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      nil
    end
  end

  def not_authenticated
    redirect_to login_path
  end

  def set_ransack_search_object
    @q = YoutubeVideo.ransack(params[:q])
  end
end
