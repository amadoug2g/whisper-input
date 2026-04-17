# Reviewer Feedback — 2026-04-17

## Verdict: LGTM

### Summary
`scripts/package-dmg.sh` and the `make dmg` Makefile target correctly implement all 5 criteria
from DAILY_GOAL.md. The script is well-structured (`set -euo pipefail`, quoted variables,
temp-file cleanup, mount-point validation). Sprint J1 objective is fully delivered.

### Non-blocking suggestions

1. **Double `make app` invocation** — `package-dmg.sh` calls `make -C "$REPO" app` on line 17,
   but the Makefile already declares `dmg: app` as a prerequisite. When `make dmg` is run from
   scratch, the app is built twice. Removing the `make -C "$REPO" app` call from the script
   (and relying solely on the Makefile dependency) would eliminate the redundancy.
   File: `scripts/package-dmg.sh` line 17.

2. **Missing `.gitignore` entry for `*.dmg`** — `Memo-v*.dmg` artifacts produced by `make dmg`
   are not gitignored. Adding `Memo-v*.dmg` (or `*.dmg`) to `.gitignore` would prevent accidental
   commits of large binary artifacts.
   File: `.gitignore`.

### Tests
Swift not available on Linux CI — `make test` exits 127. No Swift sources were modified;
46 tests are unchanged per sprint history and `package-dmg.sh` has no Swift dependency.
Test status: unchanged (46 expected to pass on macOS CI).
