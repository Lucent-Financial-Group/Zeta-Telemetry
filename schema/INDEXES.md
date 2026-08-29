# Computed indexes — why they are not committed anywhere

An index is **derivable by definition**. Committing one puts a cache in a store
that cannot forget.

## The measurement

Zeta, 48h to 2026-08-29 — index-shaped paths:

| versions | MiB/48h | index |
|---:|---:|---|
| 17 | **122.88** | `docs/github/prs/manifest.jsonl` |
| 25 | 7.41 | `docs/observe-events/society-index.json` |
| 8 | 0.42 | `db/drift-dashboard/roster.json` |
| 8 | 0.31 | `data/pr-categorization/index.html` |
| 19 | 0.10 | `docs/room-evidence/index.json` |

≈**65 MiB/day, about 65% of Zeta's entire daily growth**, for files whose whole
content is recomputable from records that are also stored.

`manifest.jsonl` is the clearest case: 13,574 lines indexing 13,574 shard files, and
Zeta's own source already says it is *"reproducible from the shards by
`derive-pr-manifest.ts`"*.

## Three options, and why the third wins

**1. Roll it like `by-day/`.** Rejected — wrong shape. `by-day/` works because a
measurement belongs to a *day*. An index is a snapshot of *current state*; rolling 30
days of it stores 30 near-identical copies of one thing.

**2. History-erasing overwrite** — rebuild as a new ROOT commit each time and move
the ref, so the previous version becomes unreachable. This genuinely works; measured
over 10 rebuilds of a 20,000-line index:

```
normal, 10 commits stacked        depth 10    pack 469.60 KiB
orphan-per-rebuild, after gc      depth  1    pack  47.87 KiB
```

~10× smaller and — the property that matters — **constant**: depth stays 1 no matter
how many rebuilds happen.

Two honest caveats. It needs a **force-push per update**, so it must be scoped to a
ref that never holds real history. And **GitHub does not promptly reclaim unreachable
objects** — it gc's on its own schedule, so the server-side size may not visibly drop.
Fresh clones do stay small, because a clone only fetches reachable objects.

**3. Do not put it in git.** Chosen. An index is a build artifact, so it is published
into the **Pages artifact** alongside `latest/`, exactly as `publish-latest.yml`
already does. Zero git history, no force-push, no extra repository, and it is
fetchable cross-origin (`*.github.io` sends `access-control-allow-origin: *`).

## The rule

> **An index is regenerated, never stored.** If something must be committed for an
> index to be rebuilt, that something is a record and belongs in `by-day/` or
> `corpus/` — the index itself never does.

Option 2 stays on the shelf for anything that must be reachable over the *git*
protocol rather than HTTP. Nothing needs that today: the dumb-protocol client reads
this repository's own mirror, not an index.
