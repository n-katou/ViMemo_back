class Admin::BaseController < ApplicationController
  before_action :authorize_admin_access

  private

  def not_authenticated
    flash[:warning] = t('defaults.flash_message.require_login')
    redirect_to root_path
  end

  def authorize_admin_access
    return if current_user.email == ENV['ADMIN_EMAIL']
    redirect_to root_path, alert: t('authorization.access_denied')
  end
end
