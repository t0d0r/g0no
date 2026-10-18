# Admin panel

Requested by the operator on 2026-10-18: "add admin panel for admin user".

## Who is an administrator

`users.admin` (boolean, default false). The seed (`db/seeds.rb`) creates the
`ADMIN_USERNAME` user (default `admin`) with `admin: true`, and sets the flag
on an existing user with that username if it is missing (email and password
are left unchanged). Sign-up never sets the flag: Devise only permits email
and password there.

## Pages

All under `/admin`, controllers in `app/controllers/admin/`. A signed-out
visitor is sent to sign in; a signed-in user without the flag is redirected
to the board with the alert "Only administrators can open that page". The
menu bar shows an "Admin" link to administrators only.

| route | behaviour |
|-------|-----------|
| `GET /admin` | stats (users, notes, files, stored bytes, sum of expenses), the user table (username, email, role, sign-in count, last sign-in, edit / delete) and the list of shared notes with "Stop sharing" |
| `GET /admin/users/new`, `POST /admin/users` | create a user: username, email, password + confirmation, admin flag |
| `GET /admin/users/:id/edit`, `PATCH /admin/users/:id` | edit the same fields; a blank password keeps the current one |
| `DELETE /admin/users/:id` | delete a user; notes they wrote stay (authors are stored as names) |
| `DELETE /admin/shares/:id` | revoke the share link of note `:id` |

## Rules

- An administrator cannot remove their own admin flag (the checkbox is
  disabled and the parameter is ignored) and cannot delete their own account.
  So at least one administrator always remains.
- Changing your own password keeps you signed in (`bypass_sign_in`).
- Usernames are unique, case-insensitive (`User` validation); surrounding
  spaces are stripped and a blank username is stored as NULL.

## Acceptance

`test/controllers/admin_controller_test.rb` covers access control, listing,
create, update with and without a password, self-protection, delete and
share revocation.

## Security Note

The admin panel can set any user's password and grant the admin flag. Keep
the number of administrators small, and keep the seeded admin password
(in `.env`) private.
