//----------------------------------------------------------------------------//
*! _mvg_parse_equation  version 1.5.0  26aug2026
*! v1.5.0: mvcrr generalized (any design; covariance-inclusive panel); the
*!  Mata library gains fix() augmentation weights.  Requires Stata 19.  History: CHANGELOG.md.
*! Private helper for mvgstudy: splits (varlist = termlist) into r(vars), r(effects).
//----------------------------------------------------------------------------//

program _mvg_parse_equation, rclass
	version 19
	syntax anything

	mata: parse_equation_mata(st_local("anything"))
	return local vars `vars'
	return local effects `effects'
end
