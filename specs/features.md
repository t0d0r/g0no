# Features

Every page except sign-in, sign-up, password reset and `/up` requires a
signed-in user.

| route | behaviour |
|-------|-----------|
| `GET /` and `GET /notes` | board of note cards (in the chosen order, see Sorting) with title, the first 250 characters of the description, age and author, a paperclip with the number of files, a link icon when shared, and the total expense when above zero; the first card links to a new note |
| `GET /notes?q=&color=` | search from the board header: `q` matches title or description (case-insensitive, `%` and `_` taken literally), `color` limits to one paper colour; unknown colours are ignored; the header shows the filter with a "Clear filter" link and the new-note tile is hidden |
| `GET /notes/new`, `POST /notes` | create a note; author is the current user; a missing or duplicate title re-renders the form with status 422 (JSON: `{error}` with 422, `{url, saved_at}` with 201) |
| `GET /notes/:id` | a note window: title and description edited in place and saved automatically (see Autosave), the total expense, the expense list (newest first) with the add-expense form, the attachment list with the upload form, and the sharing section (sharing.md); the title bar has close (back to the list), the colour menu and delete boxes |
| `PATCH /notes/:id` | one action for the note forms: title/description, colour (`note[color]`), a finance entry (`finance[date, amount, comment]`), and uploads (`note[attachments][]` with `note[attachment_comment]`); sets `updated_from`; on a validation error re-renders the page with 422 and the messages in the flash; with `Accept: application/json` (autosave) answers `{url, saved_at}` or `{error}` with 422 |
| `PATCH /preferences` | `theme` (light, dark) and/or `scale` (normal, big, extra) into permanent cookies, then back to the previous page; no sign-in needed |
| `GET /notes/:id/files/:attachment_id` | download an attachment (always as a download) |
| `GET /notes/:id/files/:attachment_id/preview` | inline copy for the preview dialog, only for allowed types (below); 404 for anything else; supports one `Range` |
| `POST /notes/:id/share`, `DELETE /notes/:id/share` | create or replace / stop the share link (sharing.md) |
| `GET /notes/:id/history`, `POST /notes/:id/history/:version_id/restore` | history of the note and restore (history.md) |
| `DELETE /notes/:id/delete_file?attachment_id=` | delete an attachment |
| `DELETE /notes/:id` | delete a note (the "-" box in the note's title bar, with a confirmation prompt) |
| `GET /notes/:tag/by_tag` | notes with the given tag, in the chosen order |
| `GET /up` | health check, 200 when the app boots |

## Sorting

Operator, 2026-10-19: a button next to the note count that cycles the
order, with light animation when the cards rearrange.

- The board header holds, right of the title: the search box, the colour
  filter (dot + colour name, opens the colour menu), the note count with
  "Clear filter" when filtered, and the sort button (operator, 2026-10-19:
  colour filter and search moved next to sort). Search and colour are one
  GET form, so each keeps the other. On phones the tools wrap under the
  title with the search on its own row.
- Orders, in cycle order: Oldest first (`created_asc`, the default), Newest
  first (`created_desc`), Recently edited (`updated_desc`), Least recently
  edited (`updated_asc`); ties by id. Applies to the board, search results
  and notes by tag.
- The choice is kept in the `sort` cookie (one year, SameSite=Lax).
  `?sort=` sets it; without JavaScript the button is a link to the next
  order that keeps only `q` and `color` from the query string.
- With JavaScript the cards are reordered in place and glide to their new
  place (FLIP): transform only, 300 ms, ease-out, only cards on screen,
  corrected for the text size zoom so nothing jumps; no animation with
  `prefers-reduced-motion`.

## Autosave

Operator, 2026-10-19: "notes to remember changes on focus out or automatic,
no need save cancel". There are no Save / Cancel buttons (a Save button
exists only inside `<noscript>`).

- The note form saves itself 1.2 seconds after typing stops, when the title
  or description loses focus, when a new note's colour changes, and when the
  page is hidden or left (`pagehide` / `visibilitychange`, sent with
  `fetch(..., keepalive: true)`).
- Requests are `POST` with the form data (`_method=patch` for existing
  notes) and `Accept: application/json`; one at a time, a change during a
  save is sent right after it.
- An existing note sends only the fields (title, description, colour) that
  changed since the last save, and uses Turbo's `fetch` so its own live
  refresh is skipped (live-updates.md).
- The token sent is the page-wide one from the `csrf-token` meta tag: Rails
  per-form tokens are bound to the form's action, which changes when a new
  note becomes an existing one.
- A new note is created on its first save, which needs a title; until then
  the status says "Add a title to save this note". After creation the form
  updates that note and the address changes to `/notes/:id` (no reload).
- A status line under the description shows "Saving...", "Saved at HH:MM"
  or "Not saved: <reason>" (for example a duplicate title, in red).
- Several saves by the same person within 10 minutes of each other form one
  "edited" history entry (history.md).

## Wide notes

Operator, 2026-10-19: "add option note to be wider". Per note, like the
zoom button of a window: a box with diagonal arrows next to the Markdown
box widens the note window from 760px to the full desk width (up to about
1090px) and back (`notes.wide`, `PATCH note[wide]`). With JavaScript the
width changes at once with a 0.25 s transition (none with reduced motion),
the text area regrows afterwards, and the flag is saved in the background;
without JavaScript the box is a form. Shared notes use the same width. Not
a content change, so no history entry. Hidden on phones, where notes are
already full width.

## Locked notes

Operator, 2026-10-19: "make note to be locked from editing if just click,
unlock it if dbl click".

- A saved note opens locked: title and description are read-only (text can
  still be selected and copied); the status line says "Double-click the note
  to edit it".
- Double-click on the title or description unlocks both and puts the caret
  exactly where the double-click was (the caret position of its first
  click), not on a selected word that typing would replace.
- Unlocking never moves the page: the field is focused without scrolling,
  any scroll caused by showing the plain text is undone, and after a
  double-click the page shifts only so that the caret's line is at the
  height of the click (measured with a hidden copy of the text area). This
  matters for Markdown notes, whose plain text is laid out differently.
  Auto-grow keeps the scroll position too, so typing in a long note does
  not jump.
- Keyboard and touch: Enter on a locked field unlocks it; the padlock box in
  the title strip toggles the lock (unlocking puts the caret at the end of
  the description).
- When focus leaves both fields, or on Escape, or with the padlock, the note
  saves (autosave) and locks again.
- New notes are not locked. Expenses, files, colour and sharing are not
  affected by the lock. Without JavaScript nothing is locked.

## Theme and text size

A sun/moon button in the menu bar switches between light and dark desk (the
moon shows in light mode, the sun in dark mode). Without a choice the theme
follows the system. Three "A" buttons of growing size next to it choose the text
size: Normal, Big (115%), Extra big (130%); the pressed one is highlighted
and the whole page scales (`zoom` on `body`). Text areas hide overflow on
both axes, since zoom rounding could otherwise show a 1px scroll bar. Both are
kept in the cookies `theme` and `scale` (one year, SameSite=Lax), so the
layout renders them on `<html data-theme data-scale>` before any script
runs; with JavaScript they apply at once without a request. They are on
every page, including sign-in and shared notes.

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
