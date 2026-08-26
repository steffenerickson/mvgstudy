// gen_mvcrrexampledata_plr.do
// Generates mvcrrexampledata_plr.dta — the crossed-design example dataset
// for mvcrr (persons x lessons x raters).
//
// Design: fully crossed p x l x r
//   n_p = 200 persons, n_l = 6 lessons, n_r = 3 raters (3,600 rows)
//   Three outcome variables per person-lesson-rater cell: Ahat, Jhat, pihat
//   (intercept, class separation, prevalence — as estimated per cell from
//    gold-labeled utterances upstream of mvgstudy/mvcrr)
//
// Data-generating model (every effect independent normal; no covariance
// among A, J, pi within any effect, so delta_beta ~ 0 by construction):
//   Ahat  = .15 + a_p + a_l + a_r + a_pl + a_pr + a_lr + a_plr
//   Jhat  = .55 + j_p + ...                 (same effect structure)
//   pihat = .10 + t_p + ...
//
//   effect    var(a)    var(j)    var(pi)
//   p         .0020     .0040     .0030
//   l         .0003     .0005     .0004
//   r         .0002     .0004     .0001
//   p#l       .0010     .0020     .0020
//   p#r       .0004     .0008     .0005
//   l#r       .0001     .0002     .0001
//   p#l#r     .0006     .0010     .0010
//
// True zero-covariance CRR at nfacet(l 4 r 2), sigma2_eps = 0 (relative
// error: effects containing p; second-order terms by the union rule):
//   V(p)     = .0020 + .0040*(.10^2 + .0030) + .55^2*.0030          = .0029595
//   V(p#l)   = .0010 + .0020*(.01 + .0030 + .0020) + .55^2*.0020
//              + .0040*.0020                                          = .0016430
//   V(p#r)   = .0004 + .0008*(.01 + .0030 + .0005) + .55^2*.0005
//              + .0040*.0005                                          = .0005673
//   V(p#l#r) = .0006 + .0010*(.01+.0030+.0020+.0005+.0010)
//              + .55^2*.0010 + (.0040+.0020+.0008)*.0010
//              + .0020*.0005 + .0008*.0020                             = .0009258
//   err      = V(p#l)/4 + V(p#r)/2 + V(p#l#r)/8                        = .0008101
//   CRR      = .55^2*.0030 / (.0029595 + .0008101)                    ~= .2408
//
// Seed: 90210 (matches the mvgstudy example-data convention)

local seed 90210
local n_p  200
local n_l  6
local n_r  3

set seed `seed'

clear
set obs `n_p'
gen p   = _n
gen a_p = rnormal(0, sqrt(.0020))
gen j_p = rnormal(0, sqrt(.0040))
gen t_p = rnormal(0, sqrt(.0030))

expand `n_l'
bysort p: gen l = _n
gen a_pl = rnormal(0, sqrt(.0010))
gen j_pl = rnormal(0, sqrt(.0020))
gen t_pl = rnormal(0, sqrt(.0020))

expand `n_r'
bysort p l: gen r = _n
gen a_plr = rnormal(0, sqrt(.0006))
gen j_plr = rnormal(0, sqrt(.0010))
gen t_plr = rnormal(0, sqrt(.0010))

// Main effects and two-way interactions not involving p, plus p#r:
// draw once per level combination and merge back
tempfile base
save `base'

foreach f in l r {
	preserve
	keep `f'
	duplicates drop
	gen a_`f' = rnormal(0, sqrt(cond("`f'" == "l", .0003, .0002)))
	gen j_`f' = rnormal(0, sqrt(cond("`f'" == "l", .0005, .0004)))
	gen t_`f' = rnormal(0, sqrt(cond("`f'" == "l", .0004, .0001)))
	tempfile eff_`f'
	save `eff_`f''
	restore
	merge m:1 `f' using `eff_`f'', nogenerate
}
preserve
keep p r
duplicates drop
gen a_pr = rnormal(0, sqrt(.0004))
gen j_pr = rnormal(0, sqrt(.0008))
gen t_pr = rnormal(0, sqrt(.0005))
tempfile eff_pr
save `eff_pr'
restore
merge m:1 p r using `eff_pr', nogenerate
preserve
keep l r
duplicates drop
gen a_lr = rnormal(0, sqrt(.0001))
gen j_lr = rnormal(0, sqrt(.0002))
gen t_lr = rnormal(0, sqrt(.0001))
tempfile eff_lr
save `eff_lr'
restore
merge m:1 l r using `eff_lr', nogenerate

gen Ahat  = .15 + a_p + a_l + a_r + a_pl + a_pr + a_lr + a_plr
gen Jhat  = .55 + j_p + j_l + j_r + j_pl + j_pr + j_lr + j_plr
gen pihat = .10 + t_p + t_l + t_r + t_pl + t_pr + t_lr + t_plr

keep p l r Ahat Jhat pihat
sort p l r
label data "mvcrr example: persons x lessons x raters (Ahat Jhat pihat); seed 90210"

save "mvcrrexampledata_plr.dta", replace
di "Saved mvcrrexampledata_plr.dta: `=_N' obs, variables p l r Ahat Jhat pihat"
