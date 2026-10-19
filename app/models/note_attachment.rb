# A file attached to a note, with an optional comment.
class NoteAttachment < ApplicationRecord
  # Only these types are ever sent inline for the preview; everything else
  # (HTML, SVG, scripts, office files) is download-only, so an uploaded file
  # can never run in the app's origin.
  PREVIEW_KINDS = {
    "image" => %w[image/png image/jpeg image/gif image/webp image/avif image/bmp],
    "pdf" => %w[application/pdf],
    "video" => %w[video/mp4 video/webm video/ogg video/quicktime],
    "audio" => %w[audio/mpeg audio/mp4 audio/ogg audio/wav audio/x-wav audio/webm audio/flac],
    "text" => %w[text/plain text/csv text/markdown text/x-log application/json]
  }.freeze
  TEXT_PREVIEW_LIMIT = 1.megabyte

  belongs_to :note, counter_cache: true
  has_one_attached :file, dependent: :purge

  validates :file, presence: true

  delegate :filename, :byte_size, :content_type, to: :file

  # Files saved together with a new note belong to its "created" entry.
  after_create { NoteVersion.record(note, "file_added", details: filename.to_s) unless note.previously_new_record? }
  after_destroy { NoteVersion.record(note, "file_deleted", details: filename.to_s) unless destroyed_by_association }
  after_commit { note.broadcast_refresh_to_viewers }

  # "image", "pdf", "video", "audio", "text", or nil when there is no preview.
  def preview_kind
    kind = PREVIEW_KINDS.find { |_kind, types| types.include?(content_type) }&.first
    kind unless kind == "text" && byte_size > TEXT_PREVIEW_LIMIT
  end
end
