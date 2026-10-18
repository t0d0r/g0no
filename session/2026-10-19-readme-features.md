# 2026-10-19 - demo data and README features

## Done

- Replaced every note in the development database with 14 demo notes in a
  Terry Pratchett style (all six colours, tags, two Markdown notes, one wide
  note, three expenses), for screenshots. The operator asked for the old
  notes to be deleted; a backup of the database was taken first and kept
  outside git (git-ignored under `storage/`). The seeding script was a
  one-off in a temporary directory and is not part of the repository.
- README: added a "Features" section that lists what the app does, taken
  from the specs (features.md, markdown.md, history.md, sharing.md,
  admin.md, ui.md). Folded the old features paragraph into it.
- README: removed the "Security Note" section at the operator's request.
  The same facts are still in specs/auth.md, specs/overview.md and
  specs/docker.md.
- README: added a "Screenshots" section with two images in
  `doc/screenshots/` (board.png, note.png), made from the operator's two
  screenshots of the demo notes. Cropped to the app (browser window, tabs
  and extensions removed), scaled to 1600 and 1200 px wide and compressed
  with pngquant and optipng: 2.2 MB -> 207 KB.

## Decisions and open points

- The README keeps no security section; specs stay the place for those
  notes.
- The backup of the development database can be deleted once the operator
  no longer needs the old notes.
- The original screenshots (`SCR-*.png` in the project root) are not
  tracked; delete them or keep them out of git.

## Files touched

README.md, doc/screenshots/board.png, doc/screenshots/note.png,
session/2026-10-19-readme-features.md.

## How to run and verify

- `make check` - rubocop, brakeman and the test suite
- `make run` - development server on http://localhost:3000

## Next step

Committed as f5e8ae4 and pushed to origin/master. Continue with
todo/todo.md.
