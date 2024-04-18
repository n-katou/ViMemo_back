class AddLikesCountToNotes < ActiveRecord::Migration[7.0]
  def change
    add_column :notes, :likes_count, :integer, default: 0
  end
end
