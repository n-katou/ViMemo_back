class CreateYoutubeVideos < ActiveRecord::Migration[7.0]
  def change
    create_table :youtube_videos do |t|
      t.string :youtube_id
      t.string :title
      t.text :description
      t.string :video_id
      t.datetime :published_at
      t.integer :duration

      t.timestamps

      t.references :user, null: false, foreign_key: true
    end
  end
end
