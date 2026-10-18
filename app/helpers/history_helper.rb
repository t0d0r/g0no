module HistoryHelper
  # Text with deletions and insertions marked, compared with the previous version.
  def diff_html(old_text, new_text)
    return new_text.to_s if old_text.nil?

    safe_join(TextDiff.diff(old_text, new_text).map do |kind, text|
      case kind
      when :del then content_tag(:del, text)
      when :ins then content_tag(:ins, text)
      else text
      end
    end)
  end

  def version_event(version)
    case version.event
    when "restored"
      time = Time.zone.parse(version.details.to_s)
      t("ui.history.events.restored", time: time ? l(time, format: :long) : "?")
    when "file_added", "file_deleted", "expense_added"
      t("ui.history.events.#{version.event}", details: version.details)
    else
      t("ui.history.events.#{version.event}")
    end
  end

  CAPSULE_VISIBLE_DEPTH = 7

  # Position of a card in the stack (application.css); the script updates
  # the same properties when moving through time.
  def capsule_card_attributes(index, selected)
    depth = selected - index
    classes = [ ("is-future" if depth.negative?), ("is-far" if depth > CAPSULE_VISIBLE_DEPTH) ].compact
    { style: "--depth: #{depth}", class: classes }
  end
end
