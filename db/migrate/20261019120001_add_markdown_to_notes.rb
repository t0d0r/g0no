class AddMarkdownToNotes < ActiveRecord::Migration[8.1]
  def change
    add_column :notes, :markdown, :boolean, default: false, null: false
  end
end
