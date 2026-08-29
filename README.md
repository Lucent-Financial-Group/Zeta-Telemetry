# Zeta-Telemetry

Machine-generated telemetry and heartbeat data for
[Zeta](https://github.com/Lucent-Financial-Group/Zeta).

**Nothing here is human-authored, and nothing here is source.** If you are looking
for documentation, it is in Zeta under `docs/`. This repository exists so that
`docs/` in Zeta can go back to meaning *documents a person wrote*.

## Why this is a separate repository

Measured on Zeta's `main` over 24h (2026-08-29): **101.7 MiB of new blob content,
of which 100.2 MiB — 98.5% — was telemetry.** Real engineering work was 1.5 MiB.
File count told the same story: 54,649 files, +857/day, 80% of the new ones
machine-generated.

Git cannot forget. A commit's tree is immutable, so "delete the old telemetry"
inside Zeta would mean rewriting Zeta's history — a force-push that invalidates
every clone and worktree, for data nobody reads after a month.

Here, history is **disposable by design**. Rolling data off is an ordinary commit;
and if the pack ever needs to be genuinely reclaimed, this repository can be
re-rooted or re-created without touching a single line of Zeta's history.

## Layout — the shape IS the retention policy

```
by-day/YYYY/MM/DD/     every dated record lands here, and ONLY here
current/               small always-current snapshots (latest tick, rosters)
schema/                what the records mean
```

`by-day/` is the whole retention mechanism. Rolling off a month is:

```sh
git rm -r --quiet by-day/2026/07 && git commit -m "roll: drop 2026-07"
```

One directory, one commit, no per-file logic, no manifest to keep in step. This is
the property being bought — and it is why a dated record must never be written
anywhere except under `by-day/`. A file that escapes the date partition is a file
the rollover cannot find.

`current/` is deliberately tiny and is *overwritten*, never appended. Anything that
grows without bound belongs in `by-day/`.

## Reading this data from Zeta's GitHub Page

Both hosts send `access-control-allow-origin: *` (verified 2026-08-29), so a static
page can fetch from here directly with no token and no proxy:

```js
const res  = await fetch(
  "https://raw.githubusercontent.com/Lucent-Financial-Group/Zeta-Telemetry/main/current/tick-latest.json");
const tick = await res.json();
```

`raw.githubusercontent.com` caches for 300s, which is well inside any telemetry
refresh interval. The Pages build may also check this repository out at deploy time
when a baked-in snapshot is preferable to a live fetch.

**This only works because this repository is public.** A private one would require a
credential the page cannot safely hold. That is a constraint on the design, not a
preference.

## Retention

Rolling window, currently **30 days** in `by-day/`. `current/` is exempt — it is
bounded by construction.
