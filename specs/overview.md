# Overview

g0No is a personal notes app. A note has a title, a description, tags, a list
of expenses with a total, and file attachments. All signed-in users share all
notes.

## Stack

| part | choice |
|------|--------|
| language | Ruby 4.0 |
| framework | Rails 8.1 |
| database | SQLite (storage/<env>.sqlite3) via Active Record |
| files | Active Storage, Disk service (storage/ in development and production) |
| auth | Devise 5 |
| assets | Propshaft, one plain CSS file and one plain JS file, no build step |
| server | Puma behind Thruster (in the Docker image) |
| tests | Minitest (`make test`) |
| lint | rubocop-rails-omakase and Brakeman (`make lint`) |

## Migration from Rails 3.0 (2026-10-18)

The app was written in 2011 for Rails 3.0.5 with notes in CouchDB through
couchrest_model and users in SQLite. Decisions made while moving to Rails 8.1:

- **CouchDB replaced by SQLite.** couchrest_model is unmaintained; its last
  release fails on Rails 8.1 (stack overflow in ActiveSupport's
  DescendantsTracker as soon as a model declares a validation). The operator
  approved moving to another database. SQLite is the Rails 8 default, needs
  no extra service, and fits a single-server app. Existing data is moved
  with `couchdb:import` (see couchdb-import.md).
- **Attachments use Active Storage** with a `NoteAttachment` model that holds
  the per-file comment. Downloads go through `NotesController#download_file`
  so they require sign-in, as before. Active Storage's own routes are turned
  off (`config.active_storage.draw_routes = false`).
- **No JavaScript framework.** jQuery 1.5, jQuery UI, Prototype, the
  unobtrusive_date_picker plugin and lowpro were replaced by about 100 lines of
  plain JavaScript (`app/assets/javascripts/application.js`) and a native
  `<input type="date">`. Delete buttons are `button_to` forms with a
  `data-confirm` prompt handled by that script.
- **Sass compiled once to CSS.** The committed CSS was a Sass syntax error
  dump (tabs mixed with spaces). The Sass was fixed, compiled once, and is now
  maintained as `app/assets/stylesheets/application.css`.
- **Secrets from the environment.** `secret_token.rb`, the hard-coded Devise
  pepper and the seeded admin password were removed. See auth.md and
  docker.md.
- **Debug leftovers removed:** the index page no longer sets sample flash
  messages, and the edit action no longer references the uninstalled
  MarkItUp editor.
- Unused gems dropped: RedCloth, haml, sass, json, nifty-generators,
  couchrest, couchrest_model.

## Security Note

All signed-in users can read, change and delete every note, and registration
is open. This matches the 2011 behaviour; restrict it before exposing the app
publicly (see todo).
