class CreateVideos < ActiveRecord::Migration[7.0]
  def change
    create_table :videos do |t|
      t.string :title
      t.text :description
      t.integer :duration
      t.string :file_path
      t.boolean :is_visible, default: true

      t.timestamps
      t.references :user, null: false, foreign_key: true
    end
  end
end
