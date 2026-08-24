//----------------------------------------------------------------------------//
*! mvdstudy  version 1.4.0  24aug2026
*! v1.4.0: one command per file; Mata moved to lmvgstudy.mlib; moremata no
*!  longer required.  Requires Stata 19.  History: CHANGELOG.md.
//----------------------------------------------------------------------------//

program mvdstudy, rclass
	version 19
	syntax, Object(string) Errortype(string) ///
	        [FACETnum(numlist integer >=1) CURRent COMPositeweights(string) ///
	         Bootstrap CI_level(real 95) FIX(string)]

	tempname _nv

	//---//
	// Validate that mvgstudy results exist
	//---//
	capture mata: st_numscalar("`_nv'", length(c.varlist))
	if _rc {
		di as error "mvdstudy: no mvgstudy results in memory; run mvgstudy first"
		exit 301
	}

	//---//
	// Validate inputs
	//---//
	if ("`errortype'" == "relative") local etype = 0
	else if ("`errortype'" == "absolute") local etype = 1
	else {
		di as error "mvdstudy: errortype must be 'relative' or 'absolute'"
		exit 198
	}

	// facetnum and current are mutually exclusive; at least one required
	if ("`facetnum'" != "" & "`current'" != "") {
		di as error "mvdstudy: facetnum() and current are mutually exclusive"
		exit 198
	}
	if ("`facetnum'" == "" & "`current'" == "") {
		di as error "mvdstudy: specify either facetnum() or current"
		exit 198
	}

	// compositeweights validation
	if ("`compositeweights'" != "") {
		capture confirm matrix `compositeweights'
		if _rc {
			di as error "mvdstudy: compositeweights matrix '`compositeweights'' not found"
			exit 198
		}
		mata st_local("_nvarlist", strofreal(length(c.varlist)))
		if (rowsof(`compositeweights') != `_nvarlist') | (colsof(`compositeweights') != 1) {
			di as error "mvdstudy: compositeweights must be a `_nvarlist'x1 column vector"
			exit 198
		}
	}

	//---//
	// Phase 11: parse fix() and apply fixed-facet augmentation
	//---//
	local n_fixed 0
	if "`fix'" != "" {
		local n_fix_toks : word count `fix'
		if mod(`n_fix_toks', 2) != 0 {
			di as error "mvdstudy: fix() requires alternating facet names and integers, e.g., fix(i 5)"
			exit 198
		}
		local n_fixed = `n_fix_toks' / 2
		tempname _fixed_ns
		matrix `_fixed_ns' = J(1, `n_fixed', .)
		local fixed_names ""
		forvalues fk = 1/`n_fixed' {
			local _fn : word `=2*`fk'-1' of `fix'
			local _fv : word `=2*`fk'' of `fix'
			capture confirm integer number `_fv'
			if _rc | `_fv' <= 0 {
				di as error "mvdstudy: fix() values must be positive integers (got '`_fv'' for facet '`_fn'')"
				exit 198
			}
			local fixed_names "`fixed_names' `_fn'"
			matrix `_fixed_ns'[1, `fk'] = `_fv'
		}
		local fixed_names = strtrim("`fixed_names'")
		mata c.apply_fixed_facets("`object'", tokens("`fixed_names'"), st_matrix("`_fixed_ns'"))
	}

	//---//
	// Build projectionnum vector and observe_only flag
	//---//
	if ("`current'" != "") {
		// Single-point at observed G-study sample sizes
		tempname _fnum
		matrix `_fnum' = J(1, 1, 0)   // dummy; init_dstudyinputs ignores when observe_only=1
		if ("`compositeweights'" == "") {
			mata c.init_dstudyinputs("`object'", `etype', st_matrix("`_fnum'"), 1)
		}
		else {
			mata c.init_dstudyinputs("`object'", `etype', st_matrix("`_fnum'"), 1, ///
			                         st_matrix("`compositeweights'"))
		}
	}
	else {
		// Sweep mode: convert numlist to a Stata matrix row vector
		local nfnum : word count `facetnum'
		tempname _fnum
		matrix `_fnum' = J(1, `nfnum', .)
		forvalues fk = 1/`nfnum' {
			matrix `_fnum'[1, `fk'] = `:word `fk' of `facetnum''
		}
		if ("`compositeweights'" == "") {
			mata c.init_dstudyinputs("`object'", `etype', st_matrix("`_fnum'"), 0)
		}
		else {
			mata c.init_dstudyinputs("`object'", `etype', st_matrix("`_fnum'"), 0, ///
			                         st_matrix("`compositeweights'"))
		}
	}

	//---//
	// D-study routine
	// c persists across calls so mvdstudy can be called multiple times
	// (e.g., relative then absolute) without re-running mvgstudy.
	// Run "mata drop c" manually after all d-studies are complete.
	// Wrap body in capture so fixed-facet state is restored on error.
	//---//
	capture noisily {
		mata c.mvdstudy_main_routine()
		mata c.export_projections()

		//---//
		// Results
		//---//
		foreach v of local vars {
			local names
			foreach x of local colnames {
				local name "`x'"
				local names `" `names' "`name'" "'
			}
			mat colnames `v' = `names'
			matlist `v' , names(c) title("`v'")
			return matrix `v' = `v'
		}
	}
	local _body_rc = _rc
	if `_body_rc' != 0 {
		if `n_fixed' > 0 {
			capture mata c.restore_fixed_facets()
		}
		exit `_body_rc'
	}

	//---//
	// Phase 10d: Bootstrap D-study CIs (opt-in)
	//---//
	if ("`bootstrap'" != "") {
		capture noisily {
			if (`ci_level' <= 0 | `ci_level' >= 100) {
				di as error "mvdstudy: ci_level must be between 1 and 99"
				exit 198
			}
			mata: st_numscalar("_boot_B_ds", c.boot_B)
			if (missing(scalar(_boot_B_ds)) | scalar(_boot_B_ds) <= 0) {
				di as error "mvdstudy: bootstrap requires mvgstudy to have been run with the bootstrap option first"
				exit 198
			}
			if ("`errortype'" == "relative") local coeff_name "erho2"
			else local coeff_name "phi"
			local ci_alpha_ds = (100 - `ci_level') / 100
			di as text _newline "Running D-study bootstrap (`ci_level'% BCa CIs, B=`=scalar(_boot_B_ds)')..."
			mata c.run_dstudy_bootstrap(`ci_alpha_ds')
			di as text "D-study bootstrap complete."
			local _dbidx 0
			foreach v of local vars {
				local ++_dbidx
				tempname _dbtab`_dbidx'
				mata c.push_dstudy_r_matrix("`v'", "`_dbtab`_dbidx''", "`coeff_name'")
				di as text _newline "Bootstrap D-study: `v' (`ci_level'% BCa CI)"
				matlist `_dbtab`_dbidx'', names(c) format(%9.4f)
				return matrix dboot_`v' = `_dbtab`_dbidx''
			}
		}
		local _boot_rc = _rc
		if `_boot_rc' != 0 {
			if `n_fixed' > 0 {
				capture mata c.restore_fixed_facets()
			}
			exit `_boot_rc'
		}
	}

	//---//
	// Phase 11: restore original design after fixed-facet D-study
	//---//
	if `n_fixed' > 0 {
		mata c.restore_fixed_facets()
	}

end
