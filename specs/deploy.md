# Production deployment

Operator, 2026-10-19: deploy to the operator's Debian server "in docker like
redmine", with Podman, and "podman should run in separate user, i need todor
to be not affected in case of exploit".

## Layout

| part | where |
|------|-------|
| system user | `g0no` (system account, no login shell, home `/srv/g0no`, own subuid/subgid range, lingering so its services run without a login) |
| container | rootless Podman as `g0no`, from the quadlet `deploy/g0no.container`, installed as `~g0no/.config/containers/systemd/g0no.container`; systemd user service `g0no.service`, `Restart=always` |
| image | `localhost/g0no:latest` (also tagged with the git revision), built on the server from `Dockerfile` |
| data | `~g0no/storage` -> `/rails/storage` (SQLite databases and uploads); files belong to `g0no` on the host (`UserNS=keep-id:uid=1000,gid=1000`) |
| settings | `~g0no/g0no.env`, mode 600, owner `g0no`; never in git |
| network | the container publishes only `127.0.0.1:3182`; Apache on the host is the only way in |
| TLS | Apache vhost from `deploy/apache.conf`, Let's Encrypt certificate from certbot (webroot of the existing ACME alias), renewed by `certbot.timer`; PageSpeed is disabled for this vhost because its global CSS rewrite emitted zstd data without `Content-Encoding` |

The container runs with `no-new-privileges` and all capabilities dropped;
the sysctl `net.ipv4.ip_unprivileged_port_start=80`, in the container's own
network namespace only, lets the image's user still listen on port 80.
A process that escapes it is the unprivileged user `g0no`, which cannot
read the operator's home or other apps' files.

Why not the Redmine pattern: Redmine on the same server runs as root
Podman on the host network. The operator asked for a separate user instead.

Live updates (live-updates.md) use a WebSocket at `/cable`; the vhost's
`ProxyPass` carries `upgrade=websocket` (Apache 2.4.47+) so it passes
through. An installed vhost without it keeps working, only without live
updates.

Why a hand-written vhost and not an ISPConfig site: the operator chose it
(2026-10-19); it is the pattern of another proxied service on the server
and can be set up over ssh.

## Settings (`~g0no/g0no.env`)

`SECRET_KEY_BASE` and `ADMIN_PASSWORD` are generated on the server
(`openssl rand`) and never leave it. `APP_HOST` and `MAILER_SENDER` use the
public host name. `RAILS_FORCE_SSL=true`, `RAILS_ASSUME_SSL=true`,
`REGISTRATION_OPEN=false`, `ADMIN_USERNAME=admin`. The operator asked for
the admin password to be written on the host: a copy is in a mode 600 file
in the operator's home. Change the password at `/admin` after the first
sign-in; changing the env file later does not change it (auth.md).

Production starts with an empty database and only the admin user (operator,
2026-10-19).

## Deploy (`make deploy`)

`DEPLOY_HOST=<ssh host> make deploy` runs `bin/deploy`:

1. `git archive HEAD` is unpacked into `~g0no/src` (only committed code is
   shipped; a dirty tree gives a warning).
2. As `g0no` (`sudo runuser -l g0no`): `podman build --format docker` (the
   OCI format would drop the image's `HEALTHCHECK`) tags
   `localhost/g0no:<rev>` and `:latest`, `systemctl --user daemon-reload`
   and `restart g0no`,
   wait up to two minutes for `/up` on `127.0.0.1:3182`, keep the three
   newest revision images and prune the rest.
3. The container entrypoint migrates the database and runs the seed.

The ssh user needs passwordless sudo to root; `sudo -u g0no` is not used
because that rule may require a password.

## One-time server setup

As root on the server, with `<host>` the public host name:

1. `useradd --system --user-group --create-home --home-dir /srv/g0no --shell /usr/sbin/nologin g0no`,
   `chmod 750 /srv/g0no`, `usermod --add-subuids <free range> --add-subgids <free range> g0no`
   (a range of 65536 not used by another user in `/etc/subuid`),
   `loginctl enable-linger g0no`.
2. As `g0no`: create `~/storage`, `~/.config/containers/systemd`, and
   `~/g0no.env` with umask 077 (settings above).
3. Install `deploy/g0no.container` into `~g0no/.config/containers/systemd/`.
4. Run `make deploy`. It reloads systemd, so the quadlet becomes
   `g0no.service`, and starts it; the quadlet's `[Install]` section starts
   it again at boot.
5. Apache: install `deploy/apache.conf` with the host name filled in, first
   with only the port 80 vhost, `a2ensite`, `apache2ctl configtest`,
   reload; `certbot certonly --webroot -w <acme webroot> -d <host>`; then
   the full file, configtest, reload.

## Operating

- Status: `sudo runuser -l g0no -s /bin/bash -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) podman ps'`
- Logs: `sudo journalctl _UID=<g0no uid>`; the server mounts `/proc` with
  `hidepid`, so other users do not see the app's processes.
- Rollback: tag an older `localhost/g0no:<rev>` as `latest` and restart
  the service as `g0no`.

## Acceptance

- `https://<host>/up` returns 200; `http://` redirects to `https://`.
- Sign-in works with the admin user; there is no sign-up link and
  `/users/sign_up` redirects to sign-in.
- After a server reboot the app comes back without anyone logging in.
- `ps` on the server shows the app's processes owned by `g0no`.

## Verified

2026-10-19, on the server: `/up` 200 over HTTPS, HTTP redirects to HTTPS,
certificate valid, HSTS and secure session cookie set, sign-up URL
redirects to sign-in and the link is hidden, admin sign-in reaches the
board and `/admin`, container healthy, Puma, Thruster, conmon and pasta
run as `g0no`, data files in `~g0no/storage` belong to `g0no`, a second
`make deploy` replaced the running revision. Not yet verified: a server
reboot, file uploads through Apache (mod_security is loaded on the
server).

## Security Note

Keep `g0no.env` and the admin password copy at mode 600 and out of git.
The password copy is in the operator's home; delete it once the password
has been changed at `/admin`. Password reset emails do not work until SMTP
is configured (auth.md), so the admin password must not be lost. Back up
`~g0no/storage` (SQLite databases and uploads); nothing else holds the
data.
