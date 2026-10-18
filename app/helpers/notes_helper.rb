module NotesHelper
  def link_to_attachment(note, attachment)
    link_to attachment.filename.to_s, download_file_note_path(note, attachment_id: attachment)
  end

  def odd_or_even(i)
    i % 2 == 0 ? "even" : "odd"
  end

  def show_finance_total(note)
    if note&.persisted? && note.finance_total > 0
      content_tag :div, class: "big-finance" do
        content_tag(:div, t("expence") + ":", class: "text") +
        content_tag(:div, f_price(note.finance_total), class: "total")
      end
    end
  end

  def show_add_remove_buttons?(controller)
    if controller.controller_name == "notes"
      case controller.action_name
      when "index"
        content_tag(:div, link_to("+", new_note_path), class: "bigplus")
      when "show"
        content_tag(:div, class: "bigplus") do
          button_to "-", note_path(@note), method: :delete,
                    form: { data: { confirm: t("Are You sure?") } }
        end
      end
    end
  end
end
