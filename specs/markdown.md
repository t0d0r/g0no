# Markdown notes

Requested by the operator on 2026-10-19: "next to close button add
'markdown' switch if clicked note to be rendered as markdown", then: "if []
checkboxes are clicked on locked mode update the text as [x]; if the note is
unlocked for editing, text should be rendered as plain".

## Switch

`notes.markdown` (boolean, default false), per note, so it stays on for
everyone and on shared links. The M-down box right after the close box in
the note's title strip toggles it (`PATCH note[markdown]`); it is dark while
on. It is not a content change, so it adds no history entry.

## Display

- Locked note (see features.md, Locked notes): the description is shown
  formatted; the text area is hidden. Double-click on the formatted text
  (not on a link or check box), Enter or the padlock unlocks and shows the
  plain text for editing. After a double-click the caret is put at the same
  place in the text: the clicked block's `data-sourcepos` (kept on the
  interactive view) gives its start in the text, then the visible characters
  before the click are matched one by one in the source, skipping Markdown
  syntax and link addresses `](...)`. Enter or the padlock put the caret at
  the end. Locking again shows the
  formatted view, re-rendered from the autosave response (`html`).
- Without JavaScript both the formatted view and the text area are shown.
- Shared notes render Markdown read-only; board cards show the text without
  Markdown syntax (rendered, then tags stripped). History diffs stay on the
  plain text.

## Task lists

In the locked view, `- [ ]` / `- [x]` items are clickable check boxes.
Each carries `data-task-line`, the source line of its list item (from the
renderer's source positions, so a "- [ ]" inside a code block is never
touched). Clicking flips `[ ]` / `[x]` on that line of the text and saves.
On shared notes the boxes are disabled.

## Rendering

`MarkdownHelper#render_markdown` with the `commonmarker` gem (GitHub
flavoured: tables, task lists, strikethrough, autolinks; line breaks kept;
no heading anchors, no footnotes, no syntax highlighting). Chosen because it
ships precompiled native gems for macOS and Linux (no compiler or Rust in
the Docker build) and drops raw HTML by default.

Safety, in layers:

1. the renderer omits raw HTML and unsafe link schemes (`render.unsafe` off);
2. Rails `sanitize` with an allow-list of tags (headings, paragraphs, lists,
   emphasis, code, quotes, tables, links, check boxes) and attributes
   (`href`, `type`, `checked`, `disabled`, `align`, `start`);
3. links get `rel="noopener noreferrer nofollow"` and `target="_blank"`;
   empty `href`s are removed; only check box inputs survive.

Images are not allowed, so a note cannot load content from other sites.

## Acceptance

`test/helpers/markdown_helper_test.rb` and the Markdown tests in
`test/controllers/notes_controller_test.rb`. Checked in headless Chrome on
2026-10-19 (switch, formatted view, check box click saved as `[x]`,
double-click to plain text, re-render after editing).

## Security Note

Markdown output is generated from user text; keep all three layers above if
the renderer or its options change, and do not allow `img`, `iframe`,
`style` or event attributes.
