# Note history ("time capsule")

Requested by the operator on 2026-10-18: "add support for history of the
changes like time capsule". Modelled on macOS Time Machine: versions of the
note stacked into the distance with a timeline beside them.

## What is recorded

Table `note_versions`: `note_id`, `event`, `title`, `description`, `color`,
`author`, `details`, `created_at`. Every row is a full snapshot of the note's
title, description and colour after the event, so any row can be restored
on its own (no chain of diffs to replay).

| event | when | details |
|-------|------|---------|
| baseline | once per note that existed when the table was added (migration) | - |
| created | a note is created; an imported note keeps its CouchDB creation time | - |
| edited | title or description changed | - |
| recolored | only the colour changed | - |
| restored | an older version was restored | ISO time of that version |
| file_added / file_deleted | an attachment is added or deleted | file name |
| expense_added | a finance entry is added | "amount - comment" |

- `author` is the signed-in user (`Current.user`), else the note's
  `updated_from` or `author`.
- Files and expenses saved together with a new note are part of its
  "created" entry (so an import does not add one entry per file).
- Changes that are not content (sharing, visited_on) are not recorded.
- Edits are grouped: an "edited" save by the same author less than 10
  minutes after the previous "edited" entry updates that entry (content and
  time) instead of adding one, so autosave does not create a version per
  pause. A pause of 10 minutes, another author, or any other event starts a
  new entry. The state before the editing session is the previous entry.
- Deleting a note deletes its history. There is no limit on stored versions;
  the page shows the latest 200.

Restoring puts back title, description and colour only. Files and expenses
are not restored (deleted files are purged from storage). A restore whose
title is taken by another note fails with the validation message.

## Page: GET /notes/:id/history

Opened from the clock box in the note's title strip. `?v=<version id>`
selects the version in front (default: newest).

- Background: a night sky (gradient with a few CSS stars).
- Stack: the selected version in front, up to 7 older ones behind it, each
  higher, smaller and darker; newer ones fly past the viewer and are hidden.
  Each card's title strip says event, author and time. Cards behind show only
  their title strip; clicking one travels back to it.
- Changes against the previous version are marked word by word (`TextDiff`,
  longest common subsequence after trimming the common start and end;
  above 400 000 cells the middle is shown as replaced). Deleted text is red
  and struck through, inserted text green. "Show changes" off shows the
  plain text of the version.
- Footer of the front card: "This is the current version" for the newest,
  "Same as the current version" when restoring would change nothing, else
  "Restore" (with the confirm dialog: "The note gets the title, text and
  colour it had on ... The current version stays in the history").
- Timeline on the right: day headings and one tick per version (time and
  event), newest at the bottom; the selected tick is highlighted. Hidden
  under 560px.
- Controls: Done (back to the note), Show changes, position "n / total",
  older / newer buttons. Keys: arrow up = older, arrow down = newer. The
  mouse wheel over the stack steps through time. The URL follows the
  selection (`history.replaceState`). Without JavaScript the ticks and
  arrows are links that reload the page.

## Acceptance

`test/models/note_version_test.rb`, `test/models/text_diff_test.rb` and the
history tests in `test/controllers/notes_controller_test.rb`. Checked in
headless Chrome on 2026-10-18 (stack, travel, plain view, restore, 390px).

## Why no database change

History is one more SQLite table with one small row per change (a few KB at
most: title, description, colour). SQLite handles millions of such rows; a
server database would only matter for several app servers writing at once,
which history does not change.

## Security Note

History keeps old text: anything once written in a note (for example a
password pasted by mistake) stays in `note_versions` after it is edited
out. Deleting the note removes it; there is no per-version delete yet (see
todo).
