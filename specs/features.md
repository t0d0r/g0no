# Features

Every page except sign-in, sign-up, password reset and `/up` requires a
signed-in user.

| route | behaviour |
|-------|-----------|
| `GET /` and `GET /notes` | board of note cards (oldest first) with title, the first 250 characters of the description, age and author, a paperclip with the number of files, a link icon when shared, and the total expense when above zero; the first card links to a new note |
| `GET /notes?q=&color=` | search from the menu bar: `q` matches title or description (case-insensitive, `%` and `_` taken literally), `color` limits to one paper colour; unknown colours are ignored; the header shows the filter with a "Clear filter" link and the new-note tile is hidden |
| `GET /notes/new`, `POST /notes` | create a note; author is the current user; a missing or duplicate title re-renders the form with status 422 |
| `GET /notes/:id` | a note window: title and description edited in place (save/cancel appear after a change), the total expense, the expense list (newest first) with the add-expense form, the attachment list with the upload form, and the sharing section (sharing.md); the title bar has close (back to the list), the colour menu and delete boxes |
| `PATCH /notes/:id` | one action for the note forms: title/description, colour (`note[color]`), a finance entry (`finance[date, amount, comment]`), and uploads (`note[attachments][]` with `note[attachment_comment]`); sets `updated_from`; on a validation error re-renders the page with 422 and the messages in the flash |
| `GET /notes/:id/files/:attachment_id` | download an attachment (always as a download) |
| `GET /notes/:id/files/:attachment_id/preview` | inline copy for the preview dialog, only for allowed types (below); 404 for anything else; supports one `Range` |
| `POST /notes/:id/share`, `DELETE /notes/:id/share` | create or replace / stop the share link (sharing.md) |
| `GET /notes/:id/history`, `POST /notes/:id/history/:version_id/restore` | history of the note and restore (history.md) |
| `DELETE /notes/:id/delete_file?attachment_id=` | delete an attachment |
| `DELETE /notes/:id` | delete a note (the "-" box in the note's title bar, with a confirmation prompt) |
| `GET /notes/:tag/by_tag` | notes with the given tag |
| `GET /up` | health check, 200 when the app boots |

## Colours

A note has one of six paper colours (`Note::COLORS`: yellow, blue, green,
pink, purple, gray), stored in `notes.color` (default yellow). There are no
custom colours: the operator asked for "colors by set, not custom one". The
colour menu in the note's title strip changes it; for a new note the choice
is saved with the note. A dice button after the six squares picks a random
colour other than the current one (for a saved note the pick is made when
the page is drawn, so it works without JavaScript). Existing notes got `id mod 6` when the column was
added, which is the colour they showed before.

## Attachments: drag and drop

Files dropped anywhere on an open note window are put into the upload form
and submitted, with the text of the comment field if any. While dragging,
the window shows a dashed overlay; dropping next to the window does nothing
(the browser does not open the file).

## Attachments: preview

Clicking a file name opens a preview dialog (a sticky in the note's colour)
instead of downloading; Ctrl/Cmd-click and no-JavaScript still download. The
dialog shows the file name, size and comment, "n / total", a Download button,
and previous/next boxes (also the arrow keys). Escape, the close box or a
click on the backdrop closes it and stops playback.

| kind | content types | shown as |
|------|---------------|----------|
| image | png, jpeg, gif, webp, avif, bmp | `<img>` |
| pdf | application/pdf | `<iframe>` (browser PDF viewer) |
| video | mp4, webm, ogg, quicktime | `<video controls>` |
| audio | mpeg, mp4, ogg, wav, webm, flac | `<audio controls>` |
| text | plain, csv, markdown, x-log, json, up to 1 MB | fetched and shown as text in `<pre>` |

Anything else (HTML, SVG, office files, archives, ...) shows "No preview for
this file type" with the Download button. The content type is the one
Active Storage detected from the file's bytes, not the upload's claim.

## Confirmations

Destructive buttons (delete note, delete file, stop sharing, delete user)
ask in a dialog that names the item and the consequence, for example
"'Groceries' will be deleted permanently, with 2 expenses and 3 files. This
cannot be undone.", with Cancel (focused) and a red button naming the action
("Delete note"). Escape or the backdrop cancels. The operator found the old
browser "Are you sure?" prompt not informative. Without JavaScript the form
submits directly.

## Locale

The locale is the first language in `Accept-Language` when it is `bg` or
`en`; anything else falls back to English. Translations are in
`config/locales/`.

## Acceptance

`make check` passes. `test/controllers/notes_controller_test.rb` covers each
route above.

## Security Note

All forms carry Rails CSRF tokens; sign-out is a DELETE request. Previews
are sent inline only for the allow-listed types, with `nosniff` (Rails
default) and, except for PDFs, `Content-Security-Policy: default-src 'none';
sandbox`, so an uploaded file never runs as a page of the app.
