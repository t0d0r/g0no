# g0No

A small notes application: each note has a title, a description, tags, a list
of expenses (finance entries with a running total) and file attachments.
Users sign in with Devise. The UI is in Bulgarian and English and looks like
macOS Stickies; Turbo Drive makes page changes feel like a single-page app.

Started in 2011 on Rails 3.0 with CouchDB; migrated in 2026 to Rails 8.1 with
SQLite. The 2011 development notes are in `doc/NOTES-2011.md`.

## Screenshots

The board of notes, newest edits first:

![Board of sticky notes in six colours](doc/screenshots/board.png)

A Markdown note with a task list, opened locked for reading:

![Note window with a task list, expenses, files and sharing](doc/screenshots/note.png)

## Features

- **Notes board** - cards with title, start of the text, age, author, file
  count, share icon and expense total. Sort by created or edited time,
  newest or oldest first; cards glide to their new place.
- **Search and filter** - search title and description from the board
  header, filter by paper colour, or list the notes with one tag.
- **Autosave** - no Save button: a note saves itself shortly after typing
  stops, on focus out and when the page is left. A status line shows when
  it was saved.
- **Locked notes** - a saved note opens read-only; double-click (or the
  padlock) to edit, with the caret where you clicked.
- **Colours** - six paper colours (yellow, blue, green, pink, purple, gray)
  and a dice button for a random one.
- **Markdown** - per-note switch for formatted view, with clickable task
  lists.
- **Wide notes** - a zoom box widens a note window to the full desk.
- **Tags** - space-separated tags on each note.
- **Expenses** - a list of finance entries per note with a running total.
- **Attachments** - upload by form or drag and drop; preview images, PDFs,
  video, audio and text in a dialog with previous/next.
- **History** - every change to title, text or colour is kept in a Time
  Machine style view; any older version can be restored.
- **Sharing** - public read-only link per note, optionally with a password;
  sharing again replaces the old link.
- **Live updates** - an open note or share page reloads itself when the
  note changes elsewhere (Action Cable); it waits while you are editing.
- **Admin panel** - at `/admin`: manage users, see stats and all shared
  links.
- **Look and feel** - macOS Stickies style, light and dark theme, three
  text sizes, Bulgarian and English UI, Turbo Drive page changes.
- **Confirmations** - deleting a note, file, share link or user asks in a
  dialog that names what will be lost.

## Requirements

- Ruby 4.0 (see `.ruby-version`) and Bundler, or
- Docker with the compose plugin

## Run locally

```sh
make run            # http://localhost:3000
```

`make run` installs gems, prepares `storage/development.sqlite3`, creates
`.env` with a random `ADMIN_PASSWORD` on first use (`bin/setup-env`), and
creates the user `admin` from it when that user does not exist. Sign in with
`admin` (or the email in `ADMIN_EMAIL`) and the password from `.env`.

## Run with Docker

```sh
make docker-up          # http://localhost:3000 (creates .env like make run)
make docker-logs
make docker-down
```

Databases and uploaded files live in the `storage` volume. See
`specs/docker.md`.

## Import from the old CouchDB

```sh
COUCHDB_URL=http://user:pass@127.0.0.1:5984/gono-production make import
# or, inside Docker, with COUCHDB_URL in .env:
make docker-import
```

The import can be re-run; notes already imported are skipped. See
`specs/couchdb-import.md`.

## Development

```sh
make help     # all targets
make check    # rubocop, brakeman and the test suite; must pass before a commit
make audit    # known-vulnerability check for gems
```

