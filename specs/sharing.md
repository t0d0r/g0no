# Sharing notes

Requested by the operator on 2026-10-18: "make option to share note, via
shared link or via shared link with password".

## Model

Columns on `notes`: `share_token` (unique, NULL when not shared),
`share_password_digest` (bcrypt via `has_secure_password :share_password`,
NULL for an open link) and `shared_at`.

- `Note#share(password: nil)` makes a new 32-character base58 token, sets or
  clears the password and saves. Sharing again therefore replaces the link;
  the old one stops working.
- `Note#unshare!` clears all three columns.
- A share password is optional; when given it must be 6 to 72 characters.

## Owner side

The note window has a "Sharing" section:

- not shared: an optional password field and "Create share link"
  (`POST /notes/:id/share`, param `share_password`);
- shared: status (open link or link + password, and since when), the URL in a
  read-only field with "Copy link", "Stop sharing" (`DELETE
  /notes/:id/share`, with a confirmation) and the same form labelled "New
  link" to replace the link or change the password.

Board cards of shared notes show a link icon. Administrators see every
shared note in `/admin` and can stop sharing it.

## Visitor side (no sign-in)

| route | behaviour |
|-------|-----------|
| `GET /s/:token` | read-only note: title, description, total, expenses, files with preview; for a password link without unlock, the password form instead |
| `POST /s/:token` | check the password; on success remember the unlock in the session and redirect to the note; wrong password re-renders the form with 422 |
| `GET /s/:token/files/:attachment_id` | download a file of that note |
| `GET /s/:token/files/:attachment_id/preview` | inline preview, same rules as for signed-in users (features.md) |

- An unknown or replaced token renders "Link not available" with 404.
- File routes of a locked note redirect to `/s/:token`.
- Attachments are looked up through the shared note, so a token never gives
  access to another note's files.
- The session stores, per token, a fingerprint of the password hash
  (first 16 hex characters of its SHA-256). Changing the password or the link
  locks the note again. At most 20 unlocked tokens are kept per session.
- Password attempts are rate limited: 10 per 5 minutes per IP and token
  (Rails `rate_limit`, in-process memory store); over the limit the form is
  shown with status 429.

## Response headers on /s/...

- `Referrer-Policy: same-origin` - the token is not sent in `Referer` to
  other sites. (`no-referrer` was tried and rejected: browsers then send
  `Origin: null` on the password form, which fails Rails' CSRF origin check.)
- `X-Robots-Tag: noindex, nofollow` and `Cache-Control: no-store`.

## Acceptance

`test/controllers/notes_controller_test.rb` covers open and password links,
wrong and short passwords, link replacement and revocation, unknown tokens
and cross-note file access. Verified in headless Chrome on 2026-10-18,
including the password form and unlock.

## Security Note

Anyone who has an open link can read the note and its files; treat links like
passwords and stop sharing when no longer needed. The rate limit is per
process and resets on restart; put the app behind HTTPS so links and share
passwords are not sent in clear text.
