class SorceryCore < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email,            null: false, index: { unique: true }
      t.string :crypted_password
      t.string :salt
      t.string :name
      t.string :avatar
      t.integer :role
      t.boolean :is_valid, default: true, null: false

      t.timestamps                null: false
    end
  end
end
