//----------------------------------------------------------------------------//
*! mvcrr  version 1.4.0  24aug2026
*! v1.4.0: one command per file; Mata moved to lmvgstudy.mlib; moremata no
*!  longer required.  Requires Stata 19.  History: CHANGELOG.md.
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
// Phase 12: mvcrr — Projected Construct-Relevant Reliability
//
// CRR = lambda x Erho2_DCF:PL, the share of observed person-score variance that
// is both reproducible across lessons and driven by true prevalence, under
// person- AND lesson-level differential classifier functioning (DCF).
// Reference: Erickson dissertation ch. 2 (chapter_02_redraft_v5.md), eqs. at
// lines 241 (lambda), 267 (Erho2_DCF:PL), 387 (CRR), 393 (sigma2_eps).
//
// Requires a prior mvgstudy run with exactly three outcome variables
// (A-hat, J-hat, prevalence-hat) and the two-effect design
// (object lesson|object), e.g.  mvgstudy (Ahat Jhat pihat = p l|p).
// Reads the persistent mata object c; does not modify it.
//----------------------------------------------------------------------------//
program mvcrr, rclass
	version 19
	syntax, Object(string) ///
	        [NL(integer 0) Avar(string) Jvar(string) Pvar(string) ///
	         nu0(string) nu1(string) NUTT(string) SIGMAE(string) ///
	         N0var(string) N1var(string) RHO_lp(string) ///
	         PWmeans Bootstrap CI_level(real 95)]

	tempname _nv C_crr C_ab C_lam C_er C_jb C_mp C_se C_tr C_ub CMP

	//---//
	// Validate that mvgstudy results exist and match the required design
	//---//
	capture mata: st_numscalar("`_nv'", length(c.varlist))
	if _rc {
		di as error "mvcrr: no mvgstudy results in memory; run mvgstudy first"
		exit 301
	}
	if scalar(`_nv') != 3 {
		di as error "mvcrr: requires an mvgstudy run with exactly 3 outcome variables (A J prevalence); found `=scalar(`_nv')'"
		exit 198
	}
	mata: st_local("_crr_neff", strofreal(length(c.effects)))
	if `_crr_neff' != 2 & `_crr_neff' != 1 {
		di as error "mvcrr: requires the design (object lesson|object), or (object) alone for single-replication mode; found `_crr_neff' effects"
		exit 198
	}
	// Phase 12d: one-effect design => single-replication (SR) mode
	local srmode = (`_crr_neff' == 1)
	mata: st_local("_crr_eff1", c.effects[1])
	if "`_crr_eff1'" != "`object'" {
		di as error "mvcrr: object(`object') does not match the design's object effect '`_crr_eff1''"
		exit 198
	}
	if !`srmode' {
		mata: st_local("_crr_eff2", c.effects[2])
		if !regexm("`_crr_eff2'", "^[^|#]+\|`object'$") {
			di as error "mvcrr: second effect '`_crr_eff2'' is not of the form lesson|`object'"
			exit 198
		}
	}
	if `nl' < 1 {
		di as error "mvcrr: nl() is required and must be a positive integer"
		exit 198
	}

	//---//
	// Resolve variable roles (default order: A, J, prevalence)
	//---//
	mata: st_local("_crr_vl", invtokens(c.varlist))
	if ("`avar'" == "") local avar : word 1 of `_crr_vl'
	if ("`jvar'" == "") local jvar : word 2 of `_crr_vl'
	if ("`pvar'" == "") local pvar : word 3 of `_crr_vl'
	foreach rv in avar jvar pvar {
		if !`:list `rv' in _crr_vl' {
			di as error "mvcrr: variable '``rv''' is not among the mvgstudy outcome variables (`_crr_vl')"
			exit 198
		}
	}
	if ("`avar'" == "`jvar'" | "`avar'" == "`pvar'" | "`jvar'" == "`pvar'") {
		di as error "mvcrr: avar(), jvar(), and pvar() must name three distinct variables"
		exit 198
	}

	//---//
	// Resolve sigma2_eps (realization variance)
	// Default sigmae = 0: when the L:P components are estimated from per-lesson
	// data they already absorb utterance-sampling noise, so adding a separate
	// sigma2_eps would count that noise twice (see build_mvcrr_plan.md, sec. 5).
	//---//
	local sig_mode 0
	local s1 0
	local s2 0
	local s3 0
	if ("`sigmae'" != "" & ("`nu0'" != "" | "`nu1'" != "" | "`nutt'" != "")) {
		di as error "mvcrr: sigmae() may not be combined with nu0()/nu1()/nutt()"
		exit 198
	}
	if ("`nu0'" != "" | "`nu1'" != "" | "`nutt'" != "") {
		if ("`nu0'" == "" | "`nu1'" == "" | "`nutt'" == "") {
			di as error "mvcrr: nu0(), nu1(), and nutt() must be specified together"
			exit 198
		}
		foreach o in nu0 nu1 nutt {
			capture confirm number ``o''
			if _rc {
				di as error "mvcrr: `o'() must be a number"
				exit 198
			}
		}
		if `nu0' < 0 | `nu1' < 0 {
			di as error "mvcrr: nu0() and nu1() must be nonnegative"
			exit 198
		}
		if `nutt' <= 0 {
			di as error "mvcrr: nutt() must be positive"
			exit 198
		}
		local sig_mode 2
		local s1 `nu0'
		local s2 `nu1'
		local s3 `nutt'
	}
	else if ("`sigmae'" != "") {
		capture confirm number `sigmae'
		if _rc {
			di as error "mvcrr: sigmae() must be a nonnegative number"
			exit 198
		}
		if `sigmae' < 0 {
			di as error "mvcrr: sigmae() must be a nonnegative number"
			exit 198
		}
		local sig_mode 1
		local s1 `sigmae'
	}

	//---//
	// Phase 12d: single-replication mode option validation.
	// SR mode reproduces the paper's person-only CRR (lambda x Erho2_DCF:P):
	// person components disattenuated for sampling error; lesson side entered
	// as D-study parameters (rho_lp, closed-form sigma2_eps).
	//---//
	if `srmode' {
		if ("`bootstrap'" != "") {
			di as error "mvcrr: bootstrap is not supported in single-replication mode"
			exit 198
		}
		if ("`sigmae'" != "") {
			di as error "mvcrr: single-replication mode requires nu0()/nu1()/nutt(); sigmae() is not allowed"
			exit 198
		}
		if `sig_mode' != 2 {
			di as error "mvcrr: single-replication mode requires nu0(), nu1(), and nutt()"
			exit 198
		}
		if ("`n0var'" == "" | "`n1var'" == "") {
			di as error "mvcrr: single-replication mode requires n0var() and n1var() (per-object gold-negative/-positive counts)"
			exit 198
		}
		confirm numeric variable `n0var'
		confirm numeric variable `n1var'
		if ("`rho_lp'" == "") local rho_lp 1
		capture confirm number `rho_lp'
		if _rc {
			di as error "mvcrr: rho_lp() must be a nonnegative number"
			exit 198
		}
		if `rho_lp' < 0 {
			di as error "mvcrr: rho_lp() must be a nonnegative number"
			exit 198
		}
		if ("`pwmeans'" != "") {
			di as text "(note: pwmeans ignored in single-replication mode — one row per object)"
		}
	}
	else if ("`n0var'`n1var'`rho_lp'" != "") {
		di as error "mvcrr: n0var()/n1var()/rho_lp() apply only to single-replication mode (one-effect design)"
		exit 198
	}

	//---//
	// Compute
	// pw = 1: means of within-object means (person-weighted); default is the
	// observation-weighted grand mean.  Identical under balanced designs.
	//---//
	local pw = cond("`pwmeans'" == "" | `srmode', 0, 1)
	if `srmode' {
		tempname SVM
		mata c.compute_crr_sr("`avar'", "`jvar'", "`pvar'", `nl', ///
		                      `nu0', `nu1', `nutt', `rho_lp', ///
		                      "`n0var'", "`n1var'", "`CMP'", "`SVM'", ///
		                      "`C_crr' `C_ab' `C_lam' `C_er' `C_jb' `C_mp' `C_se' `C_tr' `C_ub'")
	}
	else {
		mata c.compute_crr("`avar'", "`jvar'", "`pvar'", `nl', `sig_mode', ///
		                   `s1', `s2', `s3', `pw', "`CMP'", ///
		                   "`C_crr' `C_ab' `C_lam' `C_er' `C_jb' `C_mp' `C_se' `C_tr' `C_ub'")
	}

	//---//
	// Display: CRR reported together with A-bar (companion requirement)
	//---//
	local sig_src "0 (default; utterance-sampling noise absorbed in L:P components)"
	if `sig_mode' == 1 local sig_src "user-supplied via sigmae()"
	if `sig_mode' == 2 local sig_src "closed form from nu0(), nu1(), nutt()"
	local mean_src "observation-weighted grand means"
	if `pw' local mean_src "person-weighted means (pwmeans; mean of within-`object' means)"

	if `srmode' {
		local coeflab "Erho2_DCF:P"
		local modelab "single-replication mode: person-level DCF, disattenuated"
	}
	else {
		local coeflab "Erho2_DCF:PL"
		local modelab "person- and lesson-level DCF"
	}
	di as text _newline "Projected Construct-Relevant Reliability (`modelab')"
	di as text "{hline 72}"
	di as text "  CRR   (lambda x `coeflab')" _column(39) "= " as result %9.4f scalar(`C_crr')
	di as text "  A-bar (mean false-pos. intercept)   = " as result %9.4f scalar(`C_ab')
	di as text "{hline 72}"
	di as text "  lambda                              = " as result %9.4f scalar(`C_lam')
	di as text "  `coeflab'" _column(39) "= " as result %9.4f scalar(`C_er')
	di as text "  J-bar (mean class separation)       = " as result %9.4f scalar(`C_jb')
	di as text "  mu_pi (mean prevalence)             = " as result %9.4f scalar(`C_mp')
	di as text "  sigma2_eps (realization variance)   = " as result %9.6f scalar(`C_se')
	di as text "        source: `sig_src'"
	di as text "  n_L (planned lessons)               = " as result %9.0g `nl'
	if `srmode' {
		di as text "  rho_LP (sigma2_pi_LP / sigma2_pi)   = " as result %9.4f `rho_lp'
	}
	di as text "  A-bar/J-bar/mu_pi from: `mean_src'"
	di as text ""
	matlist `CMP', twidth(8) format(%12.6f) ///
		title("Variance components as used (post-truncation)")
	if `srmode' {
		di as text ""
		matlist `SVM', twidth(8) format(%12.6f) ///
			title("Mean per-object sampling variances subtracted (disattenuation)")
	}

	if scalar(`C_tr') > 0 {
		di as text "(note: `=scalar(`C_tr')' negative variance component(s) truncated at zero)"
	}
	if scalar(`C_ub') == 1 {
		di as text "(note: person-level DCF components truncated to zero; lambda = 1 by" ///
		           " construction and CRR is an upper bound, not an estimate)"
	}
	if !`srmode' & `sig_mode' > 0 & scalar(`C_se') > 0 {
		di as text "(note: sigmae > 0 assumes the lesson-level (L:P) components are" ///
		           " disattenuated for utterance-sampling error; otherwise this noise" ///
		           " is counted twice)"
	}

	//---//
	// Phase 12b: bootstrap BCa CIs for CRR (opt-in)
	// Propagates the G-study bootstrap reps (components AND per-rep means)
	// through the CRR formula; requires mvgstudy , bootstrap first.
	//---//
	if ("`bootstrap'" != "") {
		if (`ci_level' <= 0 | `ci_level' >= 100) {
			di as error "mvcrr: ci_level() must be between 1 and 99"
			exit 198
		}
		tempname _bB CRT
		capture mata: st_numscalar("`_bB'", c.boot_B)
		if _rc | missing(scalar(`_bB')) | scalar(`_bB') <= 0 {
			di as error "mvcrr: bootstrap requires mvgstudy to have been run with the bootstrap option first"
			exit 198
		}
		local ci_alpha = (100 - `ci_level') / 100
		di as text _newline "Running CRR bootstrap (`ci_level'% BCa CIs, B=`=scalar(`_bB')')..."
		mata c.run_crr_bootstrap("`avar'", "`jvar'", "`pvar'", `nl', `sig_mode', ///
		                         `s1', `s2', `s3', `pw', `ci_alpha', "`CRT'")
		di as text "CRR bootstrap complete."
		di as text ""
		matlist `CRT', format(%9.4f) ///
			title("Bootstrap Summary: CRR (`ci_level'% BCa CI)")
		return matrix crr_table = `CRT'
	}

	//---//
	// Returned results
	//---//
	return scalar crr         = scalar(`C_crr')
	return scalar Abar        = scalar(`C_ab')
	return scalar lambda      = scalar(`C_lam')
	if `srmode' {
		return scalar erho2_dcfp = scalar(`C_er')
		return scalar rho_lp     = `rho_lp'
		return matrix sampvar    = `SVM'
	}
	else {
		return scalar erho2_dcfpl = scalar(`C_er')
	}
	return scalar Jbar        = scalar(`C_jb')
	return scalar mupi        = scalar(`C_mp')
	return scalar sigmae      = scalar(`C_se')
	return scalar nl          = `nl'
	return scalar pwmeans     = `pw'
	return scalar trunc       = scalar(`C_tr')
	return matrix components  = `CMP'

end
