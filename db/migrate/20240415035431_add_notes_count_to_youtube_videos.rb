class AddNotesCountToYoutubeVideos < ActiveRecord::Migration[7.0]
  def change
    add_column :youtube_videos, :notes_count, :integer, default: 0
  end
end
