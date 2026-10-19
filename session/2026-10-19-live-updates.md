# 2026-10-19 - live updates

## Done

- Operator asked: "can we have live updates over shared link and edited",
  then "using cables or similar?". Answer: yes, Action Cable (WebSockets),
  with Turbo 8 page refreshes.
- Action Cable is on (`config/application.rb`, `config/cable.yml`, adapter
  `async`, since the app is one Puma process).
- `Note#broadcast_refresh_to_viewers` sends a debounced
  `<turbo-stream action="refresh">` to the note stream and to the share
  stream (`Note#share_stream`, named after a hash of the token). It runs
  after commit of note updates and deletes, and of file and expense
  changes. Only the signal goes over the socket; pages fetch their content
  over HTTP.
- Note pages (show, edit) and the unlocked share page subscribe with
  `turbo_stream_from`. The layout sets `turbo-refresh-scroll` to `preserve`.
- `application.js`:
  - holds a refresh while the page is busy (note unlocked, unsaved or
    saving; typed fields; focused text field; open dialog or menu) and
    shows a notice under the note while it is being edited;
  - autosave and the wide box use Turbo's `fetch`, so a page skips the
    refresh caused by its own save;
  - autosave of an existing note sends only the changed fields, so saving
    the text does not undo someone else's colour change;
  - the script tag has `data-turbo-eval="false"`, so the 404 page of a
    revoked share link does not run the script twice.
- A deleted note's `show` / `edit` redirects to the board with "That note
  was deleted." instead of a 404.
- `deploy/apache.conf`: `upgrade=websocket` on the ProxyPass.
- Tests: `test/integration/live_updates_test.rb` (8 tests). Checked in
  Chrome on port 3100 with two editors and one share viewer (results in
  specs/live-updates.md). The demo user and note were deleted afterwards.

## Decisions and open points

- Refresh signals rather than streaming HTML: no note content over the
  socket, and the existing auth and share checks stay in one place.
- Adapter `async`. Moving to several processes needs solid_cable (or
  Redis); this is recorded in config/cable.yml and the spec.
- The board does not update live (not asked for).
- Concurrent edits of the same field: last save wins, both versions are in
  History. Optimistic locking would be the next step if this matters.
- Production: pushed to origin/master and deployed with `make deploy`
  (74aa3f8 is up, `/up` answers 200). A WebSocket handshake straight to the
  container answers 101, so Thruster and the origin check are fine. Through
  Apache, `/cable` still answers 404: the installed vhost lacks
  `upgrade=websocket`. After the operator granted the permission, the
  agent added it to the installed vhost, `apache2ctl configtest` passed and
  Apache was reloaded. Now `/cable` through Apache answers 101 to the app's
  own origin and 404 to a foreign origin (Action Cable's origin check);
  `/up` answers 200.
- The operator's dev server on :3000 needs a restart to load Action Cable.
- The operator removed the todo item to run `make import` against the
  real CouchDB (2026-10-19); the import task and specs/couchdb-import.md
  stay as they are. The item to move the old users database to storage/
  (or recreate users) was removed the same way; specs/auth.md is
  unchanged.

## Dependabot alerts

- The 35 open alerts (Rails 3.0, json 1.5, mail 2.x, ...) date from 2019 and
  were never updated: the repository's dependency graph was disabled, so
  GitHub never read the new Gemfile.lock. Enabled it on 2026-10-19 with
  the API (`PUT /repos/t0d0r/g0no/vulnerability-alerts`, which also turns
  on the graph). The graph is built on the next push to master; then the
  old alerts should close as fixed. `make audit` (bundler-audit) is clean
  locally.

## Files touched

config/application.rb, config/cable.yml, app/models/note.rb,
app/models/note_attachment.rb, app/models/finance_entry.rb,
app/controllers/notes_controller.rb, app/views/layouts/application.html.erb,
app/views/notes/show.html.erb, app/views/notes/edit.html.erb,
app/views/notes/_form.html.erb, app/views/shared_notes/show.html.erb,
app/assets/javascripts/application.js, app/assets/stylesheets/application.css,
config/locales/en.yml, config/locales/bg.yml, deploy/apache.conf,
test/integration/live_updates_test.rb, specs/live-updates.md,
specs/README.md, specs/overview.md, specs/ui.md, specs/features.md,
specs/deploy.md, README.md, todo/todo.md.

## How to run and verify

- `make check` - rubocop, brakeman and the test suite
- `make run` - development server on http://localhost:3000; open a note in
  two browsers (or a note and its share link) and edit in one
- `DEPLOY_HOST=<ssh host> make deploy` - production (see specs/deploy.md)

## Next step

Sign in to production in two browsers (or a note and its share link) and
confirm a page updates when the note is edited; not done by the agent,
which has no production account.

## Security Note

The WebSocket accepts anonymous connections; subscriptions need a stream
name signed with SECRET_KEY_BASE, and only "refresh" signals are sent, never
note content. See specs/live-updates.md.
