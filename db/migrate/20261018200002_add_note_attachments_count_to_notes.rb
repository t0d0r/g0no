class AddNoteAttachmentsCountToNotes < ActiveRecord::Migration[8.1]
  def up
    add_column :notes, :note_attachments_count, :integer, default: 0, null: false
    execute <<~SQL
      UPDATE notes SET note_attachments_count =
        (SELECT COUNT(*) FROM note_attachments WHERE note_attachments.note_id = notes.id)
    SQL
  end

  def down
    remove_column :notes, :note_attachments_count
  end
end
