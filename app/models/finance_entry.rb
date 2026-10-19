class FinanceEntry < ApplicationRecord
  belongs_to :note

  attribute :date, :date, default: -> { Date.current }

  validates :amount, numericality: true

  after_create do
    unless note.previously_new_record?
      NoteVersion.record(note, "expense_added", details: [ format("%.2f", amount), comment.presence ].compact.join(" - "))
    end
  end

  after_commit { note.broadcast_refresh_to_viewers }
end
