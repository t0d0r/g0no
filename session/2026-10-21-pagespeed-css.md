# 2026-10-21 - production CSS repair

## Done

- Investigated the unstyled shared-note page. The stylesheet returned HTTP 200
  and `Content-Type: text/css`, but its first bytes were Zstandard (`28 b5 2f
  fd`) and it had no `Content-Encoding` header, so browsers rejected it.
- Confirmed globally enabled Apache `mod_pagespeed` rewrote the page assets.
- Added `ModPagespeed off` inside each g0no HTTP/HTTPS vhost, guarded by
  `IfModule pagespeed_module`, after operator approval. Apache configuration
  validation passed and Apache was reloaded.
- Kept a timestamped copy of the prior production vhost next to its source
  configuration file for rollback.
- Verified externally: the shared page now references the unrewritten CSS,
  the stylesheet is readable CSS text, `/up` returns 200, and a new browser
  load is styled correctly.

## Decision

Keep PageSpeed disabled only for this proxied application vhost. The global
module remains available for other sites; disabling it here avoids corrupt
asset delivery until its compression/header behavior is understood.

## Files touched

`deploy/apache.conf`, `specs/deploy.md`, `todo/todo.md`, this session note.

## How to verify

- `curl -sS https://g0no.linuxfan.org/up` returns `ok`.
- Fetch a public page and confirm the stylesheet URL is `/assets/application-*.css`.
- The CSS response is `text/css` and starts with CSS text rather than the
  Zstandard magic bytes.

## Next step

Run the normal project checks, then commit the vhost template and
project-record updates.
