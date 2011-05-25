require 'md5'
class Note < CouchRest::Model::Base

  use_database CouchServer.default_database

  property :title,        String,     :default => nil
  property :description,  String,     :default => nil
  property :tags ,        [String],   :default => []
  property :visited_on,   Time,       :default => Time.now.strftime('%Y/%m/%d')
  property :active,       TrueClass,  :default => true  # this create note.active? getter 
  property :closed,       TrueClass,  :default => false # same as active
  property :author,       String,     :default => nil 
  property :updated_from, String,     :default => nil 
  property :attachments_nfo, Hash,    :default => {}
  property :finance,      [Hash],     :default => []
  property :finance_total, Float,    :default => 0.0

  timestamps!

#  view_by :all
#  view_by :title
#  view_by :visited_on
#  view_by :visited_on, :title
  view_by :tags,
    :map =>
      "function(doc) {
        if (doc['couchrest-type'] == 'Note' && doc.tags) {
          doc.tags.forEach(function(tag) {
              emit(tag, null);
          });
        }
      }"

  validates_uniqueness_of :title

  def attachments=(attachments)
    attachments.each do |attachment|
      filename_key = attachment_hash(attachment.original_filename)
      self.create_attachment(:file => attachment, :name => filename_key)
      if self.attachments_nfo.has_key?(filename_key)
        self.attachments_nfo[filename_key].merge({ :filename => attachment.original_filename }) 
      else
        self.attachments_nfo[filename_key] = { :filename => attachment.original_filename }
      end
    end
  end
  
  def add_finance=(arg)
    self.finance << { :date => arg[:date], :comment => arg[:comment], :amount => arg[:amount], 
                      :created_at => Time.now, :author => arg[:author] }
    self.finance_total += arg[:amount].to_f
  end

  def self.create(arg)
    arg[:tags] = arg[:tags].split(/\s+/).uniq if arg[:tags].is_a?(String)
    super arg
  end

  def real_filename(key)
    self.attachments_nfo.has_key?(key) ? self.attachments_nfo[key]["filename"] : "UNKNOWN"
  end

  def delete_attachment(arg)
    attachments_nfo.delete(arg) if attachments_nfo.has_key?(arg)
    super arg
  end

  def attach_comments_to_filename(filename, comment)
    key = attachment_hash(filename)
    if attachments_nfo.has_key?(key)
      self.attachments_nfo[key].merge( { :filename => filename, :comment => comment } )
    else
      self.attachments_nfo[key] =  { :filename => filename, :comment => comment } 
    end
  end

  private

  def attachment_hash(name)
    MD5.new(name).hexdigest
  end

end
