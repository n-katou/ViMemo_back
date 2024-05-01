class ApplicationController < ActionController::API
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

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    payload, = JWT.decode(token, ENV['NEXTAUTH_SECRET'], true, { algorithm: 'HS256' })
    @current_user = User.find(payload['sub']) if payload
  rescue JWT::DecodeError
    render json: { error: 'Invalid token' }, status: :unauthorized
  end
end
