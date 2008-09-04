<master src="../../intranet-core/www/admin/master">
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">admin</property>
<property name="focus">@page_focus;noquote@</property>
<property name="admin_navbar_label">admin_exchange_rates</property>

<!-- <h2>@page_title@</h2> -->

<table>
<tr class=rowtitle><td class=rowtitle><%= [lang::message::lookup "" intranet-exchange-rate.Admin_Links "Admin Links"] %></td></tr>
<tr>
<td>

	<ul>
	<li><a href="get-exchange-rates"><%= [lang::message::lookup "" intranet-exchange-rate.Get_exchange_rates_for_today "Get exchange rates for today from <br>%currency_url%"] %></a><br></li>
	<li><a href="active-currencies"><%= [lang::message::lookup "" intranet-exchange-rate.Active_currencies "Manage Active Currencies"] %></a><br></li>
	</ul>
</td>
</tr>
</table>

<p>&nbsp;</p>

@filter_html;noquote@
@table;noquote@

