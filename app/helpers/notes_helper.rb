module NotesHelper
  STICKY_COLORS = Note::COLORS

  def sticky_color(note)
    note.color.presence_in(STICKY_COLORS) || "yellow"
  end

  def link_to_attachment(note, attachment)
    link_to attachment.filename.to_s, download_file_note_path(note, attachment_id: attachment)
  end

  # A file name that opens the preview dialog (see application.js). Without
  # JavaScript the link downloads the file.
  def attachment_preview_link(attachment, download_url:, preview_url:)
    details = [ number_to_human_size(attachment.byte_size), attachment.comment.presence ].compact.join(" - ")
    link_to attachment.filename.to_s, download_url,
            class: "file-link",
            data: { preview_item: true, preview_kind: attachment.preview_kind || "none",
                    preview_url: (preview_url if attachment.preview_kind),
                    filename: attachment.filename.to_s, details: details }
  end

  # Small inline SVG icons, so the app ships no image or icon font.
  ICONS = {
    clip: '<path d="M10.5 4.5 5.4 9.6a1.8 1.8 0 0 0 2.5 2.5l5.6-5.6a3 3 0 0 0-4.2-4.2L3.6 8a4.2 4.2 0 0 0 6 6l4.4-4.4" />',
    link: '<path d="M7 9.5a2.8 2.8 0 0 0 4 0l2.4-2.4a2.8 2.8 0 0 0-4-4L8.2 4.3" /><path d="M9 6.5a2.8 2.8 0 0 0-4 0L2.6 8.9a2.8 2.8 0 0 0 4 4l1.2-1.2" />',
    lock: '<rect x="3.5" y="7" width="9" height="6.5" rx="1.2" /><path d="M5.5 7V5a2.5 2.5 0 0 1 5 0v2" />',
    search: '<circle cx="7" cy="7" r="4.2" /><path d="m10.2 10.2 3.3 3.3" />',
    clock: '<circle cx="8" cy="8" r="6" /><path d="M8 4.6V8l2.4 1.6" />',
    dice: '<rect x="2" y="2" width="12" height="12" rx="3" /><g fill="currentColor" stroke="none">' \
          '<circle cx="5.5" cy="5.5" r="1.2" /><circle cx="10.5" cy="5.5" r="1.2" /><circle cx="8" cy="8" r="1.2" />' \
          '<circle cx="5.5" cy="10.5" r="1.2" /><circle cx="10.5" cy="10.5" r="1.2" /></g>',
    up: '<path d="m4 10 4-4 4 4" />',
    down: '<path d="m4 6 4 4 4-4" />'
  }.freeze

  def icon(name, label: nil, size: 14)
    attributes = label ? { role: "img", "aria-label": label } : { "aria-hidden": "true" }
    content_tag(:svg, ICONS.fetch(name).html_safe, class: "icon", viewBox: "0 0 16 16", width: size, height: size,
                fill: "none", stroke: "currentColor", "stroke-width": 1.5, "stroke-linecap": "round",
                "stroke-linejoin": "round", **attributes)
  end
end
