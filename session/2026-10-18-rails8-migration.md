# 2026-10-18 - Rails 8 migration and Docker

## Done

- Upgraded the app from Rails 3.0.5 (Ruby 1.8/1.9 era) to Rails 8.1.4 on
  Ruby 4.0.7, starting from a fresh `rails new` skeleton and porting the app
  code into it. Work is on branch `rails-8-upgrade`.
- Confirmed couchrest_model 2.2.0.beta2 cannot run on Rails 8.1 (stack
  overflow on the first validation). The operator approved moving off
  CouchDB, so notes, tags, finance entries and attachments are now SQLite
  tables plus Active Storage.
- Added `couchdb:import` to copy the old CouchDB data; verified against a
  real CouchDB 3 container.
- Devise 1.1 -> 5.0.4; 2011 bcrypt+pepper hashes verify when
  `DEVISE_PEPPER` is set.
- Rewrote the front end without jQuery/Prototype; Sass compiled to CSS.
- Docker image, compose file, `.env.example`; image built and smoke-tested.
- Added Makefile, AGENTS.md, README.md, specs/, todo/, session/.
- Removed committed secrets from the code (session secret, Devise pepper,
  default admin password); they remain in git history.

### Later in the session

- `bin/setup-env` creates `.env` (mode 600) with a random `ADMIN_PASSWORD`,
  `SECRET_KEY_BASE`, `ADMIN_EMAIL=admin@localhost`, `ADMIN_USERNAME=admin`;
  `make run` and `make docker-up` call it. Seeds now create the admin user
  whenever no user with that username exists; the container entrypoint
  runs the seed on every start.
- Replaced the 2011 look with a macOS Stickies style (specs/ui.md): board of
  pastel note cards, note window with title-strip boxes, menu bar, flash
  banners, mobile layout. All UI strings moved to en/bg locales; added
  devise.bg.yml and translated sign-up / password pages.
- Verified with `make run` (fresh and repeated) and headless Chrome
  screenshots at 1280px and 390px. Demo notes used for the screenshots were
  deleted afterwards; the local development database holds only `admin`.

### Evening: admin, sharing, search, previews

Operator asked for (in order): admin panel for the admin user, attachment
indication on notes, preview modal for attachments, sharing by link or link +
password, menu bar search with filter and per-note colours from a fixed set,
a more informative confirmation than "Are you sure?", and drag and drop
upload. All done in one turn:

- `users.admin`; seeds create the admin with the flag or set it on the
  existing admin user. `/admin` (dashboard, user CRUD, revoke shares).
- `notes.note_attachments_count` (counter cache) -> paperclip badge on cards.
- Preview dialog (`<dialog>`, plain JS) for image, PDF, video, audio, text;
  inline only for an allow-list, with CSP sandbox and Range support
  (`AttachmentServing` concern, shared by NotesController and
  SharedNotesController).
- `notes.share_token`, `share_password_digest`, `shared_at`; public
  `/s/:token` pages; password unlock remembered in the session; rate limit.
- `notes.color` (backfilled with the old `id mod 6`), colour menu in the
  note title strip, `?q=&color=` search on the board from the menu bar.
- Confirm dialog naming the note/file/user and the consequence.
- Drag and drop onto the note window submits the upload form.
- Bug found in the browser check and fixed: `Referrer-Policy: no-referrer`
  on share pages made the password form fail CSRF (Origin: null); now
  `same-origin`.

### Late evening: history and random colour

- `note_versions` table with full snapshots (title, description, colour)
  per change plus file / expense events; existing notes got one "baseline"
  row. Model callbacks record them; `Current.user` names the author.
- `/notes/:id/history`: Time Machine style stack on a night sky, timeline,
  word diff (`TextDiff`), restore with confirm. Clock box in the title strip.
- Dice button after the colour swatches picks another colour at random.
- Operator asked whether history needed a database change: no, it is one
  more SQLite table (recorded in specs/history.md).
- Flash messages restyled as small stickies at the top right (yellow
  notice that fades after 6 s, pink alert that stays), on operator request.

### 2026-10-19: autosave, theme, text size

- Notes save themselves (debounced input, blur, pagehide with keepalive);
  Save/Cancel removed. New notes are created on the first save with a
  title. Found in the browser: per-form CSRF tokens broke the first update
  after creation; the script now sends the meta csrf token.
- History groups edits by the same author within 10 minutes.
- Sun/moon theme switch and Normal/Big/Extra big text size, in cookies,
  `PreferencesController` as no-JS fallback. Dark colours moved to CSS
  variables so both the system setting and the switch drive them.

- Long descriptions showed a scroll bar (auto-grow forgot the border);
  fixed, plus a copy-to-clipboard box in the title strip and a new yellow
  sticky favicon / touch icon.

- Notes open locked (read-only); double-click, Enter or the padlock box
  unlocks; leaving the fields or Escape saves and locks again.

- Markdown switch per note (commonmarker gem, sanitized), formatted while
  locked, plain while editing, clickable task boxes that flip [ ]/[x] in the
  text. Found: YAML keys on/off are booleans (missing translation leaked
  into a title attribute); tests now raise on missing translations and
  check that en and bg keys match.

- Double-click unlock puts the caret at the click point (plain fields: the
  first click's caret; Markdown: source positions + character matching,
  verified for bold, italic, heading, task, table cell, after a link).
