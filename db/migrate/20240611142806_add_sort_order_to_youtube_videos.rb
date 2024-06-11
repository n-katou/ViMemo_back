class AddSortOrderToYoutubeVideos < ActiveRecord::Migration[7.0]
  def change
    add_column :youtube_videos, :sort_order, :integer, default: 0, null: false
    add_index :youtube_videos, :sort_order
  end
end
