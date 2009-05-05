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
    { return_url "/intranet-exchange-rate/index" }
}

set today [lindex [split [ns_localsqltimestamp] " "] 0]

set currency_url [parameter::get_from_package_key -package_key "intranet-exchange-rate" -parameter "ExchangeRateUrlXRates" -default "http://projop.project-open.net/intranet-asus-server/exchange-rates.xml"]


set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set page_title "Automatic Software Updates"
set context_bar [im_context_bar $page_title]
set context [list [list "../developer" "Developer's Administration"] $page_title]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

set system_id [im_system_id]
set full_url [export_vars -base $currency_url {system_id}]

ns_log Notice "load-update-xml-2: full_url=$full_url"
ns_log Notice "load-update-xml-2: system_id=$system_id"

# ------------------------------------------------------------
# Return the HTTP header etc.
ns_write "
        [im_header]
        [im_navbar]

	<h2>Getting data</h2>
	<ul>
"

# ------------------------------------------------------------
# Fetch the update.xml file from the remote server
#

ns_write "<li>Getting exchange rates XML file from '$currency_url' ...\n"

set update_xml ""
if { [catch {
	set update_xml [ns_httpget $full_url]
} errmsg] } {
    ad_return_complaint 1 "Error while accessing the URL '$currency_url'.<br>
	Please check your URL. The following error was returned: <br>
	<blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
    return
}	

if {"" == $update_xml} {
    ad_return_complaint 1 "Found an empty XML file accessing the URL '$currency_url'.<br>
	This means that your server(!) was not able to access the URL.<br>
	Please check the the Internet and firewall configuration of your
	server and verify that the 'nsd' (Linux) or 'nsd4' (Windows) 
	process has access to the URL.<br>"
    return
}	

ns_write "Success</li>\n"
ns_write "
</ul>
<h2>Processing Data</h2>
<ul>
"


# ------------------------------------------------------------
# Check whether it's a HTML or an XML
#
# The correct XML outplut will look like this:
# <asus_reply>
# <error>ok</error>

if {![regexp {<([^>]*)>\s*<([^>]*)>} $update_xml match tag1 tag2]} {
    ns_write "
	<li>
		<font color=red>
		Error while retreiving update information from
		URL '$currency_url'.<br>
		The retreived files doesn't seem to be a XML or HTML file:<br>
		<pre>$update_xml</pre>
		</font>
	</li>
    "
    set update_xml ""
}

if {[string tolower $tag1] == "html" || [string tolower $tag2] == "html"} {
    ns_write "
	<li>
		<font color=red>
		Error while retreiving update information from  URL<br>
		'$currency_url'.<br>
		The retreived result seems to be a HTML document and not an XML document.<br>
		Please check the URL above and/or send an error report to 
		<a href=\"mailto:support@project-open.com\">support@project-open.com</a>.
		<br>&nbsp;</br>
		Here is what the server returned:
		<br>&nbsp;</br>
		<pre>$update_xml</pre>
		</font>
	</li>
    "
    set update_xml ""
}


# ------------------------------------------------------------
# Enabled Currencies
# ------------------------------------------------------------

set enabled_currencies_sql "
	select	iso
	from	currency_codes
	where	supported_p = 't'
"
db_foreach encur $enabled_currencies_sql {
    set enabled_currencies_hash($iso) 1 
}

# ------------------------------------------------------------
# Parse the XML file and generate the HTML table
#

# Sample record:
#
#<asus_reply>
#<error>ok</error>
#<error_message>Success</error_message>
#<exchange_rate iso="AUD" day="2009-04-05">0.713603</exchange_rate>
#<exchange_rate iso="CAD" day="2009-04-05">0.805626</exchange_rate>
#<exchange_rate iso="EUR" day="2009-04-05">1.342500</exchange_rate>
#</asus_reply>

set tree [xml_parse -persist $update_xml]
set root_node [xml_doc_get_first_node $tree]
set root_name [xml_node_get_name $root_node]
if { ![string equal $root_name "asus_reply"] } {
    ad_return_complaint 1 "Expected &lt;asus_reply&gt; as root node of update.xml file, found: '$root_name'"
}

set ctr 0
set debug ""
set root_nodes [xml_node_get_children $root_node]


# login_status = "ok" or "fail"
set login_status [[$root_node selectNodes {//error}] text]
set login_message [[$root_node selectNodes {//error_message}] text]

foreach root_node $root_nodes {

    set root_node_name [xml_node_get_name $root_node]
    ns_log Notice "load-update-xml-2: node_name=$root_node_name"

    switch $root_node_name {

	# Information about the successfull/unsuccessful SystemID
	error {
	    # Ignore. Info is extracted via XPath above
	}
	error_message {
	    # Ignore. Info is extracted via XPath above
	}

	exchange_rate {
	    # <exchange_rate iso="CAD" day="2009-04-05">0.805626</exchange_rate>
	    set currency_code [apm_attribute_value -default "" $root_node iso]
	    set currency_day [apm_attribute_value -default "" $root_node day]
	    set exchange_rate [xml_node_get_content $root_node]
	    ns_write "<li>exchange_rate($currency_code,$currency_day) = $exchange_rate...\n"

	    if {![info exists enabled_currencies_hash($currency_code)]} {

		ns_write "Discarded (not an active currency)</li>\n"

	    } else {

		# Insert values into the Exchange Rates table
		if {"" != $currency_code && "" != $currency_day} {
			
		    db_dml delete_entry "
				delete  from im_exchange_rates
				where   day = :currency_day::date and
					currency = :currency_code
		    "
	
		    db_dml insert_rates "
				insert into im_exchange_rates (
					day,
					currency,
					rate,
					manual_p
				) values (
					:currency_day::date,
					:currency_code,
					:exchange_rate,
					't'
				)
		    "
	
		    im_exec_dml invalidate "im_exchange_rate_invalidate_entries (:currency_day::date, :currency_code)"
		    set fill_hole_currency_hash($currency_code) 1
		}
		ns_write "Success</li>\n"
	    }
	}

	default {
	    ns_log Notice "load-update-xml-2.tcl: ignoring root node '$root_node_name'"
	}
    }
}

ns_write "<li>Freeing document nodes</li>\n"
xml_doc_free $tree


foreach cur [array names fill_hole_currency_hash] {
    ns_write "<li>Extrapolating exchange rates for '$cur' ... \n"
    im_exec_dml invalidate "im_exchange_rate_fill_holes(:cur)"
    ns_write "Success</li>\n"
}

ns_write "<li>Finished.</li>\n"
ns_write "</ul>\n"
ns_write "<p>&nbsp;</p>\n"

ns_write "<ul><li><a href=\"$return_url\">Return to previous page</a></li></ul>\n"

ns_write [im_footer]
