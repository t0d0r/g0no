# Sends note attachments for NotesController (signed-in users) and
# SharedNotesController (people with a share link).
module AttachmentServing
  extend ActiveSupport::Concern

  private

  def send_attachment(attachment)
    send_data attachment.file.download,
              filename: attachment.filename.to_s,
              type: attachment.content_type,
              disposition: "attachment"
  end

  # Inline only for the types in NoteAttachment::PREVIEW_KINDS. Supports one
  # byte range, which Safari needs to play audio and video.
  def send_attachment_preview(attachment)
    kind = attachment.preview_kind
    return head(:not_found) unless kind

    blob = attachment.file.blob
    type = kind == "text" ? "text/plain; charset=utf-8" : blob.content_type
    options = { type: type, disposition: "inline", filename: blob.filename.to_s }

    # Defence in depth if the URL is opened directly. Chrome refuses to show
    # PDFs in a sandbox, so PDFs rely on the allow-list and nosniff only.
    response.headers["Content-Security-Policy"] = "default-src 'none'; sandbox" unless kind == "pdf"
    response.headers["Accept-Ranges"] = "bytes"

    ranges = Rack::Utils.get_byte_ranges(request.headers["Range"], blob.byte_size) if request.headers["Range"].present?
    if ranges&.one?
      range = ranges.first
      response.headers["Content-Range"] = "bytes #{range.begin}-#{range.end}/#{blob.byte_size}"
      send_data blob.download_chunk(range), **options, status: :partial_content
    elsif ranges&.empty?
      response.headers["Content-Range"] = "bytes */#{blob.byte_size}"
      head :range_not_satisfiable
    else
      send_data blob.download, **options
    end
  end
end
