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

end
