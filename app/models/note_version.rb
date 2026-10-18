# One entry in a note's history: what the note looked like after a change.
class NoteVersion < ApplicationRecord
  EVENTS = %w[baseline created edited recolored restored file_added file_deleted expense_added].freeze

  belongs_to :note

  validates :event, inclusion: { in: EVENTS }

  # Automatic saves while someone types are merged into one "edited" entry
  # per author, as long as the edits are less than this far apart.
  EDIT_SESSION = 10.minutes

  def self.record(note, event, details: nil)
    author = Current.user&.display_name || note.updated_from || note.author
    last = note.versions.reorder(:created_at, :id).last
    if event == "edited" && last&.event == "edited" && last.author == author && last.created_at > EDIT_SESSION.ago
      return last.tap do |version|
        version.update!(title: note.title, description: note.description, color: note.color, created_at: Time.current)
      end
    end

    note.versions.create!(
      event: event,
      details: details,
      title: note.title,
      description: note.description,
      color: note.color,
      author: author,
      # An imported note keeps its original creation time.
      created_at: event == "created" ? (note.created_at || Time.current) : Time.current
    )
  end

  # True when restoring this version would change the note.
  def differs_from?(note)
    [ title, description.to_s, color ] != [ note.title, note.description.to_s, note.color ]
  end
end
