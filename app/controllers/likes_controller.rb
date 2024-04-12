class LikesController < ApplicationController
  before_action :find_likeable

  def create
    @like = @likeable.likes.new(user: current_user)
    respond_to do |format|
      if @like.save
        format.html { redirect_to @likeable, notice: 'Liked!' }
        format.turbo_stream
      else
        format.html { redirect_to @likeable, alert: 'Unable to like.' }
        format.turbo_stream
      end
    end
  end

  def destroy
    @youtube_video = YoutubeVideo.find(params[:youtube_video_id])
    @like = @youtube_video.likes.find(params[:id])
    @like.destroy
    respond_to do |format|
      format.html { redirect_to @likeable, notice: 'Unliked!' }
      format.turbo_stream
    end
  end

  private

  def find_likeable
    if params[:likeable_type] && params[:likeable_id]
      klass = params[:likeable_type].safe_constantize
      @likeable = klass.find_by(id: params[:likeable_id])
    end
  
    unless @likeable
      redirect_to root_path, alert: "Invalid operation."
    end
  end
end
