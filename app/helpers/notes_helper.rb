module NotesHelper
  STICKY_COLORS = %w[yellow blue green pink purple gray].freeze

  # Each note keeps the same paper colour; new notes start yellow like Stickies.
  def sticky_color(note)
    note.persisted? ? STICKY_COLORS[note.id % STICKY_COLORS.size] : "yellow"
  end

  def link_to_attachment(note, attachment)
    link_to attachment.filename.to_s, download_file_note_path(note, attachment_id: attachment)
  end
end
