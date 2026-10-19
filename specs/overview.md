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
- **Turbo Drive** (added 2026-10-19 at the operator's request: "add turbo
  drive"). The `turbo-rails` gem serves `turbo.min.js` through Propshaft (no
  build step, no importmap); link clicks and form submits swap the page
  body instead of reloading it. No Frames and no Stimulus; the only stream
  action is "refresh" for live updates (added 2026-10-19 over Action Cable
  with the async adapter, see live-updates.md). See ui.md, Turbo Drive.
- **Plain CSS.** The committed CSS was a Sass syntax error dump (tabs mixed
  with spaces). The styles now live in `app/assets/stylesheets/application.css`
  with no Sass build step.
- **Secrets from the environment.** `secret_token.rb`, the hard-coded Devise
  pepper and the seeded admin password were removed. See auth.md and
  docker.md.
- **macOS Stickies look (2026-10-18, operator request).** The 2011 layout
  (one yellow page with a folded-corner image) was replaced by a board of
  pastel sticky notes and a note window; see ui.md.
- **Debug leftovers removed:** the index page no longer sets sample flash
  messages, and the edit action no longer references the uninstalled
  MarkItUp editor.
- Unused gems dropped: RedCloth, haml, sass, json, nifty-generators,
  couchrest, couchrest_model.

## Security Note

All signed-in users can read, change and delete every note. Sign-up is closed
in production unless `REGISTRATION_OPEN=true` (auth.md); keep it closed on a
public host.
