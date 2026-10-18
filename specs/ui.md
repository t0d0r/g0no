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
  note") and a delete box. Title and description are borderless fields on
  the paper; the description grows with its content. For an existing note
  the Save/Cancel bar is hidden until the title or description changes;
  Cancel restores the saved text. Expenses and files are sections below,
  each with a one-line form.
- **Account pages** (sign in, sign up, password reset): a small yellow
  sticky centred on the desk.
- **Flash messages:** white rounded banners above the content with a
  coloured left edge (blue notice, red alert) and a close button.

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
