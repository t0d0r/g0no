# One entry in a note's history: what the note looked like after a change.
class NoteVersion < ApplicationRecord
  EVENTS = %w[baseline created edited recolored restored file_added file_deleted expense_added].freeze

  belongs_to :note

  validates :event, inclusion: { in: EVENTS }

  def self.record(note, event, details: nil)
    note.versions.create!(
      event: event,
      details: details,
      title: note.title,
      description: note.description,
      color: note.color,
      author: Current.user&.display_name || note.updated_from || note.author,
      # An imported note keeps its original creation time.
      created_at: event == "created" ? (note.created_at || Time.current) : Time.current
    )
  end

  # True when restoring this version would change the note.
  def differs_from?(note)
    [ title, description.to_s, color ] != [ note.title, note.description.to_s, note.color ]
  end
end
