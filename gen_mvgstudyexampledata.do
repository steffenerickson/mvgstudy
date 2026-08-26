// gen_mvgstudyexampledata.do
// Generates mvgstudyexampledata.dta — the example dataset used in the
// mvgstudy and mvdstudy help files and technical reference document.
//
// Design: fully-crossed p×i×h (persons × items × raters)
//   n_p = 50 persons, n_i = 6 items, n_h = 4 raters
//   1,200 total observations (one per person-item-rater cell)
//   Two outcome variables: x1, x2
//
// Data-generating model:
//   x_{pih} = p_p + i_i + h_h + (pi)_{pi} + (ph)_{ph} + (ih)_{ih} + (pih)_{pih}
//
// True covariance component matrices (population values):
//   Σ_p   = [1.00  0.40 \ 0.40  0.80]   (universe score covariance)
//   Σ_i   = [0.50  0.20 \ 0.20  0.60]
//   Σ_h   = [0.30  0.10 \ 0.10  0.40]
//   Σ_pi  = [0.40  0.15 \ 0.15  0.50]
//   Σ_ph  = [0.20  0.08 \ 0.08  0.30]
//   Σ_ih  = [0.15  0.05 \ 0.05  0.20]
//   Σ_pih = [0.60  0.20 \ 0.20  0.70]   (residual)
//
// Seed: 90210 (matches the running example in the technical reference document)

local seed 90210
local n_p  50
local n_i   6
local n_h   4

set seed `seed'

// Person effects
preserve
    clear
    set obs `n_p'
    gen p = _n
    matrix Sigma_p = (1.0, 0.40 \ 0.40, 0.8)
    drawnorm pe1 pe2, cov(Sigma_p)
    tempfile peff
    save `peff'
restore

// Item effects
preserve
    clear
    set obs `n_i'
    gen i = _n
    matrix Sigma_i = (0.5, 0.20 \ 0.20, 0.6)
    drawnorm ie1 ie2, cov(Sigma_i)
    tempfile ieff
    save `ieff'
restore

// Rater effects
preserve
    clear
    set obs `n_h'
    gen h = _n
    matrix Sigma_h = (0.3, 0.10 \ 0.10, 0.4)
    drawnorm he1 he2, cov(Sigma_h)
    tempfile heff
    save `heff'
restore

// Person-by-item interaction effects
preserve
    clear
    set obs `=`n_p'*`n_i''
    gen p = ceil(_n / `n_i')
    gen i = mod(_n - 1, `n_i') + 1
    matrix Sigma_pi = (0.4, 0.15 \ 0.15, 0.5)
    drawnorm pie1 pie2, cov(Sigma_pi)
    tempfile pieff
    save `pieff'
restore

// Person-by-rater interaction effects
preserve
    clear
    set obs `=`n_p'*`n_h''
    gen p = ceil(_n / `n_h')
    gen h = mod(_n - 1, `n_h') + 1
    matrix Sigma_ph = (0.2, 0.08 \ 0.08, 0.3)
    drawnorm phe1 phe2, cov(Sigma_ph)
    tempfile pheff
    save `pheff'
restore

// Item-by-rater interaction effects
preserve
    clear
    set obs `=`n_i'*`n_h''
    gen i = ceil(_n / `n_h')
    gen h = mod(_n - 1, `n_h') + 1
    matrix Sigma_ih = (0.15, 0.05 \ 0.05, 0.2)
    drawnorm ihe1 ihe2, cov(Sigma_ih)
    tempfile iheff
    save `iheff'
restore

// Full factorial grid
clear
set obs `=`n_p'*`n_i'*`n_h''
gen p = ceil(_n / (`n_i'*`n_h'))
gen i = mod(ceil(_n / `n_h') - 1, `n_i') + 1
gen h = mod(_n - 1, `n_h') + 1

merge m:1 p   using `peff',  nogenerate
merge m:1 i   using `ieff',  nogenerate
merge m:1 h   using `heff',  nogenerate
merge m:1 p i using `pieff', nogenerate
merge m:1 p h using `pheff', nogenerate
merge m:1 i h using `iheff', nogenerate

// Residual (person-by-item-by-rater) effects
matrix Sigma_pih = (0.6, 0.20 \ 0.20, 0.7)
drawnorm pihe1 pihe2, cov(Sigma_pih)

gen x1 = pe1 + ie1 + he1 + pie1 + phe1 + ihe1 + pihe1
gen x2 = pe2 + ie2 + he2 + pie2 + phe2 + ihe2 + pihe2
keep p i h x1 x2
sort p i h

save "mvgstudyexampledata.dta", replace
di "Saved mvgstudyexampledata.dta: `=_N' obs, variables p i h x1 x2"
