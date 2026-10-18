# A file attached to a note, with an optional comment.
class NoteAttachment < ApplicationRecord
  belongs_to :note
  has_one_attached :file, dependent: :purge

  validates :file, presence: true

  delegate :filename, :byte_size, :content_type, to: :file
end
