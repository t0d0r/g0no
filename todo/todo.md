# Todo

- [x] upgrade from Rails 3.0.5 to Rails 8.1.4 on Ruby 4.0 (specs/overview.md)
- [x] replace CouchDB with SQLite and Active Storage (specs/data-model.md)
- [x] import task for the 2011 CouchDB data (specs/couchdb-import.md)
- [x] Devise 5 with support for 2011 password hashes (specs/auth.md)
- [x] replace jQuery/Prototype with plain JavaScript; compile Sass to CSS (specs/overview.md)
- [x] Docker image and compose file (specs/docker.md)
- [x] Makefile, specs, todo and session notes per ../AGENTS.md
- [ ] run `make import` against the real CouchDB and check the notes (specs/couchdb-import.md)
- [ ] move the old users database to storage/ and migrate it, or recreate users (specs/auth.md)
- [ ] decide whether registration stays open; restrict it if the app is public (specs/auth.md)
- [ ] configure SMTP from environment variables so password reset emails work (specs/auth.md)
- [ ] expose the tag field in the note form (it was commented out in 2011) (specs/features.md)
- [ ] add gitleaks as a pre-commit hook (../AGENTS.md)
