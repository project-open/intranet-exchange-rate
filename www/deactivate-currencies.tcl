# /packages/intranet-exchange-rate/www/deactivate-currencies.tcl
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
    { iso:multiple {} }
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-exchange-rate.Deactivate "Deactivate"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# ---------------------------------------------------------------

foreach currency $iso {
    db_dml update_active_currency "
	update	currency_codes
	set	supported_p = 'f'
	where	iso = :currency
    "
}

ad_returnredirect $return_url

