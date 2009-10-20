# /packages/intranet-exchange-rate/www/index.tcl
#
# Copyright (C) 2003-2008 ]project-open[
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
    { form_mode "edit" }
    { return_url "" }
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-exchange-rate.Manage_Active_Currencies "Manage Active Currencies"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

set form_id "exchange_rates"
set action_url "new"

if {"" == $return_url} { set return_url "/intranet-exchange-rate/active-currencies" }

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}


# ------------------------------------------------------------------
# Currency List
# ------------------------------------------------------------------

list::create \
    -name active_currencies \
    -multirow active_currencies \
    -key iso \
    -row_pretty_plural "Object Types" \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions {  } \
    -bulk_actions { Delete deactivate-currencies "Mark currency as inactive" } \
    -elements {
        iso {
            label "ISO"
            display_col iso
        }        
        currency_name {
            label "Name"
            display_col currency_name
        }
    }

db_multirow active_currencies select_active_currencies {
	select	*
	from	currency_codes
	where	supported_p = 't'
	order by lower(currency_name)
}

