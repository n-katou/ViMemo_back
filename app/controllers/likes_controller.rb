class LikesController < ApplicationController
  before_action :find_likeable

  def create
    @like = @likeable.likes.new(user: current_user)
    if @like.save
      redirect_to @likeable, notice: 'Liked!'
    else
      redirect_to @likeable, alert: 'Unable to like.'
    end
  end

  def destroy
    @like = @likeable.likes.find(params[:id])
    @like.destroy
    redirect_to @likeable, notice: 'Unliked!'
  end

  private

  def find_likeable
    if params[:likeable_type]
      klass = params[:likeable_type].safe_constantize
      @likeable = klass.find_by(id: params[:likeable_id]) if klass
    end
    redirect_to root_path, alert: "Invalid operation." unless @likeable
  end
end
