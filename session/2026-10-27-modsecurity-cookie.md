# 2026-10-27 - ModSecurity exclusion for the g0no session cookie

## Done

- The operator asked to apply to g0no the ModSecurity fix made for
  Stopan the same day: CRS rule 941120 can match the random encrypted
  Rails session cookie and lock a browser out (shown as 404).
- No such block was found in g0no's error logs; the fix is preventive.
- Site 24's Apache directives got a `SecAction` (id 13182) that removes
  `_g0no_session` from the CRS rule targets, through the ISPConfig Remote
  API (`sites_web_domain_update`), with the current `log_retention` and
  `pm_*` values passed unchanged. The record before the change is saved on
  the server for a rollback. ISPConfig regenerated the vhost and
  restarted Apache.
- Verified: pattern in the session cookie -> app (302); same pattern in
  another cookie and `<script>` in the query -> blocked; `/up` 200;
  `/cable` 101; HSTS, nosniff, X-Frame-Options; configtest OK; Stopan
  unaffected. Details: specs/deploy.md "ModSecurity and the session
  cookie".

## Decisions

- Per-request `SecAction` with `ctl:ruleRemoveTargetByTag`, not
  `SecRuleUpdateTargetByTag`: the latter had no effect inside a
  VirtualHost on Stopan (rules are loaded at server level).
- The change went through ISPConfig (the vhost is site 24 now), not a
  hand-edited file, so a resync keeps it.

## Open

- g0no sends no Content-Security-Policy (initializer commented out);
  added to todo.
- specs/deploy.md still describes the vhost as hand-written in "Layout";
  only the new section states it is ISPConfig site 24.

## Files touched

specs/deploy.md, todo/todo.md, this note. On the server: site 24's
Apache directives (through the API).

## How to verify

`make check`; on the server the checks listed in specs/deploy.md.

## Next step

Add a Content-Security-Policy to g0no (todo).

## Security Note

The exclusion covers only the encrypted session cookie of this site;
everything else is still inspected by the WAF. No secrets were printed or
written to the repository.
