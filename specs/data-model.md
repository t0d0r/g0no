# Data model

Schema source of truth: `db/schema.rb`. Migrations live in `db/migrate/`.

## notes

| column | type | notes |
|--------|------|-------|
| title | string, not null, unique | required |
| description | text | |
| visited_on | date | defaults to today |
| active | boolean, default true | kept from 2011, not shown in the UI |
| closed | boolean, default false | kept from 2011, not shown in the UI |
| author | string | display name of the creator (username, else email) |
| updated_from | string | display name of the last editor |
| couchdb_id | string, unique | `_id` of the CouchDB document it was imported from |
| color | string, not null, default "yellow" | one of `Note::COLORS` |
| markdown | boolean, default false | show the description as Markdown (markdown.md) |
| wide | boolean, default false | note window uses the full desk width (features.md) |
| note_attachments_count | integer, default 0 | counter cache for the paperclip badge |
| share_token | string, unique | set while the note is shared (sharing.md) |
| share_password_digest | string | bcrypt hash of the optional share password |
| shared_at | datetime | when the current link was made |

## tags and taggings

`tags.name` is unique. `taggings` joins notes and tags (unique per pair).
`Note#tag_list` reads and writes the tags as one space-separated string.

## finance_entries

Belong to a note. `date` (date), `amount` (decimal 12,2, required, numeric),
`comment`, `author`. Listed newest first. `Note#finance_total` is the sum of
saved entries; it is computed, not stored (CouchDB kept a running total that
could drift).

## note_attachments

Belong to a note. `comment` (string) plus one Active Storage file (`file`,
required). Deleting the record purges the file.

## note_versions

History snapshots; see history.md. `event`, `title`, `description`,
`color`, `author`, `details`, `created_at`; index on `(note_id,
created_at)`. Deleted with the note.

## users

Devise columns (see auth.md) plus `username` (unique, case-insensitive,
validated in the model) and `admin` (boolean, default false; admin.md).

## Mapping from the 2011 CouchDB document

| CouchDB field | new location |
|---------------|--------------|
| `_id` | notes.couchdb_id |
| title, description, active, closed, author, updated_from | same-named notes columns |
| visited_on, created_at, updated_at | parsed into date / datetime columns |
| tags[] | tags + taggings |
| finance[] {date, amount, comment, author, created_at} | finance_entries |
| finance_total | dropped (computed) |
| _attachments{md5: ...} + attachments_nfo{md5: {filename, comment}} | note_attachments + Active Storage |

## Security Note

Uploaded files are stored unscanned in `storage/`. Downloads use
`Content-Disposition: attachment`; only the preview types listed in
features.md are ever sent inline. Share passwords are stored as bcrypt
hashes only.
