<master>
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">admin</property>
<property name="focus">@page_focus;noquote@</property>
<property name="admin_navbar_label">admin_exchange_rates</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<table width="100%" border=0>
<tr valign=top>
<td colspan=2>
	<%= [im_component_bay top] %>
</td>
</tr>
<tr valign=top>
<td>
	<%= [im_component_bay left] %>
	@table;noquote@
</td>
<td>
	<%= [im_component_bay right] %>

</td>
</tr>
<tr valign=top>
<td colspan=2>
	<%= [im_component_bay bottom] %>
</td>
</tr>
</table>

