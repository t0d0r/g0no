namespace :couchdb do
  desc "Import notes from the legacy CouchDB database (COUCHDB_URL=http://[user:pass@]host:5984/gono-production)"
  task import: :environment do
    url = ENV["COUCHDB_URL"].presence
    abort "couchdb:import: set COUCHDB_URL to the legacy database URL, e.g. http://127.0.0.1:5984/gono-production" unless url

    result = CouchdbImporter.new(CouchdbImporter::HttpSource.new(url)).run
    puts "couchdb:import: imported #{result.imported}, skipped #{result.skipped} (already imported), failed #{result.failed}"
    exit 1 if result.failed.positive?
  end
end
