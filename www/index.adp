<master src="../../intranet-core/www/admin/master">
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">admin</property>
<property name="focus">@page_focus;noquote@</property>
<property name="admin_navbar_label">admin_exchange_rates</property>

<!-- <h2>@page_title@</h2> -->

<ul>
<li><a href="get-exchange-rates"><%= [lang::message::lookup "" intranet-exchange-rates.Get_exchange_rates_for_today "Get exchange rates for today"] %>
</ul>

@filter_html;noquote@
@table;noquote@

