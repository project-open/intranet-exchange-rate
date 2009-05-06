# /packages/intranet-exchange-rate/www/active-currencies-2.tcl
#
# Copyright (C) 2003-2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Demo page to show indicators
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { return_url "/intranet-exchange-rate/index" }
    currency
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-exchange-rate.Manage_Active_Currencies "Manage Active Currencies"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

set form_id "exchange_rates"
set action_url "new"

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# ---------------------------------------------------------------

db_dml update_active_currency "
	update	currency_codes
	set	supported_p = 't'
	where	iso = :currency
"


ad_returnredirect $return_url

