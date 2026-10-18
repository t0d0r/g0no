# Snapshots of a note's title, description and colour after every change,
# plus file and expense events, for the history ("time capsule") view.
class CreateNoteVersions < ActiveRecord::Migration[8.1]
  def up
    create_table :note_versions do |t|
      t.references :note, null: false, foreign_key: true, index: false
      t.string :event, null: false
      t.string :title, null: false
      t.text :description
      t.string :color, null: false
      t.string :author
      t.string :details
      t.datetime :created_at, null: false
    end
    add_index :note_versions, %i[note_id created_at]

    # Notes that exist before history starts get one "baseline" snapshot.
    execute <<~SQL
      INSERT INTO note_versions (note_id, event, title, description, color, author, created_at)
      SELECT id, 'baseline', title, description, color, COALESCE(updated_from, author), updated_at FROM notes
    SQL
  end

  def down
    drop_table :note_versions
  end
end
