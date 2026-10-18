# Authentication

Devise 5 with the modules `database_authenticatable`, `registerable`,
`recoverable`, `rememberable`, `trackable` and `validatable` (the same set as
in 2011).

- The sign-in form has one field labelled "Email"; it accepts the email or
  the username, case-insensitively (`User.find_for_database_authentication`).
- Sign-up accepts email and password only; `username` is set by the seed or
  the console (it was not mass-assignable in 2011 either).
- Sign-out is `DELETE /users/sign_out` (a `button_to` in the top bar).
- Sign-in, sign-up and password reset pages are translated (`bg`, `en`),
  including Devise's flash messages (`config/locales/devise.bg.yml`).

## Admin user

`db/seeds.rb` creates the user `ADMIN_USERNAME` (default `admin`) with
`ADMIN_EMAIL` and `ADMIN_PASSWORD` and the admin flag when no user with that
username exists (case-insensitive), even if other users exist. For an
existing user with that username the seed only sets the admin flag if it is
missing; email and password are never changed, so editing `.env` later does
not change the password. Without
`ADMIN_EMAIL` or `ADMIN_PASSWORD` the seed prints a message and does nothing.
The password is never printed.

`bin/setup-env` creates `.env` from `.env.example` (mode 600) when it is
missing and fills only empty values: `SECRET_KEY_BASE` (random),
`ADMIN_EMAIL` (`admin@localhost`), `ADMIN_USERNAME` (`admin`) and
`ADMIN_PASSWORD` (24 random hex characters). `make run` runs it, loads
`.env`, runs the seed and starts the server. `make docker-up` runs it before
starting the container, whose entrypoint runs the seed on every start.

To change the admin password, use the admin panel (`/admin`, admin.md) or
`bin/rails runner`, not `.env`.

## Users created by the 2011 app

Devise 1.1 hashed `password + pepper` with bcrypt (cost 10). Devise 5 checks
`password + Devise.pepper` against the bcrypt string, so old hashes verify
when the same pepper is configured. The pepper is read from `DEVISE_PEPPER`;
it is unset by default. A test (`test/models/user_test.rb`) covers this.

To keep old passwords working, set `DEVISE_PEPPER` to the value from the
2011 `config/initializers/devise.rb` (in git history). Better: leave it unset
and have users reset their password (or set a new one from the console),
because that value is public in the repository history. Note that changing
the pepper later invalidates every password hashed with the old one.

Moving an existing users database: copy the old `db/production.sqlite3` to
`storage/production.sqlite3` and run `bin/rails db:migrate`. The first
migration has the same version as in 2011 and is skipped; the next one adds
`reset_password_sent_at` and drops `password_salt` and `remember_token`.

## Security Note

Sign-up (Devise registrations) is controlled by `REGISTRATION_OPEN`: open
by default in development and test, closed by default in production
(operator, 2026-10-19, before the public deployment). When closed, the
sign-up link is hidden and `GET /users/sign_up` and `POST /users` redirect
to sign-in with "Sign-up is closed. Ask an administrator for an account.";
administrators create users at `/admin`. Signed-in users can still edit
their own account. Every signed-in user can read all notes, so keep sign-up
closed on a public host. Password reset emails need SMTP settings, which are not
configured yet (see todo).
