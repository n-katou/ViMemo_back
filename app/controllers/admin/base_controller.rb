class Admin::BaseController < ApplicationController
  before_action :authorize_admin_access

  private

  def not_authenticated
    flash[:warning] = t('defaults.flash_message.require_login')
    redirect_to admin_login_path
  end

  def authorize_admin_access
    return if current_user.email == 'naoto.light@gmail.com' || current_user.role == 'admin'
    redirect_to root_path, alert: 'You are not authorized to access this page.'
  end
end
