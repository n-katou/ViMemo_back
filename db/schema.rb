# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_06_11_142806) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "likeable_type", null: false
    t.bigint "likeable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "content"
    t.boolean "is_visible", default: true
    t.string "video_timestamp"
    t.bigint "user_id", null: false
    t.bigint "youtube_video_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "video_id"
    t.integer "likes_count", default: 0
    t.integer "sort_order", default: 0, null: false
    t.index ["sort_order"], name: "index_notes_on_sort_order"
    t.index ["user_id"], name: "index_notes_on_user_id"
    t.index ["video_id"], name: "index_notes_on_video_id"
    t.index ["youtube_video_id"], name: "index_notes_on_youtube_video_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.string "name"
    t.string "avatar"
    t.integer "role", default: 0
    t.boolean "is_valid", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.integer "access_count_to_reset_password_page", default: 0
    t.date "last_video_fetch_date"
    t.integer "video_fetch_count", default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token"
  end

  create_table "videos", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "duration"
    t.string "file_path"
    t.boolean "is_visible", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "likes_count", default: 0
    t.integer "notes_count", default: 0
    t.index ["user_id"], name: "index_videos_on_user_id"
  end

  create_table "youtube_videos", force: :cascade do |t|
    t.string "youtube_id"
    t.string "title"
    t.text "description"
    t.string "video_id"
    t.datetime "published_at"
    t.integer "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "likes_count", default: 0
    t.integer "notes_count", default: 0
    t.integer "sort_order", default: 0, null: false
    t.index ["sort_order"], name: "index_youtube_videos_on_sort_order"
    t.index ["user_id"], name: "index_youtube_videos_on_user_id"
  end

  add_foreign_key "likes", "users"
  add_foreign_key "notes", "users"
  add_foreign_key "notes", "videos"
  add_foreign_key "notes", "youtube_videos"
  add_foreign_key "videos", "users"
  add_foreign_key "youtube_videos", "users"
end
