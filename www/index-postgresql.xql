<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="exchange_rates">
    <querytext>

	select
		days.day as day
		$rate_select
	from
		(select distinct day from im_exchange_rates) days
		$rate_from
	where
                to_char(days.day, 'YYYY') = :year and
                days.day <= now()
	order by
		days.day DESC
    </querytext>
</partialquery>
 

</queryset>
