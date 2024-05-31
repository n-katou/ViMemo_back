class AddFetchCountToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_video_fetch_date, :date
    add_column :users, :video_fetch_count, :integer, default: 0
  end
end
