# Migration map — where each Zeta telemetry path lands

Telemetry in Zeta is spread across **three** unrelated roots (`docs/`, `data/`,
`db/`) with no rule connecting them. That is the "all over the place" problem: the
path tells you nothing about retention, ownership, or whether a human wrote it.

Here there are **two** roots, and the root *is* the retention policy.

## PERMANENT — `corpus/`

| Zeta path | lands at | MiB/day | why permanent |
|---|---|---:|---|
| `docs/history/pr-reviews/**` | `corpus/pr-reviews/` | 0.43 | review threads paired with fixing commits; training data, not API-recoverable |

## ROTATING — `by-day/YYYY/MM/DD/`

| Zeta path | MiB/day | produced by |
|---|---:|---|
| `data/tick-history.json`, `data/tick-latest.json` | 10.5 | heartbeat agents |
| `data/platform-drift.json` | 8.8 | drift jobs |
| `docs/observe-events/**` | 5.7 | society/observe lanes |
| `db/mutation-findings/*.jsonl` | 4.8 | mutation runs |
| `data/ci-runs.jsonl` | 2.0 | CI, also derivable from the Actions API |
| `data/tick-reasoning.jsonl` | 1.2 | heartbeat agents |
| `docs/drift-events/**`, `docs/room-evidence/**` | <1 | drift / evidence lanes |
| `db/drift-dashboard/**` | 0.2 | drift dashboard |

## NOT MIGRATED — deleted, not moved

| Zeta path | MiB/day | disposition |
|---|---:|---|
| `docs/github/prs/manifest.jsonl` | **65.35** | **derivable; do not commit anywhere** |
| `docs/github/prs/shards/**` | — | index for the above |

`manifest.jsonl` held 13,574 lines against 13,574 shard files — a line-for-line
duplicate — and Zeta's own code already declares it *"reproducible from the shards by
`derive-pr-manifest.ts`"*. At 9 rewrites a day of a ~7.3 MiB file it was **64% of
Zeta's entire daily growth**, for a file that is a cache of something else.

An index belongs in a build artifact, not in git history. It can be regenerated into
the published Pages output on every run at zero history cost, exactly like `latest/`.

## The rule this map encodes

> **If it can be regenerated, do not commit it. If it decays, put it in `by-day/`.
> If it is the record, put it in `corpus/` and never delete it.**

Three questions, and the answer to all three is visible in the path — which is what
`docs/` + `data/` + `db/` could not do.
