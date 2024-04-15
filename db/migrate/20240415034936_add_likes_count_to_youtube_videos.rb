class AddLikesCountToYoutubeVideos < ActiveRecord::Migration[7.0]
  def change
    add_column :youtube_videos, :likes_count, :integer, default: 0
  end
end
