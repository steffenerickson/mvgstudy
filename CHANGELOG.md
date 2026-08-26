# Changelog

## 1.5.0 — 2026-08-26

### Changed
- **mvcrr generalized to any G-study design** (`spec_generalized_mvcrr.md`
  rev. 3.1). `nl()` is replaced by `nfacet(facet # ...)` | `current`, and
  `fix(facet # ...)` passes through the mixed-design augmentation used by
  `mvdstudy`. The object effect and every effect containing the object facet
  enter (relative-error convention); each effect's error is divided by the
  product of its random facets' D-study sizes, and sigma2_eps by the product
  of all random non-object facets' sizes. `nl(#)` is kept as a deprecated
  synonym when exactly one random facet remains. After
  `mvgstudy (A J pi = p l|p)`, `mvcrr, object(p) nfacet(l #)` reproduces
  1.4.0 to machine precision.
- **Covariance-inclusive reporting panel, always displayed:** CRR_zc (the
  1.4.0 zero-covariance coefficient; ranking statistic), delta_beta =
  beta - Jbar (alignment check), CRR_orth (orthogonal decomposition,
  lambda = corr(tau, pi)^2) and CRR_bc (Wishart-moment bias-corrected) as a
  sensitivity bracket, plus Jbar and Abar. Second-order terms follow the
  ordered-pair union-effect rule of the derivation (Part II.2); estimated
  matrices are PSD-repaired on the orthogonal path. All members propagate
  through `bootstrap` (`r(crr_table)` now 10 x 4).
- Single-replication mode also reports the panel: the disattenuation now
  subtracts the full sampling covariance matrix (Cov(A,J) = -nu0^2/n0).
- A small-sample warning is printed whenever the number of objects is below 50.

### Added
- `r(crr_zc)`, `r(dbeta)`, `r(beta)`, `r(crr_orth)`, `r(crr_bc)`,
  `r(lambda_zc)`, `r(lambda_orth)`, `r(lambda_bc)`, `r(erho2)`,
  `r(erho2_orth)`, `r(varC)`, `r(psdfix)`, `r(ub)`, `r(n_obj)`, `r(d_eps)`,
  `r(var_obj_zc)`, `r(var_obj_orth)`, `r(err_zc)`, `r(err_orth)`, macros
  `r(object) r(nfacet) r(fix) r(avar) r(jvar) r(pvar)`, matrices
  `r(covcomps)` (effects x 6, orthogonal path) and `r(errors)`
  (error effects x 3: divisor, err_zc, err_orth). `r(components)` now has one
  row per effect used.
- `mvgstudy` class: `apply_fixed_facets()` records the augmentation weights
  (`aug_w`) so post-estimation commands can re-apply `fix()` per bootstrap
  replicate.

### Added (example data)
- `mvcrrexampledata_plr.dta`: a crossed persons x lessons x raters example
  (200 x 6 x 3, `Ahat Jhat pihat`) for the generalized `mvcrr` examples;
  generator `mvcrr_dev/gen_mvcrrexampledata_plr.do` documents the population
  parameters and the closed-form CRR (~.24 at `nfacet(l 4 r 2)`).

### Fixed
- `help mvgstudy` no longer lists "facet name prefix collision" as a known
  limitation: effect membership has been token-based since the 1.4.0 rewrite
  (`_facet_in_effect`), and a design with facets `p` and `pr` now estimates
  identically to the same design with non-overlapping names (verified for
  balanced and unbalanced data, bootstrap, `mvdstudy fix()`).

### Note
- `r(crr)`, `r(lambda)`, `r(erho2_dcfpl)` / `r(erho2_dcfp)` keep their 1.4.0
  (zero-covariance) meaning. Existing users must reinstall:
  `net install mvgstudy, from(...) replace`.

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
