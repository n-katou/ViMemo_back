class TopsController < ApplicationController
  skip_before_action :require_login, only: [:index, :agreement, :privacy]

  def index; end

  def agreement; end
  def privacy; end
end
