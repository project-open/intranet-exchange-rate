<master>
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">admin</property>
<property name="focus">@page_focus;noquote@</property>
<property name="admin_navbar_label">admin_exchange_rates</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<table width="100%" border=0>
<tr valign=top>
<td>
@table;noquote@
</td>
<td>
	<%= [im_box_header [lang::message::lookup "" intranet-exchange-rate.Update_Exchange_Rates "Update Exchange Rates"]] %>

	<%= [lang::message::lookup "" intranet-exchange-rate.Exchange_ASUS_Disclaimer "
		<p>
		This service allows you to automatically update your
		exchange rates from our exchange rate server.<br>
		By using this service you accept that we provide this 
		service 'as is' and don't accept any liability for 
		incorrect data and any consequences of using them.
		</p>
	"] %>
	
	<form action="">
	<input type=submit value="<%= [lang::message::lookup "" intranet-exchange-rate.Button_Get_Exchange_Rates "Get Exchange Rates"] %>"
	</form>
	
	<%= [im_box_footer] %>

</td>
</tr>
</table>


