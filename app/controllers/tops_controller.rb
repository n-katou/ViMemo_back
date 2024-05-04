class TopsController < ApplicationController
  skip_before_action :validate_session, only: [:index, :agreement, :privacy]

  def index; end

  def agreement; end
  def privacy; end
end
