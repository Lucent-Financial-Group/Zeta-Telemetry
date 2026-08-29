#!/usr/bin/env bash
# Refuse any MODIFICATION to a record under by-day/ or corpus/.
#
# THE INVARIANT
#   A machine-written record is written ONCE. Every write creates a new file.
#   Nothing is ever rewritten in place.
#
# WHY IT IS ENFORCED RATHER THAN DOCUMENTED
#   Rewriting a tracked file in place does not grow the FILE, so it looks free.
#   It is not: git writes a new blob on every write, forever. Measured on Zeta
#   over 48h, that single pattern accounted for 172.8 MiB against 0.9 MiB from
#   write-once shards -- 99.5% of the growth, from files that never got bigger.
#
#     docs/github/prs/manifest.jsonl   17 versions   122.88 MiB
#     data/tick-history.json           59 versions    16.78 MiB   (a 291 KiB file)
#     data/platform-drift.json         53 versions    11.05 MiB   (a 231 KiB file)
#
#   Every one of those is a file a reasonable person would call "small".
#   The cost is invisible at the filesystem and only appears in history, which
#   is exactly why a human reviewer will not catch it and a check must.
#
# SCOPE
#   by-day/  records may be ADDED, and DELETED by a rollover. Never modified.
#   corpus/  records may be ADDED only. Never modified, never deleted -- it is
#            the permanent record (see corpus/README.md).
#   Everything else (README, schema/, .github/, tools/) is human-authored prose
#   and is expected to be edited.

set -euo pipefail

BASE="${1:-}"
HEAD="${2:-HEAD}"
if [ -z "$BASE" ]; then
  echo "usage: check-append-only.sh <base-ref> [head-ref]" >&2
  exit 2
fi

# name-status gives A/M/D per path; that is precisely the distinction we need.
changes="$(git diff --name-status "$BASE" "$HEAD" -- by-day corpus || true)"

if [ -z "$changes" ]; then
  echo "check-append-only: no records touched between $BASE and $HEAD"
  exit 0
fi

violations=0
added=0; deleted=0
while IFS=$'\t' read -r status path rest; do
  [ -z "${status:-}" ] && continue
  case "$status" in
    A)
      added=$((added + 1))
      ;;
    D)
      if [[ "$path" == corpus/* ]]; then
        echo "REFUSED: deletion under corpus/ -- the permanent record is never deleted"
        echo "         $path"
        echo "         If a rollover job reached this path, the rollover is the bug."
        violations=$((violations + 1))
      else
        deleted=$((deleted + 1))
      fi
      ;;
    M)
      echo "REFUSED: in-place modification of a record"
      echo "         $path"
      echo "         A record is written once. Write a NEW file instead."
      echo "         Rewriting costs a whole new blob in history on every write,"
      echo "         forever, even though the file itself never grows."
      violations=$((violations + 1))
      ;;
    R*|C*)
      echo "REFUSED: rename/copy of a record ($status)"
      echo "         $path ${rest:-}"
      echo "         Records are addressed by their path; moving one breaks that."
      violations=$((violations + 1))
      ;;
    *)
      echo "REFUSED: unexpected change status '$status' for $path"
      violations=$((violations + 1))
      ;;
  esac
done <<< "$changes"

echo "check-append-only: $added added, $deleted rolled off, $violations violation(s)"
if [ "$violations" -gt 0 ]; then
  echo
  echo "See tools/check-append-only.sh for why this is enforced rather than advised."
  exit 1
fi
exit 0
