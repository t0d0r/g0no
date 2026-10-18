module NotesHelper
  STICKY_COLORS = Note::COLORS

  def sticky_color(note)
    note.color.presence_in(STICKY_COLORS) || "yellow"
  end

  def link_to_attachment(note, attachment)
    link_to attachment.filename.to_s, download_file_note_path(note, attachment_id: attachment), data: { turbo: false }
  end

  # A file name that opens the preview dialog (see application.js). Without
  # JavaScript the link downloads the file.
  def attachment_preview_link(attachment, download_url:, preview_url:)
    details = [ number_to_human_size(attachment.byte_size), attachment.comment.presence ].compact.join(" - ")
    # data-turbo=false: a file download is not a page Turbo can show.
    link_to attachment.filename.to_s, download_url,
            class: "file-link",
            data: { turbo: false, preview_item: true, preview_kind: attachment.preview_kind || "none",
                    preview_url: (preview_url if attachment.preview_kind),
                    filename: attachment.filename.to_s, details: details }
  end

  # Title-strip box that copies the note's text; shown by application.js.
  def copy_note_box(text_selector:, title_selector:)
    content_tag(:button, type: "button", class: "sticky__box sticky__box--icon copy-note", hidden: true,
                title: t("ui.copy_note.label"), aria: { label: t("ui.copy_note.label") },
                data: { copy_note: true, copy_text: text_selector, copy_title: title_selector,
                        label: t("ui.copy_note.label"), copied: t("ui.copy_note.copied") }) do
      icon(:copy, size: 10) + content_tag(:span, icon(:check, size: 10), class: "copy-note__done")
    end
  end

  # Small inline SVG icons, so the app ships no image or icon font.
  ICONS = {
    clip: '<path d="M10.5 4.5 5.4 9.6a1.8 1.8 0 0 0 2.5 2.5l5.6-5.6a3 3 0 0 0-4.2-4.2L3.6 8a4.2 4.2 0 0 0 6 6l4.4-4.4" />',
    link: '<path d="M7 9.5a2.8 2.8 0 0 0 4 0l2.4-2.4a2.8 2.8 0 0 0-4-4L8.2 4.3" /><path d="M9 6.5a2.8 2.8 0 0 0-4 0L2.6 8.9a2.8 2.8 0 0 0 4 4l1.2-1.2" />',
    lock: '<rect x="3.5" y="7" width="9" height="6.5" rx="1.2" /><path d="M5.5 7V5a2.5 2.5 0 0 1 5 0v2" />',
    unlock: '<rect x="3.5" y="7" width="9" height="6.5" rx="1.2" /><path d="M5.5 7V5a2.5 2.5 0 0 1 4.9-.7" />',
    search: '<circle cx="7" cy="7" r="4.2" /><path d="m10.2 10.2 3.3 3.3" />',
    clock: '<circle cx="8" cy="8" r="6" /><path d="M8 4.6V8l2.4 1.6" />',
    dice: '<rect x="2" y="2" width="12" height="12" rx="3" /><g fill="currentColor" stroke="none">' \
          '<circle cx="5.5" cy="5.5" r="1.2" /><circle cx="10.5" cy="5.5" r="1.2" /><circle cx="8" cy="8" r="1.2" />' \
          '<circle cx="5.5" cy="10.5" r="1.2" /><circle cx="10.5" cy="10.5" r="1.2" /></g>',
    sun: '<circle cx="8" cy="8" r="2.8" /><path d="M8 1.5v1.6M8 12.9v1.6M1.5 8h1.6M12.9 8h1.6' \
         'M3.4 3.4l1.1 1.1M11.5 11.5l1.1 1.1M3.4 12.6l1.1-1.1M11.5 4.5l1.1-1.1" />',
    moon: '<path d="M13.2 9.6A5.6 5.6 0 0 1 6.4 2.8a5.6 5.6 0 1 0 6.8 6.8z" />',
    copy: '<rect x="5.5" y="5.5" width="8" height="8" rx="1.5" />' \
          '<path d="M10.5 3.5V3A1.5 1.5 0 0 0 9 1.5H4A1.5 1.5 0 0 0 2.5 3v5A1.5 1.5 0 0 0 4 9.5h.5" />',
    check: '<path d="m3.5 8.5 3 3 6-7" />',
    markdown: '<rect x="1" y="3.5" width="14" height="9" rx="1.5" />' \
              '<path d="M3.5 10V6l2 2.3L7.5 6v4M11.5 6v4M10 8.6l1.5 1.5 1.5-1.5" />',
    sort: '<path d="M5 3v10M2.5 10.5 5 13l2.5-2.5M11 13V3M8.5 5.5 11 3l2.5 2.5" />',
    widen: '<path d="M9.5 2.5h4v4M13.5 2.5 9.2 6.8M6.5 13.5h-4v-4M2.5 13.5l4.3-4.3" />',
    narrow: '<path d="M13.5 2.5 9.2 6.8M9.2 3.3v3.5h3.5M2.5 13.5l4.3-4.3M6.8 12.7V9.2H3.3" />',
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
