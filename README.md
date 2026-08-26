# mvgstudy

Stata commands for multivariate generalizability and decision studies: variance/covariance component estimation with bootstrap BCa inference, D-study projections, and reliability criteria for LLM-classifier measurement designs.

The package ships as a suite of three commands:

| Command | Purpose |
|---|---|
| `mvgstudy` | G-study: variance and covariance component estimation, with optional bootstrap |
| `mvdstudy` | D-study: projects reliability coefficients (Eρ², Φ) and error/true-score variances over proposed facet sample sizes, with bootstrap CIs propagated from the G-study |
| `mvcrr` | Projected construct-relevant reliability (CRR) for LLM-classifier measurement designs on any G-study design, with the covariance-inclusive reporting panel (CRR_zc, δ_β, [CRR_bc, CRR_orth], J̄, Ā) and optional bootstrap BCa CIs |

`mvgstudy` estimates variance and covariance components for multifaceted generalizability (G-study) designs, following Brennan (2001). It supports any combination of crossed and nested facets, univariate and multivariate outcomes, balanced and unbalanced designs, and data with missing outcome values. For balanced designs it uses the SSCP-based method-of-moments estimator derived from a MANOVA decomposition; for unbalanced designs it automatically switches to the exact CP-terms estimator (Brennan, 2001, Sec. 11.1.3).

## Installation

```stata
net install mvgstudy, from("https://raw.githubusercontent.com/steffenerickson/mvgstudy/main/") replace
net get mvgstudy, from("https://raw.githubusercontent.com/steffenerickson/mvgstudy/main/")   // example datasets
```

Requirements: **Stata 19 or later.** No dependencies outside official Stata.

Existing users upgrading from 1.3.x or 1.4.0: reinstall with `replace` (as above). Version 1.4.0 changed the file layout and 1.5.0 rebuilds the Mata library, so a plain re-run of the old install will not pick up the new files.

### Files

`net install` places the following in your PLUS directory:

| File | Contents |
|---|---|
| `mvgstudy.ado`, `mvdstudy.ado`, `mvcrr.ado` | one Stata command per file |
| `_mvg_parse_equation.ado` | private helper used by `mvgstudy` |
| `lmvgstudy.mlib` | compiled Mata library (class `mvgstudy` and its helpers) |
| `mvgstudy.sthlp`, `mvdstudy.sthlp`, `mvcrr.sthlp` | help files |

The Mata source (`mvgstudy.mata`) and the build script (`build_mlib.do`) are in the repository for transparency but are not installed.

## Quick start

A fully-crossed persons × items × raters design with two outcomes:

```stata
use mvgstudyexampledata.dta, clear
mvgstudy (x1 x2 = p i h p#i p#h i#h p#i#h)
```

With bootstrap inference and a D-study projection:

```stata
mvgstudy (x1 x2 = p i h p#i p#h i#h p#i#h), bootstrap reps(1000) seed(42)
mvdstudy, object(p) errortype(relative) current bootstrap ci_level(95)
```

Full syntax, options, and validated-design tables are in the help files: `help mvgstudy`, `help mvdstudy`, `help mvcrr`.

## Documentation

See the [package page](https://steffenerickson.github.io/software/mvgstudy/) for a full overview.

## Citation

```bibtex
@software{erickson2026mvgstudy,
  author  = {Erickson, Steffen},
  title   = {mvgstudy: Stata commands for multivariate generalizability and decision studies},
  version = {1.5.0},
  year    = {2026},
  url     = {https://github.com/steffenerickson/mvgstudy}
}
```

## References

- Brennan, R. L. (2001). *Generalizability theory*. Springer.
- Efron, B., & Tibshirani, R. J. (1993). *An introduction to the bootstrap*. Chapman & Hall.
- Li, G., Michaelides, M. P., & Haertel, E. (2023). Bootstrap confidence intervals for generalizability theory variance components. *PLOS ONE*, 18(7), e0288069.
