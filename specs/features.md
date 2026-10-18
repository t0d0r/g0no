# Features

Every page except sign-in, sign-up, password reset and `/up` requires a
signed-in user.

| route | behaviour |
|-------|-----------|
| `GET /` and `GET /notes` | board of note cards (oldest first) with title, the first 250 characters of the description, age and author, and the total expense when above zero; the first card links to a new note |
| `GET /notes/new`, `POST /notes` | create a note; author is the current user; a missing or duplicate title re-renders the form with status 422 |
| `GET /notes/:id` | a note window: title and description edited in place (save/cancel appear after a change), the total expense, the expense list (newest first) with the add-expense form, the attachment list with the upload form; the title bar has close (back to the list) and delete boxes |
| `PATCH /notes/:id` | one action for three forms: title/description, a finance entry (`finance[date, amount, comment]`), and uploads (`note[attachments][]` with `note[attachment_comment]`); sets `updated_from`; on a validation error re-renders the page with 422 and the messages in the flash |
| `GET /notes/:id/files/:attachment_id` | download an attachment (always as a download) |
| `DELETE /notes/:id/delete_file?attachment_id=` | delete an attachment |
| `DELETE /notes/:id` | delete a note (the "-" box in the note's title bar, with a confirmation prompt) |
| `GET /notes/:tag/by_tag` | notes with the given tag |
| `GET /up` | health check, 200 when the app boots |

## Locale

The locale is the first language in `Accept-Language` when it is `bg` or
`en`; anything else falls back to English. Translations are in
`config/locales/`.

## Acceptance

`make check` passes. `test/controllers/notes_controller_test.rb` covers each
route above.

## Security Note

All forms carry Rails CSRF tokens; sign-out is a DELETE request.
