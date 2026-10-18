# User interface

Requested by the operator on 2026-10-18: "styling like Apple sticky notes".
Styles: `app/assets/stylesheets/application.css`. Behaviour:
`app/assets/javascripts/application.js`. No CSS or JS framework.

## Look

- **Desk:** neutral warm-grey background (`--desk`), darker in dark mode.
- **Menu bar:** translucent bar at the top, like the macOS menu bar: app
  name, "Content" link, and when signed in the user name and logout.
- **Sticky paper:** square corners (3px), soft shadow, a slightly darker
  title strip (`.sticky__bar`) of the same colour. Notes keep their paper
  colours in dark mode, as Stickies does.
- **Colours** (paper / title strip), as in the Stickies Color menu:

  | name | paper | strip |
  |------|-------|-------|
  | yellow | #fff6a8 | #f5e270 |
  | blue | #cfe7fc | #a9d1f5 |
  | green | #d4f4c6 | #ade5a0 |
  | pink | #fcd4e6 | #f4b0cf |
  | purple | #e3d8fc | #c9b9f5 |
  | gray | #efeeea | #d8d6cf |

  A note's colour is `id mod 6` in that order (`NotesHelper#sticky_color`),
  so it never changes. New notes are yellow.
- **Font:** the system font (San Francisco on Apple devices).
- **Expense amounts** are red and use tabular figures.

## Pages

- **Board** (index, by tag): responsive grid of cards, at least 210px wide
  (150px under 560px). The first card is a dashed "+ New note" tile.
  Hovering a card lifts it slightly.
- **Note window** (show, new, edit): one sticky, max 760px wide. Title strip
  with a close box (back to the list), a caption ("edited ... ago" or "New
  note"), the colour menu, the history box and a delete box. Title and
  description are borderless fields on the paper; the description grows
  with its content. Changes save themselves (features.md, Autosave). Expenses and files are sections below,
  each with a one-line form.
- **Account pages** (sign in, sign up, password reset): a small yellow
  sticky centred on the desk.
- **Flash messages:** small stickies pinned at the top right under the menu
  bar (operator: notices should look like the site itself): yellow paper
  with caption "Notice" for notices, pink with "Attention" for alerts, a
  close box in the title strip. Notices fade out after 6 seconds (paused
  while hovered or focused); alerts stay until closed. They slide in, and
  do not animate with reduced motion.

- **Menu bar search:** a search field and a round colour button between the
  links and the user name. The button opens a small menu of the six colours
  plus "All colours"; picking one searches at once. On phones the search
  field takes its own row under the links.
- **Colour menu:** six small squares in a note's title strip, the current one
  ringed. Fixed set only.
- **Card badges:** paperclip + file count, link icon for shared notes, then
  the total. Icons are inline SVG (`NotesHelper#icon`), no image files.
- **Preview dialog:** a large sticky in the note's colour over a dimmed desk;
  title strip with close, file name and previous/next boxes; footer with
  size, comment, position and a blue Download button.
- **Confirm dialog:** a small yellow sticky with a red "!" badge, a bold
  question, a sentence on what will happen, Cancel and a red action button.
- **Drop overlay:** dashed blue border and "Drop files to attach them to
  this note" over the note window while files are dragged onto it.
- **Sort button:** small text button with an up/down arrow icon after the
  note count, showing the current order ("Oldest first", ...).
- **Menu bar tools:** sun/moon theme button and three "A" buttons (small,
  medium, large letter) for Normal / Big / Extra big text. In dark
  theme the desk, menu bar and menus darken; notes keep their paper colours.
  Dark colours are CSS variables, redefined under
  `@media (prefers-color-scheme: dark) :root:not([data-theme="light"])` and
  `:root[data-theme="dark"]`.
- **Description field:** grows with its text and never shows a scroll bar
  (the height includes the border; it is measured again on resize, when
  fonts load and when the text size changes). Without JavaScript it keeps a
  normal scroll bar so no text is hidden.
- **Markdown box:** M-down icon right after the close box; dark while the
  note is shown as Markdown (markdown.md). Formatted text uses the note's
  font; code and tables get a light grey background and rules.
- **Lock:** padlock box in the title strip (closed when locked, open while
  editing). While editing, the title and description show their dashed
  rules; locked fields have a default cursor.
- **Copy box:** a small copy icon in the note's title strip (and on shared
  notes) puts the note's text on the clipboard, or the title when there is
  no text; it shows a green check mark for 1.5 seconds. Falls back to
  `execCommand("copy")` where the Clipboard API is unavailable (plain HTTP
  other than localhost). Hidden without JavaScript.
- **Site icon:** a small yellow sticky with a darker title strip and three
  text lines: `public/icon.svg` (source), `favicon.ico` (16/32/48 PNG
  entries), `icon.png` (512) and `apple-touch-icon.png` (180, on the desk
  colour because iOS does not allow transparency).
- **Autosave status:** small grey text under the description, red when a
  save fails.
- **Colour menu dice:** a small five-dot die after the swatches; it turns a
  little on hover.
- **History:** night-sky page; versions stacked like Time Machine windows,
  timeline at the right, controls at the bottom; green insertions, red
  struck-through deletions (history.md). Clock box in the note title strip.
- **Admin:** coloured stat tiles, grey sticky panels with tables.
- **Shared note:** the note window without boxes or forms, caption "Shared
  note"; password page and "link not available" page as small stickies.

## Constraints

- Works at 390px width with no horizontal scrolling.
- Visible focus rings on links, buttons and fields; every form field has a
  label (visually hidden where the placeholder shows it).
- Delete actions ask for confirmation in the confirm dialog (`data-confirm`,
  `data-confirm-title`, `data-confirm-button` via
  `ApplicationHelper#confirm_data`).

## Translations

All UI text is in `config/locales/{en,bg}.yml` (`ui.*`, `flash.*`) and
Devise text in `config/locales/devise.{en,bg}.yml`. The locale follows the
browser (see features.md).

## Verified

Screenshots were taken on 2026-10-18 with headless Chrome at 1280px and
390px for the sign-in (with an error), sign-up, board and note pages. Later
the same day (puppeteer-core driving Chrome): colour filter, search, note
with colour menu, image / PDF / text previews, confirm dialog, drop overlay
and upload, sharing section, admin panel, shared note locked / wrong
password / unlocked, and the board at 390px.

## Security Note

User text (titles, descriptions, comments, file names) is always rendered
escaped; the CSS and JS are served from the app itself, with no third-party
assets.
