# /packages/intranet-exchange-rate/www/get-exchange-rates.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2008-08-04
    @cvs-id $Id$
} {
}

set today [lindex [split [ns_localsqltimestamp] " "] 0]

set currency_url [parameter::get_from_package_key -package_key "intranet-exchange-rate" -parameter "ExchangeRateUrlXRates" -default "http://www.x-rates.com/d/USD/table.html"]

# --------------------------------------------------------------------------
# Get he HTML page
if {[catch {set page [ns_httpget $currency_url]} err_msg]} {
    ad_return_complaint 1 "Exchange Rates:<br>Unable to get page '$currency_url'"
    ad_script_abort
}

# --------------------------------------------------------------------------
# The main table is marked using comments in the HTML
if {![regexp {<!-- start content -->(.*)<!-- end content -->} $page match page_content]} {
    ad_return_complaint 1 "Exchange Rates:<br>Unable to extract the 'contents' from page '$currency_url'"
    ad_script_abort
}


# --------------------------------------------------------------------------
# Write out the HTTP header for this "streaming" page
ad_return_top_of_page "
        [im_header]
        [im_navbar]
	<h2>Exchange rates from '$currency_url'</h2>
	<ul>
"

# --------------------------------------------------------------------------
# Extract a number of lines like these:
# <tr bgcolor=\#eeeeee>
# <td><font face="Verdana" size=-1>&nbsp;&nbsp;Australian Dollar&nbsp;&nbsp;</font></td>
# <td align="right"><font face="Verdana" size=-1>&nbsp;<a href="/d/AUD/USD/graph120.html" class="menu">1.10156</a>&nbsp;</font></td>
# <td align="right"><font face="Verdana" size=-1>&nbsp;<a href="/d/USD/AUD/graph120.html" class="menu">0.907803</a>&nbsp;</font></td>
# </tr>

# --------------------------------------------------------------------------
# "Package" the lines based on <tr ...> </tr>

set lines [split $page_content "\n"]
set ctr 0
set max_ctr [llength $lines]
set debug ""
set debug_table ""
set col_ctr 0

while {$ctr < $max_ctr} {

    # skip lines until the first <tr bgcolor...>
    while {$ctr < $max_ctr && ![regexp {^<tr bgcolor=} [lindex $lines $ctr] match]} { incr ctr }
    set cur_line ""

    # Record the lines between <tr> and </tr>
    while {$ctr < $max_ctr && ![regexp {^</tr>} [lindex $lines $ctr] match]} { 
	append cur_line [lindex $lines $ctr]
	incr ctr 
    }
    
    # Now we've got a full line in "cur_line" like this:
    # <tr bgcolor=#eeeeee>  <td><font face="Verdana" size=-1>&nbsp;&nbsp;Australian Dollar&nbsp;&nbsp;</font></td>  <td align="right"><font face="Verdana" size=-1>&nbsp;<a href="/d/AUD/USD/graph120.html" class="menu">1.10156</a>&nbsp;</font></td>  <td align="right"><font face="Verdana" size=-1>&nbsp;<a href="/d/USD/AUD/graph120.html" class="menu">0.907803</a>&nbsp;</font></td>
    lappend debug $cur_line

    # Get rid of &nbsp;
    while {[regexp {^(.*?)\&nbsp\;(.*)$} $cur_line match head tail]} { set cur_line [string trim "$head $tail"] }

    # The one line contains three columns. Start by splitting tags in general.
    if {![regexp {<td(.+)</td>\s*<td(.+)</td>\s*<td(.+)</td>} $cur_line match col1 col2 col3]} {
	continue
	ad_return_complaint 1 "Exchange Rates:<br>Bad line doesn't contain three &lt;td&gt's<br>
	<pre>[ns_quotehtml $cur_line]</pre>"
	ad_script_abort
    }

    # Skip the first line with the table header
    # Col1: width=50%><font face="Verdana" size="-2" color="green">click on values to see graphs</font>
    # Col2: width=25% align="right"><font face="Verdana" size=-1><b>&nbsp;1 USD&nbsp;</b></font>
    # Col3: width=25% align="right"><font face="Verdana" size=-1><b>&nbsp;in USD&nbsp;</b></font>

    if {[regexp {click on values to see graphs} $col1 match]} { continue }

    # Extract values from the following lines:
    # col1: <font face="Verdana" size=-1>&nbsp;&nbsp;Australian Dollar&nbsp;&nbsp;</font>
    # col2: align="right"><font face="Verdana" size=-1>&nbsp;<a href="/d/AUD/USD/graph120.html" class="menu">1.10156</a>&nbsp;</font>
    # col3: align="right"><font face="Verdana" size=-1>&nbsp;<a href="/d/USD/AUD/graph120.html" class="menu">0.907803</a>&nbsp;</font>

    # Restore the "<" in front of col2 and col3
    set col2 "<$col2"
    set col3 "<$col3"

    # For some reason there is a sigle ">" in front of col1
    while {[regexp {^>(.*)} $col1 match rest]} { set col1 [string trim $rest] }

    while {[regexp {^(.*?)<.+?>(.*)$} $col1 match head tail]} { set col1 [string trim "$head $tail"] }
    while {[regexp {^(.*?)<.+?>(.*)$} $col2 match head tail]} { set col2 [string trim "$head $tail"] }
    while {[regexp {^(.*?)<.+?>(.*)$} $col3 match head tail]} { set col3 [string trim "$head $tail"] }

    # Now we have got clean values
    # Check if we find the currency
    set iso [db_string iso "select iso from currency_codes where lower(currency_name) = lower(:col1)" -default ""]

    set rate_value $col3
    lappend debug_table "iso=$iso, name=$col1, value=$rate_value"
    ns_write "<li>Currency=$iso, Name=$col1, Value=$rate_value</li>\n"

    # Insert values into the Exchange Rates table
    if {"" != $iso && "" != $rate_value} {

	db_dml delete_entry "
                delete from im_exchange_rates
                where
                        day = to_date(:today, 'YYYY-MM-DD')
                        and currency = :iso
        "

  	db_dml update_rates "
                insert into im_exchange_rates (
                        day,
                        currency,
                        rate,
                        manual_p
                ) values (
                        to_date(:today, 'YYYY-MM-DD'),
                        :iso,
                        :rate_value,
                        't'
                )
        "

	im_exec_dml invalidate "im_exchange_rate_invalidate_entries (to_date(:today, 'YYYY-MM-DD'), :iso)"
	im_exec_dml invalidate "im_exchange_rate_fill_holes(:iso)"

    }

    incr col_ctr
}

ns_write "<p>Finished.</p>\n"
ns_write [im_footer]
