# /packages/intranet-exchange-rate/tcl/intranet-exchange-rate-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Common procedures for Exchange Rates
    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# PackageID for Parameters
# ----------------------------------------------------------------------


ad_proc -public im_package_exchange_rate_id { } {
} {
    return [util_memoize "im_package_exchange_rate_id_helper"]
}

ad_proc -private im_package_exchange_rate_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-exchange_rate'
    } -default 0]
}


# ----------------------------------------------------------------------
# Exchange Rate from TCL
# ----------------------------------------------------------------------

ad_proc im_exchange_rate { day from_cur to_cur } {
    Returns the exchange rate for a given day
} {
    return [im_exchange_rate_helper $day $from_cur $to_cur]
}


ad_proc im_exchange_rate_helper { day from_cur to_cur } {
    Returns the exchange rate for a given day
} {
    return [db_exec_plsql exchange_rate {}]
}



# ----------------------------------------------------------------------
# Exchange Rate Maintenance
# ----------------------------------------------------------------------

ad_proc im_exchange_rate_outdated_currencies { } {
    Returns an empty list if everything OK.
    Otherwise returns a list of currency - days_outdated
    for the "supported_currencies" that are outdated.
} {
    set max_days_outdated [ad_parameter -package_id [im_package_exchange_rate_id] "MaxDaysOutdated" "" 7]
    set currency_date_map [im_exchange_rate_outdated_map]

    set result [list]
    foreach entry $currency_date_map {
	set currency [lindex $entry 0]
	set days_outdated [lindex $entry 1]

	if {$days_outdated > $max_days_outdated} { 
	    lappend result [list $currency $days_outdated] 
	}
    }
    return $result
}


ad_proc im_exchange_rate_outdated_map { } {
    Returns a hash-map from supported currencies into 
    days_outdated and last_date
} {
   set currency_date_map [db_list_of_lists outdated_currencies "
	select
		currency,
		now()::date - max(day) as days_outdated,
		max(day) as last_update
	from
		currency_codes cc,
		(
			select	max(day) as day,
				currency
			from	im_exchange_rates
			where	manual_p = 't'
			group	by currency
		    UNION
			select	to_date('1999-01-01', 'YYYY-MM-DD') as day,
				iso as currency
			from	currency_codes
			where	supported_p = 't'
		) e
	where
		cc.iso = e.currency and
		cc.supported_p = 't'
	group by currency
    "]

    return $currency_date_map
}


