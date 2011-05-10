require 'couchrest/model'
#CouchServer = CouchRest::Server.new "http://admin:alabala@127.0.0.1:5984"# defaults to localhost:5984
CouchServer = CouchRest::Server.new "http://127.0.0.1:5984"# defaults to localhost:5984
CouchServer.default_database = "gono-#{Rails.env}"
