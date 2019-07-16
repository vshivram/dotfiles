*! version 2.0   11dec03   Chris Metli

program define spread, sortpreserve

	version 8.0
	syntax varlist [if] [in], by(varlist) [Zero]

	* mark the sample
	marksample touse, novarlist

	* create tempvariable and preserve
	tempvar var_last
	preserve

	* loop over variables in varlist
	foreach var of local varlist {

		* check which type of variable var is, set negative sign for sort if is numeric
		capture confirm numeric variable `var'
		if (!_rc) {
			local sign "-"
			local missmark "."
		}
		else {
			local sign ""
			local missmark `""""'
		}
		
		* create variable equal to last value of variable to spread - thereby spreading it
		gsort `by' `sign'`var', mfirst
		quietly by `by': generate `var_last' = `var'[_N] if `touse'
		
		* test for consistency in the variable to spread within by groups (not counting missings)
		capture assert `var_last'==`var' if `var'~=`missmark' & `touse'
		if _rc {
			display as error "`var' not unique within `by'"
			exit 9
		}
		
		* count number of changes to be made
		if "`zero'"=="zero" quietly count if (`var'!=`var_last' | `var_last'>=.) & `touse'
		else quietly count if `var'!=`var_last' & `touse'
		local changes = r(N)
	
		* replace original variable with its filled value
		quietly replace `var' = `var_last' if `touse'
		
		* replace with zeros if option is on
		if "`zero'"=="zero"	quietly replace `var' = 0 if `var'>=. & `touse'
		
		* display changes made
		local s = cond(`changes'==1,"","s")
		display as text "(`changes' real change`s' made)"
		
		* drop temporary variable for next loop
		drop `var_last'
	
	* end loop over variables
	}

	restore, not

end /* end program spread */

