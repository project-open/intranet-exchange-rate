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

set currency_url [parameter::get_from_package_key -package_key "intranet-exchange-rate" -parameter "ExchangeRateUrlXRates" -default "http://projop.project-open.net/intranet-asus-server/exchange-rates.xml"]


set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Automatic Software Updates"
set context_bar [im_context_bar $page_title]
set context [list [list "../developer" "Developer's Administration"] $page_title]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

set core_versions [db_list core_versions "
	select version_name
	from apm_package_versions
	where version_id in (
		select max(version_id) 
		from apm_package_versions 
		where package_key = 'intranet-core'
	)
"]
set core_version [lindex $core_versions 0]

set full_url [export_vars -base $service_url {{email $service_email} {password $service_password} core_version }  ]

ns_log Notice "load-update-xml-2: full_url=$full_url"
ns_log Notice "load-update-xml-2: service_email=$service_email"

set update_xml ""


# ------------------------------------------------------------
# Fetch the update.xml file from the remote server
#

if { [catch {
    set update_xml [ns_httpget $full_url]
} errmsg] } {
    ad_return_complaint 1 "Error while accessing the URL '$service_url'.<br>
    Please check your URL. The following error was returned: <br>
    <blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
    return
}	

if {"" == $update_xml} {
    ad_return_complaint 1 "Found an empty XML file accessing the URL '$service_url'.<br>
    This means that your server(!) was not able to access the URL.<br>
    Please check the the Internet and firewall configuration of your
    server and verify that the 'nsd' (Linux) or 'nsd4' (Windows) 
    process has access to the URL.<br>
    return
}	



# ------------------------------------------------------------
# Check whether it's a HTML or an XML
#

if {![regexp {<([^>]*)>\s*<([^>]*)>\s*<([^>]*)>} $update_xml match tag1 tag2 tag3]} {
    ad_return_complaint 1 "Error while retreiving update information from
    URL '$service_url'.<br>The retreived files doesn't seem to be a XML or HTML file:<br>
    <pre>$update_xml</pre>"
    return
}

if {[string tolower $tag1] == "html" || [string tolower $tag2] == "html" || [string tolower $tag3] == "html"} {
    ad_return_complaint 1 "Error while retreiving update information from  URL<br>
    '$service_url'.<br>
    The retreived result seems to be a HTML document and not an XML document.<br>
    Please check the URL above and/or send an error report to 
    <a href=\"mailto:support@project-open.com\">support@project-open.com</a>.
    <br>&nbsp;</br>
    Here is what the server returned:
    <br>&nbsp;</br>
    <pre>$update_xml</pre>"
}

ns_log notice "load-update-xml-2: match=$match, tag1=$tag1, tag2=$tag2, tag3=$tag3"


# ------------------------------------------------------------
# Parse the XML file and generate the HTML table
#

# Sample record:
#
# <po_software_update>
#   <login>
#     <login_status>ok</login_status>
#     <login_message>Successful Login</login_message>
#   </login>
#  <account>
#  </account>
#  <update_list>
#   <update>
#     <package_name>intranet-wiki</package_name>
#     <package_url>http://www.project-open.com/product/modules/km/wiki.html</package_url>
#     <package_version>3.0.0</package_version>
#     <po_version>3.0.beta8</po_version>
#     <po_version_url></po_version_url>
#     <is_new>t</is_new>
#     <release_date>2005-04-18</release_date>
#     <cvs_action>Checkout</cvs_action>
#     <cvs_server>cvs.project-open.net</cvs_server>
#     <cvs_user>anonymous</cvs_user>
#     <cvs_password></cvs_password>
#     <cvs_root>/home/cvsroot</cvs_root>
#     <cvs_command>checkout intranet-wiki</cvs_command>
#     <update_urgency format="text/plain">New Package</update_urgency>
#     <forum_url>http://sourceforge.net/forum/forum.php?thread_id=1240473&forum_id=295937</forum_url>
#     <forum_title>New Wiki Module</forum_title>
#     <whats_new>
#       See package description. Please also install the "wiki" module (below).
#     </whats_new>
#   </update>
# </update_list>

set tree [xml_parse -persist $update_xml]
set root_node [xml_doc_get_first_node $tree]
set root_name [xml_node_get_name $root_node]
if { ![string equal $root_name "po_software_update"] } {
    ad_return_complaint 1 "Expected <po_software_update> as root node of update.xml file, found: '$root_name'"
}

set ctr 0
set debug ""
set root_nodes [xml_node_get_children $root_node]

# ad_return_complaint 1 "<pre>$update_xml</pre>"

# login_status = "ok" or "fail"
set login_status [[$root_node selectNodes {//login_status}] text]
set login_message [[$root_node selectNodes {//login_message}] text]

# May be new or old protocol - accept the error and use defaults
set cvs_user ""
set cvs_password ""
catch {
    set cvs_user [[$root_node selectNodes {/po_software_update/login/cvs_user}] text]
    set cvs_password [[$root_node selectNodes {/po_software_update/login/cvs_password}] text]
} err_msg
if {"" == $cvs_user} { set cvs_user "anonymous" }

set version_html ""

foreach root_node $root_nodes {

    set root_node_name [xml_node_get_name $root_node]
    ns_log Notice "load-update-xml-2: node_name=$root_node_name"

    switch $root_node_name {

	# Information about the successfull/unsuccessful login 
	# process
	login {
	    # Ignore. Info is extracted via XPath above
	}

	# Information about the customers account, such as an expriation,
	# payment information etc.
	account {
	    # not used yet
	}

	update_list {

	    set version_list [list]
	    set version_nodes [xml_node_get_children $root_node]

	    foreach version_node $version_nodes {

		set version_node_name [xml_node_get_name $version_node]

		if { [string equal $version_node_name "update"] } {

		    set package_name [apm_tag_value -default "" $version_node package_name]
		    set package_url [apm_tag_value -default "" $version_node package_url]
		    set package_version [apm_tag_value -default "" $version_node package_version]

		    set po_version [apm_tag_value $version_node po_version]
		    set po_version_url [apm_tag_value $version_node po_version_url]
		    
		    set is_new [apm_tag_value -default "" $version_node is_new]

		    set release_date [apm_tag_value -default "" $version_node release_date]
		    set whats_new [apm_tag_value -default "" $version_node whats_new]
		    set cvs_action [apm_tag_value -default "" $version_node cvs_action]
		    set cvs_server [apm_tag_value -default "" $version_node cvs_server]
		    set cvs_root [apm_tag_value -default "" $version_node cvs_root]
		    set cvs_command [apm_tag_value -default "" $version_node cvs_command]
		    set update_urgency [apm_tag_value -default "" $version_node update_urgency]
		    set forum_url [apm_tag_value -default "" $version_node forum_url]
		    set forum_title [apm_tag_value -default "" $version_node forum_title]
		    set update_url [export_vars -base cvs-update {cvs_server cvs_user cvs_password cvs_command cvs_root}]
		    
		    set package_formatted $package_name
		    if {"" != $package_url} {set package_formatted "<a href=\"$package_url\">$package_name</a>" }
		    
		    set po_version_formatted $po_version
		    if {"" != $po_version_url} {set po_version_formatted "<a href=\"$po_version_url\">$po_version</a>" }
		    
		    # Skip this item if it's not "new"
		    if {$show_only_new_p} {
			if {![string equal $is_new "t"]} { continue }
		    }

#		    set higher_version_p [apm_higher_version_installed_p "intranet-core" $package_version]
#		    ns_log Notice "load-update-xml-2: higher: $higher_version_p, v=$package_version"
		    
		    append version_html "
<tr $bgcolor([expr $ctr % 2])>
  <td><a href=\"$update_url\" title=\"Update\" class=\"button\">Update</a>&nbsp;</td>
  <td>$package_formatted</td>
  <td>$package_version</td>
  <td>$po_version_formatted</td>
  <td>$release_date</td>
  <td><a href=\"$forum_url\">$forum_title</a></td>
  <td>$update_urgency</td>
  <td>$whats_new</td>
</tr>
"

		    incr ctr
		}
	    }
	}

	default {
	    ns_log Notice "load-update-xml-2.tcl: ignoring root node '$root_node_name'"
	}
    }
}


xml_doc_free $tree


# ------------------------------------------------------------
# Show the list of currently installed packages
#

set dimensional_list {
    {
        supertype "Package Type:" all {
	    { apm_application "Applications" { where "[db_map apm_application]" } }
	    { apm_service "Services" { where "t.package_type = 'apm_service'"} }
	    { all "All" {} }
	}
    }
    {

	owned_by "Owned by:" everyone {
	    { me "Me" {where "[db_map everyone]"} }
	    { everyone "Everyone" {where "1 = 1"} }
	}
    }
    {
	status "Status:" latest {
	    {
		latest "Latest" {where "[db_map latest]" }
	    }
	    { all "All" {where "1 = 1"} }
	}
    }
}

set missing_text "<strong>No packages match criteria.</strong>"

# append body "<center><table><tr><td>[ad_dimensional $dimensional_list]</td></tr></table></center>"

set use_watches_p [expr ! [ad_parameter -package_id [ad_acs_kernel_id] PerformanceModeP request-processor 1]]

set table_def {
    { package_key "Key" "" "<td><a href=\"[export_vars -base /acs-admin/apm/version-view { version_id }]\">$package_key</a></td>" }
    { pretty_name "Name" "" "<td><a href=\"[export_vars -base /acs-admin/apm/version-view { version_id }]\">$pretty_name</a></td>" }
    { version_name "Ver." "" "" }
    {
	status "Status" "" {<td align=center>&nbsp;&nbsp;[eval {
	    if { $installed_p == "t" } {
		if { $enabled_p == "t" } {
		    set status "Enabled"
		} else {
		    set status "Disabled"
		}
	    } elseif { $superseded_p } {
		set status "Superseded"
	    } else {
		set status "Uninstalled"
	    }
	    format $status
	}]&nbsp;&nbsp;</td>}
    }
}

doc_body_flush

set table [ad_table -Torderby $orderby -Tmissing_text $missing_text "apm_table" "" $table_def]

db_release_unused_handles

# The reload links make the page slow, so make them optional
set page_url "[ad_conn url]?[export_vars -url {orderby owned_by supertype}]"
if { $reload_links_p } {
    set reload_filter "<a href=\"$page_url&reload_links_p=0\">Do not check for changed files</a>"
} else {
    set reload_filter "<a href=\"$page_url&reload_links_p=1\">Check for changed files</a>"
}






































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
