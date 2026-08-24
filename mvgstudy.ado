//----------------------------------------------------------------------------//
*! mvgstudy  version 1.4.0  24aug2026
*! v1.4.0: one command per file; Mata moved to lmvgstudy.mlib; moremata no
*!  longer required.  Requires Stata 19.  History: CHANGELOG.md.
//----------------------------------------------------------------------------//

program mvgstudy, rclass
	version 19
	syntax anything [if] [in] [, Bootstrap REPs(integer 1000) CI_level(integer 95) SEED(string) BOOTunit(string)]

	marksample touse
	tempname facetlevels df_mat P_mat _cp_slvd

	//---//
	// Validate input
	//---//
	if !regexm(`"`anything'"', "\(.*=.*\)") {
		di as error "mvgstudy: invalid syntax -- expected (varlist = termlist)"
		exit 198
	}

	//---//
	// Set up
	// c persists after this program exits so that mvdstudy can access it.
	// Run "mata drop c" manually when all d-studies are complete.
	//---//
	mata c = mvgstudy()
	_mvg_parse_equation `anything'
	local tempvarlist `r(vars)'
	local effects `r(effects)'
	mata expand_if_residual()
	mata st_local("effects",invtokens(c.sortbylength(tokens(st_local("effects")),0)))
	foreach var of varlist `tempvarlist' {
		local varlist : list varlist | var
	}

	mata facets = uniqrows(tokens(subinstr(subinstr(invtokens(st_local("effects")),"|"," "), "#"," "))')
	mata st_local("facets",invtokens(facets'))
	foreach facet of local facets {
		qui levelsof `facet' if `touse' == 1
		matrix `facetlevels' = (nullmat(`facetlevels') \ `r(r)')
	}
	//---//
	// Direct SSCP computation
	//---//
	mata Y = st_data(., tokens(st_local("varlist")), "`touse'")
	mata Z = st_data(., tokens(st_local("facets")), "`touse'")
	mata c.init_inputs_direct(Y, Z, tokens(st_local("effects")), tokens(st_local("facets")), tokens(st_local("varlist")), st_matrix("`facetlevels'"))
	mata mata drop Y Z facets

	//---//
	// Mata mvgstudy main routine
	//---//
	mata c.mvgstudy_main_routine()
	mata for (loc=asarray_first(c.covcomps); loc!=NULL; loc=asarray_next(c.covcomps, loc)) st_matrix(asarray_key(c.covcomps, loc),asarray_contents(c.covcomps, loc))
	mata st_matrix("`df_mat'",c.df)
	mata st_matrix("`P_mat'",c.P)

	//---//
	// Results
	//---//
	local lengtheffectlist : list sizeof local(effects)
	foreach x of local varlist {
		local name "`x'"
		local names `" `names' "`name'" "'
	}
	local _neg_warn 0
	forvalues i = 1/`lengtheffectlist' {
		matrix rownames emcp`i' = `names'
		matrix colnames emcp`i' = `names'
		matlist emcp`i' , twidth(20) title("`:word `i' of `effects'' Component")
		// Check for negatives before return matrix clears the local copy
		mata: st_numscalar("_min_diag_`i'", min(diagonal(st_matrix("emcp`i'"))))
		if scalar(_min_diag_`i') < 0 local _neg_warn 1
		return matrix emcp`i' = emcp`i'
	}
	if `_neg_warn' {
		di as text "(note: one or more variance component estimates are negative;" ///
		           " this is expected for near-zero components in unbalanced designs;" ///
		           " see Brennan 2001, Ch. 3)"
	}

	return matrix P = `P_mat'
	return matrix df = `df_mat'
	return local varlist `varlist'
	return local effects `effects'
	mata: st_numscalar("`_cp_slvd'", c.cp_solved)
	return scalar cp_solved = `_cp_slvd'

	//---//
	// Phase 10a: Bootstrap CIs (opt-in)
	//---//
	if ("`bootstrap'" != "") {
		// Validate scalar options
		if (`reps' < 1) {
			di as error "mvgstudy: reps() must be >= 1"
			exit 198
		}
		if (`ci_level' <= 0 | `ci_level' >= 100) {
			di as error "mvgstudy: ci_level() must be between 1 and 99"
			exit 198
		}
		if ("`seed'" != "") {
			confirm integer number `seed'
			set seed `seed'
		}

		// Resolve bootunit: default to first single-facet effect (object of measurement)
		if ("`bootunit'" == "") {
			mata st_local("bootunit", tokens(subinstr(subinstr(c.effects[1], "|", " "), "#", " "))[1])
		}
		// Validate: every bootunit facet must be a design facet
		foreach bu_fac of local bootunit {
			if !`:list bu_fac in facets' {
				di as error "mvgstudy: bootunit facet '`bu_fac'' is not in the design facets (`facets')"
				exit 198
			}
		}

		local ci_alpha = (100 - `ci_level') / 100
		di as text _newline "Running bootstrap (B=`reps', boot-`bootunit', `ci_level'% BCa CIs)..."
		mata c.run_bootstrap(`reps', `ci_alpha', tokens("`bootunit'"))
		di as text "Bootstrap complete."

		// Display and return bootstrap tables
		forvalues i = 1/`lengtheffectlist' {
			local effname   : word `i' of `effects'
			// Sanitize effect name for use as Stata matrix name (# and | not allowed)
			local effname_c = subinstr(subinstr("`effname'", "#", "_", .), "|", "_", .)
			tempname _btab`i'
			mata c.push_boot_r_matrix("emcp`i'", "`_btab`i''", `ci_alpha')
			di as text _newline "Bootstrap Summary: `effname' Component (`ci_level'% BCa CI)"
			matlist `_btab`i'', twidth(20) format(%9.4f)
			return matrix emcp_table_`effname_c' = `_btab`i''
		}
	}

end
