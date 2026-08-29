# corpus/ — the permanent record. NEVER rotates.

Everything here is kept forever. This directory is the reason a blanket
"30-day rolling window" would have been wrong.

## Why this is separate from `by-day/`

`by-day/` holds **measurements**: ticks, drift samples, CI run records. Their value
decays — nobody asks what the tick rate was six weeks ago, and keeping them forever
is what made Zeta's history grow ~100 MiB/day.

`corpus/` holds **the record of decisions and the reasoning behind them**. Its value
does not decay; it increases as the corpus grows.

## `corpus/pr-reviews/`

One document per pull request, each carrying `## Review threads`, `## Outcome`, and
`## Fix commits (touching thread paths)` — which is to say **a review comment paired
with the commit that resolved it.** That pairing is supervised training data, and it
is not reconstructible from the GitHub API after the fact: threads get edited,
resolved, and deleted, and the linkage to the fixing commit is computed at archive
time, not stored upstream.

Deleting this to save space would be deleting the only artifact here that is worth
keeping.

## It is cheap, which is the point

Measured on Zeta 2026-08-29: this corpus grows **0.43 MiB/day (~157 MiB/year)**,
while the *index* pointing at it churned **65.35 MiB/day** — 64% of Zeta's entire
daily growth.

The expensive thing was the derivable index. The valuable thing is nearly free. Any
retention policy that treats them alike has it exactly backwards.

## Rule

- Nothing in `corpus/` is ever deleted by a rollover job.
- A rollover job that can reach `corpus/` is a bug, not a feature.
- If something here can be regenerated from an API, it belongs in `by-day/` or
  nowhere.
