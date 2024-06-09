class AddSortOrderToNotes < ActiveRecord::Migration[7.0]
  def change
    add_column :notes, :sort_order, :integer, default: 0, null: false
    add_index :notes, :sort_order
  end
end
