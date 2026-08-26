// gen_mvcrrexampledata.do
// Generates mvcrrexampledata.dta — the example dataset for mvcrr.
//
// Design: one-facet nested p, l|p (lessons within persons)
//   n_p = 1000 persons, n_l = 20 lessons each (large, for closed-form recovery)
//   Three outcome variables per person-lesson: Ahat, Jhat, pihat
//   (intercept, class separation, prevalence — as estimated per lesson from
//    gold-labeled utterances upstream of mvgstudy/mvcrr)
//
// Data-generating model (all effects independent normal):
//   Ahat_pl  = Abar + a_p  + a_pl,   Abar = .15, var(a_p)  = .002, var(a_pl)  = .001
//   Jhat_pl  = Jbar + j_p  + j_pl,   Jbar = .55, var(j_p)  = .004, var(j_pl)  = .002
//   pihat_pl = mupi + pi_p + eta_pl, mupi = .10, var(pi_p) = .003, var(eta_pl)= .003
//
// True CRR at n_L = 4, sigma2_eps = 0 (see build_mvcrr_plan.md):
//   num_pi  = .55^2*.003                                   = .0009075
//   num_tau = num_pi + .002 + .004*(.10^2+.003)            = .0029595
//   err_L   = .001 + (.55^2+.004)*.003
//             + .002*(.10^2+.003+.003)                     = .0019515
//   CRR     = num_pi/(num_tau + err_L/4)                  ~= .2633
//
// Seed: 90210 (matches the mvgstudy example-data convention)

local seed 90210
local n_p  1000
local n_l  20

set seed `seed'

clear
set obs `n_p'
gen p    = _n
gen a_p  = rnormal(0, sqrt(.002))
gen j_p  = rnormal(0, sqrt(.004))
gen pi_p = rnormal(0, sqrt(.003))

expand `n_l'
bysort p: gen l = _n

gen Ahat  = .15 + a_p  + rnormal(0, sqrt(.001))
gen Jhat  = .55 + j_p  + rnormal(0, sqrt(.002))
gen pihat = .10 + pi_p + rnormal(0, sqrt(.003))

keep p l Ahat Jhat pihat
sort p l

save "mvcrrexampledata.dta", replace
di "Saved mvcrrexampledata.dta: `=_N' obs, variables p l Ahat Jhat pihat"
