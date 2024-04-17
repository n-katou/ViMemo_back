class LikesController < ApplicationController
  before_action :find_likeable

  def create
    @like = @likeable.likes.new(user: current_user)
    respond_to do |format|
      if @like.save
        format.html { redirect_to @likeable, notice: t('likes.liked') }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("like_button_#{params[:likeable_id]}",
                                 partial: 'likes/like_button',
                                 locals: { likeable: @likeable }),
            turbo_stream.replace("like_count_#{params[:likeable_id]}",
                                 partial: 'likes/like_count',
                                 locals: { likeable: @likeable })
          ]
        end
      else
        format.html { redirect_to @likeable, alert: t('likes.unable_to_like') }
        format.turbo_stream
      end
    end
  end

  def destroy
    @like = @likeable.likes.find(params[:id])
    @like.destroy
    respond_to do |format|
      format.html { redirect_to @likeable, notice: t('likes.unliked') }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("like_button_#{params[:likeable_id]}",
                               partial: 'likes/like_button',
                               locals: { likeable: @likeable }),
          turbo_stream.replace("like_count_#{params[:likeable_id]}",
                               partial: 'likes/like_count',
                               locals: { likeable: @likeable })
        ]
      end
    end
  end

  private

  def find_likeable
    klass = params[:likeable_type].safe_constantize
    @likeable = klass.find(params[:likeable_id])
    unless @likeable
      redirect_to root_path, alert: t('likes.invalid_operation')
    end
  end
end
