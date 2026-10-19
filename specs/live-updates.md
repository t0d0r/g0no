# Live updates

Operator, 2026-10-19: "can we have live updates over shared link and
edited", "using cables or similar?".

## Behaviour

- An open note page (`/notes/:id`, `/notes/:id/edit`) and an open share page
  (`/s/:token`) reload themselves within about a second of the note
  changing in another window or browser: title, text, colour, Markdown,
  wide, files, expenses, a restore from history, or sharing.
- The page reloads where it is scrolled (`turbo-refresh-scroll` set to
  `preserve`; `setUpPage` puts the scroll back once the text areas have
  their height).
- A page does not reload because of its own saves. Autosave and the wide box
  use Turbo's `fetch`, and Turbo forms do as well; these send
  `X-Turbo-Request-Id`, the server puts that id on the refresh, and Turbo
  skips refreshes for its own recent requests.
- **Work in progress is never thrown away.** A refresh waits while the page
  is busy and runs once it is idle (checked every second):
  - the note is unlocked for editing, has typed text not saved yet, or is
    saving;
  - another field has been typed in or a file chosen (expense, file
    comment, share password);
  - a text field that is not read-only has focus;
  - a dialog (preview, confirmation) or a menu (`<details>`) is open.
  While the note itself is being edited, a line under the text says that it
  changed somewhere else and will reload when editing stops.
- **Concurrent edits.** Autosave of an existing note sends only the fields
  (title, text, colour) that changed since the last save. Changing the text
  therefore does not put back a colour someone else just picked. If two
  people change the same field, the last save wins and both versions stay
  in History (history.md).
- A stopped or replaced share link shows "Link not available" on the open
  share page. A password-protected share page subscribes only after it is
  unlocked.
- A note deleted while its page is open: the page goes to the board with
  "That note was deleted." (`show` and `edit` redirect for a missing note;
  other actions still answer 404).
- The board (`/notes`) does not update live.

## Design

- **Action Cable with Turbo Streams "refresh" (Turbo 8 page refresh).**
  Pages subscribe with `turbo_stream_from`. The server broadcasts only
  `<turbo-stream action="refresh">`, never note content. Each page fetches
  itself again over HTTP, so sign-in, the share token and the share
  password are checked as on any request.
- Streams:
  - the note's pages: the note (`turbo_stream_from @note`);
  - the share page: `Note#share_stream`, the note plus a SHA-256 hash of
    the token. The token itself stays out of Action Cable's logs and the
    signed stream name, which is signed, not encrypted.
- Broadcasts: `Note#broadcast_refresh_to_viewers` runs after commit of a
  note's update or destroy, and of a `NoteAttachment` or `FinanceEntry`.
  It sends to the note stream and to the share streams of the current and
  the previous token. It uses `broadcast_refresh_later`, which turbo-rails
  debounces (0.5 s per stream and request), so a burst of saves sends one
  refresh. The jobs run on Active Job's default in-process adapter.
- **Adapter: `async`** (`config/cable.yml`). The app runs one Puma process
  with threads, so every subscription and broadcast meets in that process.
  Several processes (Puma workers, several containers) would need a shared
  adapter such as solid_cable.
- Refresh method `replace` (Turbo's default), not `morph`. `setUpPage`
  attaches listeners to elements; a morph keeps the elements, so the
  listeners would be attached twice.
- Client: `application.js` wraps the `render` of each refresh stream in a
  `turbo:before-stream-render` listener, which holds the refresh while
  `pageIsBusy()`.
- `application.js` is loaded with `data-turbo-eval="false"`: Turbo shows an
  error response (a revoked share link answers 404) by swapping the whole
  document, which would otherwise run the script a second time.
- Without a WebSocket (blocked proxy, old browser) pages work as before, just
  without live updates; the Action Cable client keeps retrying.

## Deployment

- WebSockets go to `/cable` on the same host. Thruster passes them through.
  In front of it, Apache needs `upgrade=websocket` on the `ProxyPass`
  (Apache 2.4.47+, see `deploy/apache.conf`).
- Action Cable accepts only connections whose `Origin` is the app's own host
  (`allow_same_origin_as_host`). Behind Apache this works because of
  `ProxyPreserveHost On` and `RAILS_ASSUME_SSL`.

## Acceptance

- `test/integration/live_updates_test.rb`: the pages subscribe, a locked
  share page does not, saves broadcast one refresh to both streams, the
  refresh carries the request id, files and expenses broadcast, a revoked
  link's stream is told, and a deleted note redirects.
- Checked in Chrome on 2026-10-19 with two signed-in windows and one share
  window:
  - editor A's save refreshed the share page and editor B, with B's scroll
    kept at 900px, and A did not refresh itself;
  - with B unlocked, a colour change by A waited and showed the notice;
    after B locked the note, it refreshed with the new colour and B's text
    kept;
  - stopping sharing showed "Link not available";
  - deleting the note sent B to the board with the notice.

## Security Note

- Anyone can open the WebSocket. The connection is not tied to a user,
  because share viewers are anonymous. A subscription needs a stream name
  signed with `secret_key_base`, which is handed out only on pages the
  viewer may see.
- A signed name does not expire. A user who is removed later, or someone
  who once had a share link, could keep receiving "refresh" signals. The
  signal carries only the fact that the note changed, never its content.
  Replacing or stopping the share link changes the share stream.
- Rotating `SECRET_KEY_BASE` invalidates all signed stream names.
