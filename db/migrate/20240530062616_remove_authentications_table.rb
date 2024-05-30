class RemoveAuthenticationsTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :authentications do |t|
      t.bigint :user_id
      t.string :provider
      t.string :uid
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index ["user_id"], name: "index_authentications_on_user_id"
    end
  end
end