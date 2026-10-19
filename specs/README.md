# Specs

| file | summary |
|------|---------|
| [overview.md](overview.md) | what g0No is, the stack, and the decisions of the Rails 8 migration |
| [data-model.md](data-model.md) | tables for notes, tags, finance entries and attachments |
| [features.md](features.md) | pages and behaviour the app must keep |
| [ui.md](ui.md) | look and feel: macOS Stickies style, colours, layout, translations |
| [admin.md](admin.md) | admin flag, admin panel for users, stats and shared notes |
| [markdown.md](markdown.md) | per-note Markdown switch, formatted view, clickable task lists |
| [history.md](history.md) | version history of notes, Time Machine style view and restore |
| [sharing.md](sharing.md) | public share links, optionally with a password |
| [live-updates.md](live-updates.md) | note and share pages reload themselves when the note changes (Action Cable) |
| [auth.md](auth.md) | Devise setup, sign-in by username or email, legacy password hashes |
| [couchdb-import.md](couchdb-import.md) | one-off import of the 2011 CouchDB data |
| [docker.md](docker.md) | Docker image, compose file and environment variables |
| [deploy.md](deploy.md) | production on a server: rootless Podman under its own user, Apache, certbot |

## Security Note

Specs are committed. Describe credentials and hosts in general terms only.
