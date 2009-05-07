# /packages/intranet-exchange-rate/www/index.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-06-04
    @cvs-id $Id$

} {
    {orderby "package_key"}
    {year ""}
}

# ---------------------------------------------------------------
# Default & Security
# ---------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-exchange-rate.Exchange_Rates "Exchange Rates"]
set context [list $page_title]
set page_focus "im_header_form.keywords"
set today [lindex [split [ns_localsqltimestamp] " "] 0]

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $year} {
    set year [lindex [split [ns_localsqltimestamp] "-"] 0]
}

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

set supported_currencies [im_supported_currencies]
set missing_text "<strong>No packages match criteria.</strong>"
set use_watches_p [expr ! [ad_parameter -package_id [ad_acs_kernel_id] PerformanceModeP request-processor 1]]
set return_url "[ad_conn url]?[ad_conn query]"

set table_def {
    { xchg_date "Date" "" "<td><a href=\"[export_vars -base new {{form_mode edit} {today $day} return_url}]\">$day</a></td>" }
}

set rate_select ""
set rate_from ""
foreach currency [im_supported_currencies] {
    set low_cur "cur_[string tolower $currency]"
    lappend table_def [list $currency "$currency" "" "<td><font color=\${${low_cur}_color}>\${$low_cur}</font></td>"]

    append rate_select "\t\t,$low_cur.rate as $low_cur\n"
    append rate_select "\t\t,CASE WHEN $low_cur.manual_p ='t' THEN 'black' ELSE 'grey' END as ${low_cur}_color\n"

    append rate_from "\t\tLEFT OUTER JOIN (select day, rate, manual_p from im_exchange_rates where currency='$currency') $low_cur\n\t\tON (days.day = $low_cur.day)\n"

}

set table [ad_table -Torderby $orderby -Tmissing_text $missing_text exchange_rates "" $table_def]

# ------------------------------------------------------------------
# NavBar
# ------------------------------------------------------------------

set form_id "filter"
set action_url "/intranet-exchange-rate/index"
set form_mode "edit"

set year_options [list]
for {set i 1999} {$i <= 2015} {incr i} { lappend year_options [list $i $i] }

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export { }\
    -form {
        {year:text(select),optional {label "[lang::message::lookup {} intranet-core.Year Year]"} {options $year_options}}
    }

template::element::set_value $form_id year $year


# ------------------------------------------------------------------
# NavBar
# ------------------------------------------------------------------

# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<formtemplate id="filter"></formtemplate>}]
set filter_html $__adp_output

# Left Navbar is the filter/select part of the left bar
set left_navbar_html "
        <div class='filter-block'>
                <div class='filter-title'>
                   [lang::message::lookup "" intranet-exchange-rate.Filter_Rates "Filter Rates"]
                </div>
                $filter_html
        </div>
      <hr/>
"

set currency_url [parameter::get_from_package_key -package_key "intranet-exchange-rate" -parameter "ExchangeRateUrlXRates" -default "http://www.x-rates.com/d/USD/table.html"]

set admin_html "
	<ul>
<!--
	<li><a href='get-exchange-rates'>[lang::message::lookup "" intranet-exchange-rate.Get_exchange_rates_for_today "Get exchange rates for today from <br>%currency_url%"]</a><br></li>
-->
	<li><a href='active-currencies'>[lang::message::lookup "" intranet-exchange-rate.Active_currencies "Manage Active Currencies"]</a><br></li>
	</ul>
"

append left_navbar_html "
      <div class='filter-block'>
         <div class='filter-title'>
            [lang::message::lookup "" intranet-exchange-rate.Admin_Links "Admin Links"]
         </div>
         $admin_html
      </div>
"


