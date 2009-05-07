<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="main_navbar_label">home</property>
<property name="focus">@page_focus;noquote@</property>
<property name="admin_navbar_label">admin_exchange_rates</property>

<h2>@page_title@</h2>

<table width="70%" cellspacing=2 cellpadding=2>
<tr valign=top>
<td>
<listtemplate name="active_currencies"></listtemplate>
</td>
<td>&nbsp;&nbsp;</td>
<td>

	<table>
	<tr class=rowtitle>
	<td class=rowtitle><%= [lang::message::lookup "" intranet-exchange-rate.Add_Currencies "Add Currencies"] %></td>
	</tr>
	<tr>
	<td>
		<form action="/intranet-exchange-rate/active-currencies-2" method=GET>
		<%= [export_form_vars return_url] %>
		<%= [im_currency_select -enabled_only_p 0 -currency_name "iso || ' - ' || currency_name" currency] %><br>
		<input type=submit value="<%= [lang::message::lookup "" intranet-exchange-rate.Add_Active_Currency "Add Active Currency"] %>">
		</form>
	</td>
	</tr>
	</table>

</td>
</tr>
</table>

<!-- 
<p>&nbsp;</p>
<h2><%= [lang::message::lookup "" intranet-exchange-rate.Immutable_Currencies "Immutable Currencies"] %></h2>

<table class="list" cellpadding="3" cellspacing="1" summary="Data for active_currencies"> 
    <thead>
      <tr class="list-header">      
        <th class="list-narrow" align="center">&nbsp;&nbsp;&nbsp;&nbsp;</th>
        <th class="list-narrow" id="active_currencies_iso">ISO</th>
        <th class="list-narrow" id="active_currencies_currency_name">Name</th>
      </tr>
   </thead>
  <tbody>
    <tr class="odd">
              <td class="list-narrow" align="center" headers="active_currencies_checkbox">
              </td>
              <td class="list-narrow" headers="active_currencies_iso">USD</td>
              <td class="list-narrow" headers="active_currencies_currency_name">US Dollar</td>
          </tr>      
</tbody>
</table>
-->


<p>&nbsp;</p>
<p>
The 'US Dollar' currency is required and can't be modified.<br>
The value of the US Dollar should always be '1.0', because it
is the reference currency.
</p>

