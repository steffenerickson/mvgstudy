# Changelog

## 1.4.0 — 2026-08-24

### Fixed
- **mvdstudy / mvcrr unrecognized after `net install`** (`bugs/2026-08-24_single_file_autoload.md`).
  All three commands lived in `mvgstudy.ado`, so Stata could only autoload
  `mvgstudy`: in a fresh session `mvdstudy` and `mvcrr` were "unrecognized"
  until `mvgstudy` had been called, and after a long bootstrap Stata's
  autoload cache could drop them again mid-script with the same error.
- **mvdstudy** called with no G-study in memory now exits 301 with
  "no mvgstudy results in memory; run mvgstudy first" (as `mvcrr` already did)
  instead of failing inside Mata.

### Changed
- One command per file: `mvgstudy.ado`, `mvdstudy.ado`, `mvcrr.ado`, plus the
  private helper `_mvg_parse_equation.ado`.
- The Mata engine is compiled into `lmvgstudy.mlib`; the source is kept as
  `mvgstudy.mata` and rebuilt with `build_mlib.do`. Rebuild the `.mlib`
  whenever the `.mata` changes.
- The undeclared dependency on moremata (`mm_cond()` in one helper) is removed.
- **Requires Stata 19.** The package has always been written for Stata 19
  (`version 19` in every program); the `.pkg` previously misstated 16.

### Note
- Existing users must reinstall: `net install mvgstudy, from(...) replace`.
- Numerical results are unchanged from 1.3.4; every regression log diffs clean
  apart from timestamps and the version banner.

## 1.3.4 — 2026-08-24

### Fixed
- **mvdstudy, bootstrap**: negative variance components inside bootstrap and
  jackknife replicates are now truncated at zero before the D-study ratios are
  formed, so replicate reliability coefficients (Eρ², Φ) stay within [0, 1].
  Previously a replicate with a negative object or error component could make
  the ratio explode (SEs in the hundreds, BCa limits far outside [0, 1]).
  Point estimates are never truncated; a note reports the number of truncated
  components when any occur.

### Added
- **mvgstudy, bootstrap**: warns when the BCa jackknife has fewer than 10
  leave-out units. This typically means the nesting direction in the termlist
  is reversed (`a|b` means *a* nested within *b*; lessons within persons is
  `l|p`, not `p|l`), which makes the cluster bootstrap resample the wrong unit.
- Help files document both behaviours (`help mvgstudy` › Bootstrap › Jackknife
  size warning; `help mvdstudy` › Bootstrap D-study Details › Truncation).

## 1.3.3 — 2026-08-15
- Initial public release: mvgstudy, mvdstudy, mvcrr.
