module NotesHelper

  def couchdb_rev_field(form, record)
    unless record.new_record?
      form.hidden_field("rev")
    end
  end

  def link_to_tags(tags)
    tags.each do |tag|
    
    end
  end

  def link_to_filename(doc, name)
    link_to doc.real_filename(name), note_path(:id => doc, :filename => name)
  end


  def odd_or_even(i)
    i % 2 == 0 ? 'even' : 'odd'
  end

  def show_finance_total(note)
    if note && note.finance_total > 0
      content_tag :div, :class => 'big-finance' do
        content_tag(:div, t("expence") + ':', :class => 'text') + 
        content_tag(:div, f_price(note.finance_total), :class => 'total')
      end
    end
  end

  def show_add_remove_buttons?(controller)
    if controller.controller_name == "notes"
      case controller.action_name
        when "index"
          content_tag(:div, link_to("+", :controller => :notes, :action=> :new ), :class => 'bigplus')
        when "show"
          content_tag(:div, link_to("-", :action=> :destroy ), :class => 'bigplus')
      end
    end
#     content_tag :h1, controller.methods.grep(/name/)
#     content_tag :h1, controller.controller_name
#     content_tag :h1, controller.action_name
  end

end
