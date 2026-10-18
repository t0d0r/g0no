# 2026-10-19 - production deployment

## Done

- Sign-up switch `REGISTRATION_OPEN`: open in development and test, closed
  by default in production (operator's choice). Hidden link, new/create
  redirect to sign-in, own-account edit still works. Tests in
  `test/controllers/registrations_controller_test.rb`. specs/auth.md.
- Deployed to the operator's Debian server with rootless Podman under a
  new system user `g0no` (operator: the app must not run as root or as the
  operator's login user). Quadlet `deploy/g0no.container`, app on
  127.0.0.1:3182 only, Apache vhost from `deploy/apache.conf` with a
  Let's Encrypt certificate from certbot (webroot of the server's existing
  ACME alias, renew hook reloads Apache). specs/deploy.md.
- `make deploy` (`bin/deploy`, needs `DEPLOY_HOST`) ships HEAD with git
  archive, builds on the server as `g0no` and restarts; keeps three
  revision images.
- Production started empty with only the admin user. Secrets were
  generated on the server and never left it; at the operator's request the
  admin password is in a mode 600 file in the operator's home on the
  server.

## Decisions

- Separate system user with rootless Podman instead of the root Podman
  pattern used by the older Redmine install (operator).
- Hand-written Apache vhost + certbot, not an ISPConfig site (operator).
- Sign-up closed in production (operator).
- Empty production database (operator).
- Port 80 inside the container with all capabilities dropped: allowed by
  the namespaced sysctl `ip_unprivileged_port_start=80`.
- `podman build --format docker` keeps the image HEALTHCHECK.
- `sudo runuser -l g0no` instead of `sudo -u g0no`, because the ssh user's
  passwordless sudo rule covers running as root only.

## Open

- Reboot test and an upload through Apache / mod_security not done yet.
- SMTP is not configured, so password reset mails do not work.
- Backups of `~g0no/storage` are not set up.
- The admin password copy in the operator's home should be deleted after
  the password is changed at /admin.

## Files touched

app/controllers/users/registrations_controller.rb, config/application.rb,
config/routes.rb, config/locales/{en,bg}.yml,
app/views/devise/shared/_links.html.erb,
test/controllers/registrations_controller_test.rb, bin/deploy,
deploy/g0no.container, deploy/apache.conf, Makefile, compose.yaml,
.env.example, specs/{deploy,auth,overview,docker,README}.md, todo/todo.md.

## How to run and verify

- `make check` - rubocop, brakeman, 111 tests
- `DEPLOY_HOST=<ssh host> make deploy` - build and restart on the server
- `curl https://<public host>/up` - 200

## Next step

Sign in, change the admin password at /admin, delete the password copy on
the server; then set up backups of `~g0no/storage`.
