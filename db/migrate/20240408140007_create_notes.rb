class CreateNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :notes do |t|
      t.text :content
      t.boolean :is_visible, default: true
      t.string :video_timestamp

      t.references :user, null: false, foreign_key: true
      # 後から足す
      # t.references :video, null: false, foreign_key: true
      t.references :youtube_video, null: false, foreign_key: true

      t.timestamps
    end
  end
end
