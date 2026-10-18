require "test_helper"

class CouchdbImporterTest < ActiveSupport::TestCase
  class FakeSource
    def initialize(docs, files = {})
      @docs = docs
      @files = files
    end

    def each_note_doc(&block)
      @docs.each(&block)
    end

    def fetch_attachment(doc_id, name)
      @files.fetch([ doc_id, name ])
    end
  end

  LEGACY_DOC = {
    "_id" => "0f1e2d3c4b5a69788796a5b4c3d2e1f0",
    "couchrest-type" => "Note",
    "title" => "Car",
    "description" => "Service history",
    "tags" => %w[car money],
    "visited_on" => "2011/05/19",
    "active" => true,
    "closed" => false,
    "author" => "admin",
    "updated_from" => "admin",
    "created_at" => "2011/05/19 10:00:00 +0000",
    "updated_at" => "2011/05/20 11:00:00 +0000",
    "finance" => [
      { "date" => "19.05.2011", "amount" => "120,50", "comment" => "oil", "author" => "admin",
        "created_at" => "2011/05/19 10:05:00 +0000" },
      { "date" => "", "amount" => "", "comment" => "empty", "author" => "admin" }
    ],
    "finance_total" => 120.5,
    "attachments_nfo" => { "abc123" => { "filename" => "invoice.txt", "comment" => "May invoice" } },
    "_attachments" => { "abc123" => { "content_type" => "text/plain", "length" => 7, "stub" => true } }
  }.freeze

  test "imports a legacy note with tags, finance entries and attachments" do
    source = FakeSource.new([ LEGACY_DOC ], { [ LEGACY_DOC["_id"], "abc123" ] => "invoice" })
    result = CouchdbImporter.new(source, out: StringIO.new).run

    assert_equal 1, result.imported
    note = Note.find_by!(couchdb_id: LEGACY_DOC["_id"])
    assert_equal "Car", note.title
    assert_equal "car money", note.tag_list
    assert_equal Date.new(2011, 5, 19), note.visited_on
    assert_equal Time.utc(2011, 5, 19, 10), note.created_at

    oil = note.finance_entries.find_by!(comment: "oil")
    assert_equal BigDecimal("120.5"), oil.amount
    assert_equal Date.new(2011, 5, 19), oil.date
    assert_equal 0, note.finance_entries.find_by!(comment: "empty").amount
    assert_equal BigDecimal("120.5"), note.finance_total

    attachment = note.note_attachments.sole
    assert_equal "invoice.txt", attachment.filename.to_s
    assert_equal "May invoice", attachment.comment
    assert_equal "invoice", attachment.file.download
  end

  test "skips documents that were already imported" do
    source = FakeSource.new([ LEGACY_DOC ], { [ LEGACY_DOC["_id"], "abc123" ] => "invoice" })
    CouchdbImporter.new(source, out: StringIO.new).run
    result = CouchdbImporter.new(source, out: StringIO.new).run

    assert_equal 0, result.imported
    assert_equal 1, result.skipped
  end

  test "gives untitled and duplicate titles a unique name" do
    docs = [
      { "_id" => "aaaaaaaa1111", "title" => "" },
      { "_id" => "bbbbbbbb2222", "title" => notes(:groceries).title }
    ]
    CouchdbImporter.new(FakeSource.new(docs), out: StringIO.new).run

    assert Note.exists?(title: "Untitled aaaaaaaa")
    assert Note.exists?(title: "Groceries (bbbbbbbb)")
  end

  test "reports failures and continues" do
    out = StringIO.new
    docs = [ LEGACY_DOC, { "_id" => "cccccccc3333", "title" => "Fine" } ]
    result = CouchdbImporter.new(FakeSource.new(docs), out: out).run

    assert_equal 1, result.failed
    assert_equal 1, result.imported
    assert_match LEGACY_DOC["_id"], out.string
  end
end
