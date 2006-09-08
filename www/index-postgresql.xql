<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="exchange_rates">
    <querytext>

	select
		days.day as day,
		:return_url as return_url
		$rate_select
	from
		(select distinct day from im_exchange_rates) days
		$rate_from
	where
		1=1
		[ad_dimensional_sql $dimensional_list where and]
	order by
		days.day DESC


    </querytext>
</partialquery>
 

</queryset>
