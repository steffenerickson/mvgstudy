# Changelog

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
