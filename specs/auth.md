# Authentication

Devise 5 with the modules `database_authenticatable`, `registerable`,
`recoverable`, `rememberable`, `trackable` and `validatable` (the same set as
in 2011).

- The sign-in form has one field labelled "Email"; it accepts the email or
  the username, case-insensitively (`User.find_for_database_authentication`).
- Sign-up accepts email and password only; `username` is set by the seed or
  the console (it was not mass-assignable in 2011 either).
- Sign-out is `DELETE /users/sign_out` (a `button_to` in the top bar).
- The first user is created by `db/seeds.rb` from `ADMIN_EMAIL`,
  `ADMIN_PASSWORD` and optional `ADMIN_USERNAME` (default `admin`). Without
  them the seed prints a message and does nothing.

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

Registration is open: anyone who can reach the app can create an account and
read all notes. Password reset emails need SMTP settings, which are not
configured yet (see todo).
