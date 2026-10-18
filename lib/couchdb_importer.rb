require "net/http"
require "json"

# Copies notes from the legacy CouchDB database (the 2011 couchrest_model
# version of the app) into the ActiveRecord tables. See specs/couchdb-import.md.
#
# The importer is idempotent: a document whose _id is already stored in
# notes.couchdb_id is skipped, so it can be re-run after a partial failure.
class CouchdbImporter
  Result = Struct.new(:imported, :skipped, :failed, keyword_init: true)

  # Reads documents and attachments over CouchDB's HTTP API.
  class HttpSource
    PAGE_SIZE = 200

    # url: database URL, for example http://user:secret@127.0.0.1:5984/gono-production
    def initialize(url)
      @uri = URI(url.chomp("/"))
    end

    def each_note_doc
      start_key = nil
      loop do
        params = { include_docs: "true", limit: PAGE_SIZE + 1 }
        params[:startkey] = start_key.to_json if start_key
        rows = get_json("_all_docs", params).fetch("rows")
        rows.first(PAGE_SIZE).each do |row|
          doc = row["doc"]
          yield doc if doc && note?(doc)
        end
        break if rows.size <= PAGE_SIZE
        start_key = rows.last["id"]
      end
    end

    def fetch_attachment(doc_id, name)
      get("#{escape(doc_id)}/#{escape(name)}")
    end

    private

    def note?(doc)
      doc["couchrest-type"] == "Note" || doc["type"] == "Note"
    end

    def get_json(path, params = {})
      JSON.parse(get(path, params))
    end

    def get(path, params = {})
      uri = @uri.dup
      uri.path = "#{@uri.path}/#{path}"
      uri.query = URI.encode_www_form(params) if params.any?
      uri.user = uri.password = nil

      request = Net::HTTP::Get.new(uri)
      if @uri.user
        request.basic_auth(URI.decode_www_form_component(@uri.user),
                           URI.decode_www_form_component(@uri.password.to_s))
      end
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
      raise "CouchDB GET #{uri.path} failed: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def escape(segment)
      URI.encode_www_form_component(segment).gsub("+", "%20")
    end
  end

  attr_reader :result

  # source: responds to #each_note_doc and #fetch_attachment(doc_id, name)
  def initialize(source, out: $stdout)
    @source = source
    @out = out
    @result = Result.new(imported: 0, skipped: 0, failed: 0)
  end

  def run
    @source.each_note_doc { |doc| import(doc) }
    result
  end

  private

  def import(doc)
    if Note.exists?(couchdb_id: doc["_id"])
      result.skipped += 1
      return
    end

    build_note(doc).save!
    result.imported += 1
  rescue StandardError => e
    result.failed += 1
    @out.puts "failed #{doc["_id"]}: #{e.class}: #{e.message}"
  end

  def build_note(doc)
    note = Note.new(
      couchdb_id: doc["_id"],
      title: unique_title(doc),
      description: doc["description"],
      visited_on: parse_date(doc["visited_on"]),
      active: doc.fetch("active", true) != false,
      closed: doc.fetch("closed", false) == true,
      author: doc["author"],
      updated_from: doc["updated_from"],
      created_at: parse_time(doc["created_at"]),
      updated_at: parse_time(doc["updated_at"])
    )
    note.tag_list = Array(doc["tags"]).join(" ")

    Array(doc["finance"]).each do |entry|
      note.finance_entries.build(
        date: parse_date(entry["date"]),
        amount: parse_amount(entry["amount"]),
        comment: entry["comment"],
        author: entry["author"],
        created_at: parse_time(entry["created_at"])
      )
    end

    info = doc["attachments_nfo"] || {}
    (doc["_attachments"] || {}).each do |key, meta|
      details = info[key] || {}
      attachment = note.note_attachments.build(comment: details["comment"])
      attachment.file.attach(
        io: StringIO.new(@source.fetch_attachment(doc["_id"], key)),
        filename: details["filename"].presence || key,
        content_type: meta["content_type"]
      )
    end

    note
  end

  # Titles are unique in the new schema. Old documents could have none.
  def unique_title(doc)
    short_id = doc["_id"].to_s.first(8)
    title = doc["title"].to_s.strip.presence || "Untitled #{short_id}"
    Note.exists?(title: title) ? "#{title} (#{short_id})" : title
  end

  def parse_date(value)
    Date.parse(value.to_s) if value.present?
  rescue Date::Error
    nil
  end

  def parse_time(value)
    Time.zone.parse(value.to_s) if value.present?
  rescue ArgumentError
    nil
  end

  # Amounts were stored as whatever the user typed, and summed with to_f.
  def parse_amount(value)
    BigDecimal(value.to_s.strip.tr(",", "."))
  rescue ArgumentError, TypeError
    BigDecimal("0")
  end
end
