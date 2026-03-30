# TEST-NEEDS: Cliometrics.jl

## Current State

| Category | Count | Details |
|----------|-------|---------|
| **Source modules** | 11 | 1,636 lines |
| **Test files** | 1 | 477 lines, 142 @test/@testset |
| **Benchmarks** | 0 | None |

## What's Missing

- [ ] **E2E**: No end-to-end historical data analysis pipeline test
- [ ] **Performance**: No benchmarks for time series analysis on historical datasets
- [ ] **Error handling**: No tests for incomplete/corrupt historical data

## FLAGGED ISSUES
- **142 tests for 11 modules = 12.9 tests/module** -- adequate
- **0 benchmarks** for data-heavy computation

## Priority: P2 (MEDIUM)

## FAKE-FUZZ ALERT

- `tests/fuzz/placeholder.txt` is a scorecard placeholder inherited from rsr-template-repo — it does NOT provide real fuzz testing
- Replace with an actual fuzz harness (see rsr-template-repo/tests/fuzz/README.adoc) or remove the file
- Priority: P2 — creates false impression of fuzz coverage
