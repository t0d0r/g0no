# CouchDB import

`bin/rails couchdb:import` (or `make import`, `make docker-import`) copies the
notes from the 2011 CouchDB database into SQLite. Code:
`lib/couchdb_importer.rb`, task `lib/tasks/couchdb.rake`.

## Input

`COUCHDB_URL` - the database URL, e.g.
`http://user:password@host:5984/gono-production`. The 2011 app named the
database `gono-<environment>`. Without `COUCHDB_URL` the task exits with an
error message.

## Behaviour

- Reads `_all_docs?include_docs=true` in pages of 200 and imports documents
  with `couchrest-type` (or `type`) equal to `Note`.
- Field mapping: see data-model.md.
- Skips a document whose `_id` is already in `notes.couchdb_id`, so the task
  can be re-run.
- Blank titles become `Untitled <first 8 chars of _id>`; a title that is
  already taken gets ` (<first 8 chars of _id>)` appended.
- Amounts accept `,` or `.` as the decimal separator; unparseable amounts
  become 0 (the 2011 app summed them with `to_f`).
- Dates that cannot be parsed become empty.
- Each note is saved with its tags, entries and attachments in one step; a
  failing document is reported with its `_id` and the import continues.
- Prints `imported N, skipped N, failed N` and exits 1 if any failed.

## Verified

Tests use a fake source (`test/lib/couchdb_importer_test.rb`). On 2026-10-18
the task was also run inside the Docker image against a CouchDB 3 container
holding a document in the 2011 format (Cyrillic title and file name, a
finance entry with a comma decimal, one attachment): import, re-import skip
and authenticated download all worked.

## Security Note

`COUCHDB_URL` may contain a password: pass it through the environment or
`.env`, never on a shared command line history or in a committed file. The
task never prints the URL.
