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
by-day/YYYY/MM/DD/     MEASUREMENTS — rotates at 30 days
corpus/                THE RECORD — never rotates
schema/                what the records mean
```

Two roots because there are two kinds of data with **opposite** retention needs, and
a single policy over both is wrong in one direction or the other.

There is deliberately **no `current/` directory**. See "Reading the latest" below —
an always-current file committed to git does not grow, but its *history* does,
forever, which is the exact cost this repository exists to avoid.

`by-day/` is the whole retention mechanism. Rolling off a month is:

```sh
git rm -r --quiet by-day/2026/07 && git commit -m "roll: drop 2026-07"
```

One directory, one commit, no per-file logic, no manifest to keep in step. This is
the property being bought — and it is why a dated record must never be written
anywhere except under `by-day/`. A file that escapes the date partition is a file
the rollover cannot find.

Everything measured lands in `by-day/`. Nothing is overwritten in place.

`corpus/` is the exception that proves the rule: it is append-only and **permanent**.
It holds the PR review archives — review threads paired with the commits that
resolved them — which are training data and are not reconstructible from the API
once threads are edited or deleted. See `corpus/README.md`.

The counter-intuitive part, measured: the permanent corpus costs **0.43 MiB/day**,
while the *derivable index* pointing at it churned **65.35 MiB/day**. The valuable
half is nearly free; the expensive half is the disposable one. A retention policy
that treated both as "PR data" would delete the wrong one.

## Reading this data from Zeta's GitHub Page

Both hosts send `access-control-allow-origin: *` (verified 2026-08-29), so a static
page can fetch from here directly with no token and no proxy:

### Reading the latest — and why it is not a file in this repo

`publish-latest.yml` assembles the newest record of each kind and publishes it as a
**GitHub Pages artifact**. Actions uploads that artifact; it is never committed, so
republishing it every few minutes costs **zero git history**. That is the whole
point: a committed `current/tick-latest.json` would be a new blob on every write,
forever.

```js
const res  = await fetch(
  "https://lucent-financial-group.github.io/Zeta-Telemetry/latest/tick-latest.json");
const tick = await res.json();
```

`*.github.io` sends `access-control-allow-origin: *` (verified 2026-08-29, 600s
cache), so Zeta's Page can read it with no token and no proxy. `_meta.json` beside
it carries `generated_at` and `commit` so a consumer can distinguish fresh from
stale instead of inferring it.

Historical records are still readable straight from git when a consumer wants a
specific day:

```
https://raw.githubusercontent.com/Lucent-Financial-Group/Zeta-Telemetry/main/by-day/2026/08/29/<record>.json
```

**Release assets were considered and rejected** for the browser path: they are also
zero-history, but the redirect chain to `release-assets.githubusercontent.com`
sends no ACAO header, so page JavaScript cannot read them cross-origin. They remain
usable from CI and scripts.

**This only works because this repository is public.** A private one would require a
credential the page cannot safely hold. That is a constraint on the design, not a
preference.

## Retention

**`by-day/` — rolling 30 days.** Measurements whose value decays.

**`corpus/` — forever.** The record. A rollover job must never be able to reach it;
see `corpus/README.md`.

Nothing else in this repository accumulates, so nothing else needs a policy.
