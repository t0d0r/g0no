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
  timestamps!

  view_by :all
  view_by :title
  view_by :visited_on
  view_by :visited_on, :title
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
      self.create_attachment(:file => attachment, :name => attachment.original_filename)
    end
  end

  def self.create(arg)
    arg[:tags] = arg[:tags].split(/\s+/) if arg[:tags].is_a?(String)
    super arg
  end

end
