class DropUnwantedTables < ActiveRecord::Migration[7.0]
  def up
    drop_table :Account, if_exists: true
    drop_table :Session, if_exists: true
    drop_table :User, if_exists: true
    drop_table :VerificationToken, if_exists: true
    drop_table :_prisma_migrations, if_exists: true
  end

  def down
    # ここでテーブルを再作成する場合、元のスキーマ定義を正確に再現する必要があります。
    # 下記は元のテーブル作成コマンドの一例です。
    create_table "Account", id: :text, force: :cascade do |t|
      t.text "userId", null: false
      t.text "type", null: false
      t.text "provider", null: false
      t.text "providerAccountId", null: false
      t.text "refresh_token"
      t.text "access_token"
      t.integer "expires_at"
      t.text "token_type"
      t.text "scope"
      t.text "id_token"
      t.text "session_state"
      t.index ["provider", "providerAccountId"], name: "Account_provider_providerAccountId_key", unique: true
    end

    create_table "Session", id: :text, force: :cascade do |t|
      t.text "sessionToken", null: false
      t.text "userId", null: false
      t.datetime "expires", precision: 3, null: false
      t.index ["sessionToken"], name: "Session_sessionToken_key", unique: true
    end

    create_table "User", id: :text, force: :cascade do |t|
      t.text "cryptedPassword"
      t.text "name"
      t.text "email"
      t.datetime "emailVerified", precision: 3
      t.text "image"
      t.index ["email"], name: "User_email_key", unique: true
    end

    create_table "VerificationToken", id: false, force: :cascade do |t|
      t.text "identifier", null: false
      t.text "token", null: false
      t.datetime "expires", precision: 3, null: false
      t.index ["identifier", "token"], name: "VerificationToken_identifier_token_key", unique: true
      t.index ["token"], name: "VerificationToken_token_key", unique: true
    end

    create_table "_prisma_migrations", id: { type: :string, limit: 36 }, force: :cascade do |t|
      t.string "checksum", limit: 64, null: false
      t.timestamptz "finished_at"
      t.string "migration_name", limit: 255, null: false
      t.text "logs"
      t.timestamptz "rolled_back_at"
      t.timestamptz "started_at", default: -> { "now()" }, null: false
      t.integer "applied_steps_count", default: 0, null: false
    end
  end
end
