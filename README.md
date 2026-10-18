# g0No

A small notes application: each note has a title, a description, tags, a list
of expenses (finance entries with a running total) and file attachments.
Users sign in with Devise. The UI is in Bulgarian and English and looks like
macOS Stickies.

Notes can be searched and filtered by colour from the menu bar, recoloured
from a fixed set, shared by link (optionally with a password), and given
files by drag and drop; attachments open in a preview dialog. Every change
is kept in a Time Machine style history from which older versions can be
restored. Administrators
manage users and shared links at `/admin`.

Started in 2011 on Rails 3.0 with CouchDB; migrated in 2026 to Rails 8.1 with
SQLite. The 2011 development notes are in `doc/NOTES-2011.md`.

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

## Security Note

- Never commit `.env`, `config/master.key` or any credential. Production
  needs `SECRET_KEY_BASE` from the environment. `.env` is created with mode
  600 and holds the admin password in plain text; keep it on your machine.
- The 2011 code committed a session secret, a Devise pepper and a default
  admin password to git history. They are no longer used by the code, but
  treat them as public: use a new `SECRET_KEY_BASE`, change the admin
  password, and set `DEVISE_PEPPER` only while old passwords still need it
  (see `specs/auth.md`).
- Anyone can register an account and every signed-in user sees every note.
  Put the app behind a trusted network or disable registration before
  exposing it to the internet.
- Keep `RAILS_FORCE_SSL=true` (the default) whenever the app is reachable
  over a network; the compose file turns it off only for localhost.
