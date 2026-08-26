//----------------------------------------------------------------------------//
*! mvcrr  version 1.5.0  26aug2026
*! v1.5.0: generalized to any mvgstudy design (nfacet/current/fix); covariance-
*!  inclusive reporting panel (CRR_zc, delta_beta, CRR_orth, CRR_bc, Jbar, Abar).
*!  Requires Stata 19.  History: CHANGELOG.md.
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
// mvcrr — Projected Construct-Relevant Reliability
//
// CRR = lambda x Erho2_DCF:O, the share of observed object-score variance
// that is both reproducible over the generalization facets and driven by
// true prevalence, under differential classifier functioning (DCF) at every
// effect of the design.  Reference: Erickson dissertation ch. 2;
// spec_generalized_mvcrr.md (rev. 3.1) and the derivation
// generalized_crr_covariance_derivation.md (Parts I-II).
//
// Requires a prior mvgstudy run with exactly three outcome variables
// (A-hat, J-hat, prevalence-hat) on any crossed/nested design whose object
// of measurement is a main effect, e.g.  mvgstudy (Ahat Jhat pihat = p l|p)
// or  mvgstudy (Ahat Jhat pihat = p l r p#l p#r l#r p#l#r).
// A one-effect design (Ahat Jhat pihat = p) triggers single-replication mode.
// Reads the persistent mata object c; fix() mutates it transiently and the
// original design is restored before exit (also on error).
//----------------------------------------------------------------------------//
program mvcrr, rclass
	version 19
	syntax, Object(string) ///
	        [NFacet(string) CURrent NL(integer 0) FIX(string) ///
	         Avar(string) Jvar(string) Pvar(string) ///
	         nu0(string) nu1(string) NUTT(string) SIGMAE(string) ///
	         N0var(string) N1var(string) RHO_lp(string) ///
	         PWmeans Bootstrap CI_level(real 95)]

	tempname _nv CMP COV ERR SVM CRT _fixed_ns _nf_ns
	// 25 result slots, in the order of the Mata core's return layout
	tempname C_crr C_ab C_lam C_er C_se C_tr C_ub C_db C_cro C_lo C_crb C_lb ///
	         C_ero C_psd C_beta C_jb C_mp C_vz C_vo C_ez C_eo C_vc C_nz C_no C_nb
	local scn "`C_crr' `C_ab' `C_lam' `C_er' `C_se' `C_tr' `C_ub' `C_db' `C_cro' `C_lo' `C_crb' `C_lb' `C_ero' `C_psd' `C_beta' `C_jb' `C_mp' `C_vz' `C_vo' `C_ez' `C_eo' `C_vc' `C_nz' `C_no' `C_nb'"

	//---//
	// Validate that mvgstudy results exist and have three outcome variables
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
	mata: st_local("_crr_facets", invtokens(c.facets))
	mata: st_local("_crr_effects", invtokens(c.effects))
	if !`:list object in _crr_facets' {
		di as error "mvcrr: object(`object') is not a facet of the design (facets: `_crr_facets')"
		exit 198
	}
	if !`:list object in _crr_effects' {
		di as error "mvcrr: object(`object') must be a main effect of the design (effects: `_crr_effects')"
		exit 198
	}
	// One-effect design => single-replication (SR) mode
	local srmode = (`_crr_neff' == 1)

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
	// Parse fix(): alternating facet names and positive integers
	//---//
	local n_fixed 0
	local fixed_names ""
	if "`fix'" != "" {
		if `srmode' {
			di as error "mvcrr: fix() is not available in single-replication mode (one-effect design)"
			exit 198
		}
		local n_fix_toks : word count `fix'
		if mod(`n_fix_toks', 2) != 0 {
			di as error "mvcrr: fix() requires alternating facet names and integers, e.g., fix(l 4)"
			exit 198
		}
		local n_fixed = `n_fix_toks' / 2
		matrix `_fixed_ns' = J(1, `n_fixed', .)
		forvalues fk = 1/`n_fixed' {
			local _fn : word `=2*`fk'-1' of `fix'
			local _fv : word `=2*`fk'' of `fix'
			if !`:list _fn in _crr_facets' {
				di as error "mvcrr: fix() facet '`_fn'' is not a facet of the design (facets: `_crr_facets')"
				exit 198
			}
			if "`_fn'" == "`object'" {
				di as error "mvcrr: fix() facet '`_fn'' is the object of measurement; cannot fix the object"
				exit 198
			}
			capture confirm integer number `_fv'
			if _rc | `_fv' <= 0 {
				di as error "mvcrr: fix() values must be positive integers (got '`_fv'' for facet '`_fn'')"
				exit 198
			}
			local fixed_names "`fixed_names' `_fn'"
			matrix `_fixed_ns'[1, `fk'] = `_fv'
		}
		local fixed_names = strtrim("`fixed_names'")
	}

	//---//
	// D-study sizes: nfacet() | current | nl() (deprecated synonym)
	// SR mode: nl() is the planned number of lessons (required).
	//---//
	local random_facets : list _crr_facets - object
	local random_facets : list random_facets - fixed_names
	local use_current 0
	local nf_names ""
	local nf_str ""
	if `srmode' {
		if ("`nfacet'`current'" != "") {
			di as error "mvcrr: single-replication mode takes nl(#); nfacet()/current are not available"
			exit 198
		}
		if `nl' < 1 {
			di as error "mvcrr: nl() is required in single-replication mode and must be a positive integer"
			exit 198
		}
		matrix `_nf_ns' = J(1, 1, `nl')
		local nf_str "lessons `nl'"
	}
	else {
		if ("`nfacet'" != "" & "`current'" != "") {
			di as error "mvcrr: nfacet() and current are mutually exclusive"
			exit 198
		}
		if (`nl' != 0 & ("`nfacet'" != "" | "`current'" != "")) {
			di as error "mvcrr: nl() is a deprecated synonym for nfacet(); do not combine it with nfacet() or current"
			exit 198
		}
		if `nl' != 0 {
			// Deprecated synonym: valid only when exactly one random facet remains
			local n_rand : word count `random_facets'
			if `n_rand' != 1 | `nl' < 1 {
				di as error "mvcrr: nl() applies only to a design with exactly one random non-object facet; use nfacet(facet # ...)"
				exit 198
			}
			local nfacet "`random_facets' `nl'"
			di as text "(note: nl(`nl') is deprecated; interpreted as nfacet(`nfacet'))"
		}
		if ("`nfacet'" == "" & "`current'" == "") {
			if "`random_facets'" == "" {
				local use_current 1
			}
			else {
				di as error "mvcrr: specify nfacet(facet # ...) with a D-study size for every random non-object facet (`random_facets'), or current"
				exit 198
			}
		}
		if "`current'" != "" local use_current 1
		if "`nfacet'" != "" {
			local n_nf_toks : word count `nfacet'
			if mod(`n_nf_toks', 2) != 0 {
				di as error "mvcrr: nfacet() requires alternating facet names and integers, e.g., nfacet(l 4 r 2)"
				exit 198
			}
			local n_nf = `n_nf_toks' / 2
			matrix `_nf_ns' = J(1, `n_nf', .)
			forvalues fk = 1/`n_nf' {
				local _fn : word `=2*`fk'-1' of `nfacet'
				local _fv : word `=2*`fk'' of `nfacet'
				if "`_fn'" == "`object'" {
					di as error "mvcrr: nfacet() facet '`_fn'' is the object of measurement"
					exit 198
				}
				if `:list _fn in fixed_names' {
					di as error "mvcrr: facet '`_fn'' is fixed via fix(); do not also give it in nfacet()"
					exit 198
				}
				if !`:list _fn in random_facets' {
					di as error "mvcrr: nfacet() facet '`_fn'' is not a random non-object facet of the design (`random_facets')"
					exit 198
				}
				if `:list _fn in nf_names' {
					di as error "mvcrr: facet '`_fn'' given more than once in nfacet()"
					exit 198
				}
				capture confirm integer number `_fv'
				if _rc | `_fv' <= 0 {
					di as error "mvcrr: nfacet() values must be positive integers (got '`_fv'' for facet '`_fn'')"
					exit 198
				}
				local nf_names "`nf_names' `_fn'"
				matrix `_nf_ns'[1, `fk'] = `_fv'
			}
			local nf_names = strtrim("`nf_names'")
			local missing_nf : list random_facets - nf_names
			if "`missing_nf'" != "" {
				di as error "mvcrr: nfacet() must give a D-study size for every random non-object facet; missing: `missing_nf'"
				exit 198
			}
			local nf_str = strtrim("`nfacet'")
		}
		if `use_current' {
			matrix `_nf_ns' = J(1, 1, .)
		}
	}

	//---//
	// Resolve sigma2_eps (realization variance)
	// Default sigmae = 0: when the generalization-facet components are
	// estimated from per-cell data they already absorb utterance-sampling
	// noise, so a separate sigma2_eps would count it twice (help: Remarks).
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
	// Single-replication mode option validation.
	// SR mode reproduces the paper's person-only CRR: object components
	// disattenuated for sampling (co)variance; lesson side entered as
	// D-study parameters (rho_lp, closed-form sigma2_eps).
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
	// Bootstrap prerequisites (checked before any state mutation)
	//---//
	local pw = cond("`pwmeans'" == "" | `srmode', 0, 1)
	if ("`bootstrap'" != "") {
		if (`ci_level' <= 0 | `ci_level' >= 100) {
			di as error "mvcrr: ci_level() must be between 1 and 99"
			exit 198
		}
		tempname _bB
		capture mata: st_numscalar("`_bB'", c.boot_B)
		if _rc | missing(scalar(`_bB')) | scalar(`_bB') <= 0 {
			di as error "mvcrr: bootstrap requires mvgstudy to have been run with the bootstrap option first"
			exit 198
		}
		if `pw' {
			mata: st_local("_crr_bufac", tokens(subinstr(subinstr(c.effects[1], "|", " "), "#", " "))[1])
			if "`_crr_bufac'" != "`object'" {
				di as error "mvcrr: pwmeans with bootstrap requires object() to be the first facet of the first effect ('`_crr_bufac'') because per-replicate person-weighted means are stored for that facet"
				exit 198
			}
		}
		local ci_alpha = (100 - `ci_level') / 100
	}

	//---//
	// Number of objects (small-sample warning threshold, spec rev. 3)
	//---//
	tempname _nobj
	mata: st_numscalar("`_nobj'", c.facetlevels[selectindex(c.facets :== "`object'")])
	local n_obj = scalar(`_nobj')

	//---//
	// Apply fix() augmentation (mutates c; restored below, also on error)
	//---//
	if `n_fixed' > 0 {
		mata c.apply_fixed_facets("`object'", tokens("`fixed_names'"), st_matrix("`_fixed_ns'"))
	}

	capture noisily {
		//---//
		// Design-level setup, then compute
		//---//
		mata c._crr_setup("`object'", "`avar'", "`jvar'", "`pvar'", ///
		                  tokens("`nf_names'"), st_matrix("`_nf_ns'"), ///
		                  `use_current', `srmode', `nl')
		if `srmode' {
			mata c.compute_crr_sr(`nu0', `nu1', `nutt', `rho_lp', ///
			                      "`n0var'", "`n1var'", ///
			                      "`CMP'", "`COV'", "`ERR'", "`SVM'", "`scn'")
		}
		else {
			mata c.compute_crr(`pw', `sig_mode', `s1', `s2', `s3', ///
			                   "`CMP'", "`COV'", "`ERR'", "`scn'")
		}
		// Resolved D-study sizes and realization divisor (from Mata state)
		if !`srmode' {
			mata: st_local("_crr_nfres", invtokens(c.crr_facets :+ " " :+ strofreal(c.crr_facetn)))
			local nf_str "`_crr_nfres'"
		}
		mata: st_local("_crr_deps", strofreal(c.crr_deps))

		//---//
		// Display
		//---//
		local sig_src "0 (default; utterance-sampling noise absorbed in the facet components)"
		if `sig_mode' == 1 local sig_src "user-supplied via sigmae()"
		if `sig_mode' == 2 local sig_src "closed form from nu0(), nu1(), nutt()"
		local mean_src "observation-weighted grand means"
		if `pw' local mean_src "person-weighted means (pwmeans; mean of within-`object' means)"
		if `srmode' {
			local modelab "single-replication mode: object-level DCF, disattenuated"
		}
		else {
			local modelab "DCF at every effect containing `object'"
		}

		di as text _newline "Projected Construct-Relevant Reliability (`modelab')"
		di as text "{hline 72}"
		di as text "  CRR_zc  (ranking statistic; zero-covariance)" _column(50) "= " as result %9.4f scalar(`C_crr')
		di as text "  A-bar   (mean false-positive intercept)" _column(50) "= " as result %9.4f scalar(`C_ab')
		di as text "  J-bar   (mean class separation)" _column(50) "= " as result %9.4f scalar(`C_jb')
		di as text "  delta_beta (alignment check; beta - J-bar)" _column(50) "= " as result %9.4f scalar(`C_db')
		di as text "  CRR_orth (orthogonal, naive; upper edge)" _column(50) "= " as result %9.4f scalar(`C_cro')
		di as text "  CRR_bc   (orthogonal, bias-corr.; lower edge)" _column(50) "= " as result %9.4f scalar(`C_crb')
		di as text "{hline 72}"
		di as text "  lambda_zc" _column(50) "= " as result %9.4f scalar(`C_lam')
		di as text "  Erho2_DCF:`object' (zero-covariance)" _column(50) "= " as result %9.4f scalar(`C_er')
		di as text "  lambda_orth = corr(tau, pi)^2" _column(50) "= " as result %9.4f scalar(`C_lo')
		di as text "  lambda_bc" _column(50) "= " as result %9.4f scalar(`C_lb')
		di as text "  Erho2_DCF:`object' (covariance-inclusive)" _column(50) "= " as result %9.4f scalar(`C_ero')
		di as text "  beta (slope of universe score on prevalence)" _column(50) "= " as result %9.4f scalar(`C_beta')
		di as text "  mu_pi (mean prevalence)" _column(50) "= " as result %9.4f scalar(`C_mp')
		di as text "  sigma2_eps (realization variance)" _column(50) "= " as result %9.6f scalar(`C_se')
		di as text "        source: `sig_src'"
		di as text "        divided by d(eps) = " as result "`_crr_deps'"
		di as text "  D-study sizes: " as result "`nf_str'"
		if `n_fixed' > 0 di as text "  fixed facets:  " as result "`fix'"
		if `srmode' {
			di as text "  rho_LP (sigma2_pi_LP / sigma2_pi)" _column(50) "= " as result %9.4f `rho_lp'
		}
		di as text "  number of objects (`object')" _column(50) "= " as result %9.0g `n_obj'
		di as text "  A-bar/J-bar/mu_pi from: `mean_src'"
		di as text ""
		matlist `CMP', twidth(12) format(%12.6f) ///
			title("Variance components as used, zero-covariance path (post-truncation)")
		di as text ""
		matlist `COV', twidth(12) format(%12.6f) ///
			title("Covariance components as used, orthogonal path (post-truncation, PSD-repaired)")
		if rowsof(`ERR') > 0 & !missing(`ERR'[1,1]) {
			di as text ""
			matlist `ERR', twidth(12) format(%12.6f) ///
				title("Error contributions by effect (V(e)/d(e))")
		}
		if `srmode' {
			di as text ""
			matlist `SVM', twidth(12) format(%12.6f) ///
				title("Mean per-object sampling variances subtracted (disattenuation)")
		}

		if scalar(`C_tr') > 0 {
			di as text "(note: `=scalar(`C_tr')' negative variance component(s) truncated at zero)"
		}
		if scalar(`C_psd') > 0 {
			di as text "(note: `=scalar(`C_psd')' component matrix/matrices repaired to positive" ///
			           " semidefinite by eigenvalue clipping on the orthogonal path)"
		}
		if scalar(`C_ub') == 1 {
			di as text "(note: object-level DCF components truncated to zero; lambda_zc = 1 by" ///
			           " construction and CRR_zc is an upper bound, not an estimate)"
		}
		if missing(scalar(`C_crb')) {
			di as text "(note: CRR_bc not available: the Wishart plug-in needs an invertible" ///
			           " expected-mean-square matrix for the design)"
		}
		if !`srmode' & `sig_mode' > 0 & scalar(`C_se') > 0 {
			di as text "(note: sigmae > 0 assumes the generalization-facet components are" ///
			           " disattenuated for utterance-sampling error; otherwise this noise" ///
			           " is counted twice)"
		}
		mata: st_local("_crr_isbal", strofreal(c.crr_isbal))
		if "`_crr_isbal'" == "0" {
			di as text "(note: unbalanced design; CRR_bc uses the balanced-design Wishart" ///
			           " approximation with the observed expected-mean-square coefficients)"
		}
		if `n_obj' < 50 {
			di as text "{err}Warning:{txt} only `n_obj' objects (fewer than 50). Rank on CRR_zc, read"
			di as text "         [CRR_bc, CRR_orth] as a sensitivity bracket, and use bootstrap for"
			di as text "         reportable inference: at small object samples the orthogonal"
			di as text "         estimators are biased (naive upward, corrected downward) and"
			di as text "         delta_beta is noisy (see help mvcrr, Remarks: small samples)."
		}

		//---//
		// Bootstrap BCa CIs for the panel (opt-in)
		//---//
		if ("`bootstrap'" != "") {
			di as text _newline "Running CRR bootstrap (`ci_level'% BCa CIs, B=`=scalar(`_bB')')..."
			mata c.run_crr_bootstrap(`pw', `sig_mode', `s1', `s2', `s3', `ci_alpha', "`CRT'")
			di as text "CRR bootstrap complete."
			di as text ""
			matlist `CRT', format(%9.4f) ///
				title("Bootstrap Summary: CRR panel (`ci_level'% BCa CI)")
		}
	}
	local _body_rc = _rc
	if `_body_rc' != 0 {
		if `n_fixed' > 0 capture mata c.restore_fixed_facets()
		exit `_body_rc'
	}
	if `n_fixed' > 0 mata c.restore_fixed_facets()

	//---//
	// Returned results (return matrix moves the matrix: all display above)
	//---//
	return scalar crr         = scalar(`C_crr')
	return scalar crr_zc      = scalar(`C_crr')
	return scalar Abar        = scalar(`C_ab')
	return scalar Jbar        = scalar(`C_jb')
	return scalar dbeta       = scalar(`C_db')
	return scalar beta        = scalar(`C_beta')
	return scalar crr_orth    = scalar(`C_cro')
	return scalar crr_bc      = scalar(`C_crb')
	return scalar lambda      = scalar(`C_lam')
	return scalar lambda_zc   = scalar(`C_lam')
	return scalar lambda_orth = scalar(`C_lo')
	return scalar lambda_bc   = scalar(`C_lb')
	return scalar erho2       = scalar(`C_er')
	if `srmode' {
		return scalar erho2_dcfp = scalar(`C_er')
		return scalar rho_lp     = `rho_lp'
		return scalar nl         = `nl'
	}
	else {
		return scalar erho2_dcfpl = scalar(`C_er')
		if `nl' != 0 return scalar nl = `nl'
	}
	return scalar erho2_orth  = scalar(`C_ero')
	return scalar mupi        = scalar(`C_mp')
	return scalar sigmae      = scalar(`C_se')
	return scalar d_eps       = `_crr_deps'
	return scalar n_obj       = `n_obj'
	return scalar pwmeans     = `pw'
	return scalar trunc       = scalar(`C_tr')
	return scalar psdfix      = scalar(`C_psd')
	return scalar ub          = scalar(`C_ub')
	return scalar varC        = scalar(`C_vc')
	return scalar var_obj_zc   = scalar(`C_vz')
	return scalar var_obj_orth = scalar(`C_vo')
	return scalar err_zc      = scalar(`C_ez')
	return scalar err_orth    = scalar(`C_eo')
	return local  object      "`object'"
	return local  nfacet      "`nf_str'"
	return local  fix         "`fix'"
	return local  avar        "`avar'"
	return local  jvar        "`jvar'"
	return local  pvar        "`pvar'"
	return matrix components  = `CMP'
	return matrix covcomps    = `COV'
	if rowsof(`ERR') > 0 & !missing(`ERR'[1,1]) return matrix errors = `ERR'
	if `srmode' return matrix sampvar = `SVM'
	if ("`bootstrap'" != "") return matrix crr_table = `CRT'

end
