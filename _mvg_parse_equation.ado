//----------------------------------------------------------------------------//
*! _mvg_parse_equation  version 1.4.0  24aug2026
*! v1.4.0: one command per file; Mata moved to lmvgstudy.mlib; moremata no
*!  longer required.  Requires Stata 19.  History: CHANGELOG.md.
*! Private helper for mvgstudy: splits (varlist = termlist) into r(vars), r(effects).
//----------------------------------------------------------------------------//

program _mvg_parse_equation, rclass
	version 19
	syntax anything

	mata: parse_equation_mata(st_local("anything"))
	return local vars `vars'
	return local effects `effects'
end
