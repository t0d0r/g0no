require 'couchrest/model'
COUCHDB = YAML::load(ERB.new(IO.read("#{Rails.root.to_s}/config/couchdb.yml")).result)[Rails.env]
#YAML::load(ERB.new(IO.read(xmlrpc_configuration_file)).result) [ENV['G00NET_ENV']]
CouchServer = CouchRest::Server.new "http://#{COUCHDB['server']}"
if COUCHDB["required_authentination"]
  CouchServer = CouchRest::Server.new "http://#{COUCHDB['username']}:#{COUCHDB['password']}@#{COUCHDB['server']}"
else
  CouchServer = CouchRest::Server.new "http://#{COUCHDB['server']}"
end

CouchServer.default_database = "gono-#{Rails.env}"
