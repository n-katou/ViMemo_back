class ChangeYoutubeVideoIdNotNullOnNotes < ActiveRecord::Migration[7.0]
  def change
    change_column_null :notes, :youtube_video_id, true
  end
end
