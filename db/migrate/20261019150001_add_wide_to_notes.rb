class AddWideToNotes < ActiveRecord::Migration[8.1]
  def change
    add_column :notes, :wide, :boolean, default: false, null: false
  end
end
