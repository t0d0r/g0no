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