- Text size is now three A buttons; text areas hide overflow on both axes
  (zoom rounding showed a horizontal scroll bar in Safari).
- A demo note ("Caret plain demo") was kept: the operator edited it.

- Board sort button (oldest / newest / recently edited / least recently
  edited) in a cookie; cards glide to new places (FLIP, transform only,
  300 ms, zoom-corrected, off with reduced motion).

- Search box and colour filter moved from the menu bar to the board
  header next to the count and sort button (notes/_board_tools).
- Operator asked about the Rails "single page feel": Hotwire Turbo (was
  Turbolinks). Not adopted; the app stays framework-free unless asked.

- Turbo Drive added (turbo-rails, module script via Propshaft): setUpPage
  on turbo:load with an AbortController per page, autosave flush on Turbo
  visits, no page snapshots (stale-note safety), downloads opt out.
- Menu bar left side redesigned: sticky icon + name, section pills with
  paper colour squares.

- Unlocking a long note no longer jumps to the top (focus without scroll,
  auto-grow restores scroll, caret line aligned to the click).

- Per-note wide option (notes.wide): title strip box, instant toggle saved
  in the background.

- 2026-10-19: operator asked to push and merge. gitleaks over the 14 new
  commits found only the Devise generator's commented-out sample key (now a
  placeholder). master fast-forwarded to rails-8-upgrade and pushed to
  origin. GitHub's Dependabot alerts at push time referred to the 2011
  Gemfile.lock; `make audit` on the new lock file is clean.

## Decisions

See specs/overview.md ("Migration from Rails 3.0"). Main ones: SQLite instead
of CouchDB, authenticated attachment downloads with Active Storage routes
off, no JS framework, secrets only from the environment.

- Colours are a fixed set of six; no custom colours (operator: "colors by
  set, not custom one"). The menu bar filter is server-side (`GET /notes`).
- A non-admin opening `/admin` is redirected with an alert (not a 404).
- History stores full snapshots, not diffs, so any version restores alone;
  restore covers title, description and colour, not files or expenses.
- Sharing again always makes a new token, so "change password" and "new
  link" are the same action and old links die.

## Open

- Real data import and users database move have not been run (no access to
  the production data from this session).
- Registration is open and SMTP is not configured.
- Share-password rate limit is in-process memory; fine for one Puma process.
- The local development database still holds three demo notes from the
  screenshot run (Groceries, Garden, Car service) because the operator added
  their own files to them while testing; the other demo notes and the demo
  user were deleted.

## Files touched

2026-10-19: app/views/notes/_form.html.erb, partials/_preferences,
app/controllers/preferences_controller.rb, notes_controller (JSON),
note_version.rb (grouping), application.js/css, layout, helpers, locales,
test/controllers/preferences_controller_test.rb, specs.

Late evening: db/migrate/20261019090001, app/models (current,
note_version, text_diff, note, note_attachment, finance_entry),
app/helpers/history_helper.rb, app/views/notes/history.html.erb,
_window, _color_menu, partials/_flash, layout, application.js/css, locales, tests,
specs/history.md and related specs.

Evening: db/migrate/20261018200001-04, app/models (note, note_attachment,
user), app/controllers (notes, shared_notes, admin/*, concerns/attachment_serving),
config/routes.rb, app/helpers, app/views (layout, partials/_search,
partials/_confirm_dialog, notes/*, shared_notes/*, admin/*),
app/assets (application.css, application.js), config/locales/{en,bg}.yml,
db/seeds.rb, test/ (fixtures, notes and admin controller tests, seeds test),
specs/admin.md, specs/sharing.md, specs/features.md, specs/ui.md,
specs/data-model.md, specs/auth.md, specs/README.md, README.md, todo.

Later: bin/setup-env, db/seeds.rb, Makefile, bin/docker-entrypoint,
.env.example, app/assets/stylesheets/application.css,
app/assets/javascripts/application.js, app/views (layout, notes, devise),
app/helpers, config/locales (en, bg, devise.en, devise.bg),
test/seeds_test.rb, specs/ui.md and the other specs.

First part: almost every file: Gemfile/Gemfile.lock, app/, config/, db/, lib/,
test/, bin/, public/, Dockerfile, compose.yaml, .dockerignore, .env.example,
.gitignore, Makefile, README.md, AGENTS.md, specs/, todo/, session/.
Removed: script/, vendor/plugins/, public/javascripts, public/stylesheets,
public/images (two images moved to app/assets/images), the Rails 3 tests.
The 2011 README moved to doc/NOTES-2011.md.

## How to run and verify

- `make check` - rubocop, brakeman, 108 tests
- `make run` - development server on http://localhost:3000; admin password
  is `ADMIN_PASSWORD` in `.env`
- `make docker-up` - production image via compose (needs `.env`)
- `make audit` - gem vulnerability check

## Next step

Try the new features with `make run` (sign in as admin, open `/admin`, share
a note, drop a file on a note, open a note's history with the clock box). Then:

Run `COUCHDB_URL=... make import` (or `make docker-import`) against the real
2011 CouchDB and compare the note count and totals with the old app.

## Security Note

The old secrets in git history must be treated as public. Use a fresh
SECRET_KEY_BASE and reset the seeded admin password from 2011.
