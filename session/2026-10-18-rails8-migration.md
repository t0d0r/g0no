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

## Decisions

See specs/overview.md ("Migration from Rails 3.0"). Main ones: SQLite instead
of CouchDB, authenticated attachment downloads with Active Storage routes
off, no JS framework, secrets only from the environment.

## Open

- Real data import and users database move have not been run (no access to
  the production data from this session).
- Registration is open and SMTP is not configured.

## Files touched

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

- `make check` - rubocop, brakeman, 34 tests
- `make run` - development server on http://localhost:3000; admin password
  is `ADMIN_PASSWORD` in `.env`
- `make docker-up` - production image via compose (needs `.env`)
- `make audit` - gem vulnerability check

## Next step

Run `COUCHDB_URL=... make import` (or `make docker-import`) against the real
2011 CouchDB and compare the note count and totals with the old app.

## Security Note

The old secrets in git history must be treated as public. Use a fresh
SECRET_KEY_BASE and reset the seeded admin password from 2011.
