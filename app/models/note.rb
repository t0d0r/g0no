class Note
  include CouchPotato::Persistence
  property :title, :type => String, :default => nil
  property :description, :type => String, :default => nil
  # property :tags, [String], :default => []
  property :visited_on, :type => Time
  property :active, :default => true
  property :closed, :default => false
  # timestamps!  
end
# class Note < CouchRest::Model::Base
#   use_database CouchServer.default_database
#   property :title, String, :default => nil
#   property :description, String, :default => nil
#   # property :tags, [String], :default => []
#   property :visited_on, Time, :default => Time.now.strftime('%Y/%m/%d')
#   property :active, TrueClass, :default => true  # this create note.active? getter 
#   property :closed, TrueClass, :default => false # same as active
#   timestamps!
#   
#   view_by :title
#   view_by :visited_on
#   view_by :visited_on, :title
#   
#   validates_uniqueness_of :title
#   
#   before_update :testme
#   
#   def testme
#     logger.info("test me here!!!!")
#   end
# end