class AddNotesCountToVideos < ActiveRecord::Migration[7.0]
  def change
    add_column :videos, :notes_count, :integer, default: 0
  end
end
