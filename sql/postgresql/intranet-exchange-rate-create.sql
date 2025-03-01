-- /packages/intranet-exchange-rate/sql/postgresql/intranet-exchange-rate-create.sql
--
-- ]project-open[ Exchange Rate Module
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- https://www.project-open.com/license/ for details.
-- @author frank.bergmann@project-open.com

----------------------------------------------------
-- Exchange rates of currencies with respect to the US dollar

create table im_exchange_rates (
	day			date
				constraint im_exchange_rates_nn
				not null,
	currency		char(3)
				constraint im_exchange_rates_currency_fk
				references currency_codes,
	rate			numeric(12,6),
	manual_p		char(1)
				constraint im_exchange_rates_manual_ck
				check (manual_p in ('t','f')),
        constraint im_exchange_rates_pk
        primary key (day,currency)
);

-- load data from 1999-01-01 until 2005-06-30
\i intranet-exchange-rate-data.sql



-- Fill "holes" (=missing exchange rate entries)
-- with the values from the last manually entered
-- rates. This procedure is "idempotent", so it
-- can be executed at any time.
create or replace function im_exchange_rate_fill_holes (varchar, date, date)
returns integer as $body$
DECLARE
    p_currency			alias for $1;
    p_start_date		alias for $2;
    p_end_date			alias for $3;

    v_rate			numeric;
    row2			RECORD;
    v_exists_p			integer;
    v_manual_p			boolean;
BEGIN
    RAISE NOTICE 'im_exchange_rate_fill_holes: cur=%, start=%, end=%', p_currency, p_start_date, p_end_date;

    -- Loop through all dates and check if there
    -- is a hole (no entry for a date)
    FOR row2 IN
	select  im_day_enumerator as day
	from    im_day_enumerator(p_start_date, p_end_date)
		LEFT OUTER JOIN (
			select  *
			from    im_exchange_rates
			where   currency = p_currency
		) ex on (im_day_enumerator = ex.day)
	where   1=1 -- ex.rate is null
    LOOP
	-- RAISE NOTICE 'im_exchange_rate_fill_holes: cur=%, day=%', p_currency, row2.day;

	-- get the latest manually entered exchange rate
	select  rate into v_rate
	from    im_exchange_rates
	where   day = (
			select  max(day)
			from    im_exchange_rates
			where   day < row2.day
				and currency = p_currency
				and manual_p = 't'
		      )
		and currency = p_currency;

	-- RAISE NOTICE 'im_exchange_rate_fill_holes: rate=%', v_rate;
	-- use the latest exchange rate for the next few years...
	select  1, manual_p into v_exists_p, v_manual_p
	from im_exchange_rates
	where day = row2.day and currency = p_currency;

	IF (v_manual_p) THEN continue; END IF;		  -- never overwrite manually entered values

	IF v_exists_p > 0 THEN
		update im_exchange_rates
		set     rate = v_rate,
			manual_p = 'f'
		where   day = row2.day
			and currency = p_currency;
	ELSE
		RAISE NOTICE 'im_exchange_rate_fill_holes: day=%, cur=%, rate=%, x=%',row2.day, p_currency, v_rate, v_exists_p;
		insert into im_exchange_rates (
			day, rate, currency, manual_p
		) values (
			row2.day, v_rate, p_currency, 'f'
		);
	END IF;
    END LOOP;

    return 0;
end;$body$ language 'plpgsql';




-- Compatibility version of fill_holes:
-- Fills holes for 2013 - 2020.
create or replace function im_exchange_rate_fill_holes (varchar)
returns integer as $body$
DECLARE
    p_currency			alias for $1;
    v_max			integer;
    v_start_date		date;
    v_end_date			date;
BEGIN
    RAISE NOTICE 'im_exchange_rate_fill_holes: cur=%', p_currency;

    v_max := 365 * 7;
    v_start_date := to_date('2018-01-01', 'YYYY-MM-DD');
    v_end_date = v_start_date + v_max;

    RETURN im_exchange_rate_fill_holes (p_currency, v_start_date, v_end_date);

end;$body$ language 'plpgsql';



-- Most generic variant of fill_holes:
-- Fill for all currencies in the last 5 years
create or replace function im_exchange_rate_fill_holes ()
returns integer as $body$
DECLARE
    row			RECORD;
BEGIN
    FOR row IN
    	select	iso
	from	currency_codes
	where	supported_p = 't'
    LOOP
	perform im_exchange_rate_fill_holes(row.iso);
    END LOOP;

    return 0;
end;$body$ language 'plpgsql';




-- Deletes all entries around a new entry.
-- This function is useful after adding a new entriy
-- to delete all those entries that need to be updated.
create or replace function im_exchange_rate_invalidate_entries (date, char(3))
returns integer as $body$
DECLARE
    p_currency_date			alias for $1;
    p_currency			alias for $2;

    v_prev_entry_date		date;
    v_next_entry_date		date;
    v_max			integer;
    v_start_date		date;
BEGIN
    v_start_date := to_date('2010-01-01', 'YYYY-MM-DD');
    v_max := 365 * 7;

    -- Determine the last manual entry BEFORE the insert date
    select	max(day) into v_prev_entry_date
    from	im_exchange_rates
    where	day < p_currency_date and manual_p = 't' and currency = p_currency;
    IF v_prev_entry_date is NULL THEN v_prev_entry_date := v_start_date;  END IF;

    -- Determine the next manual manual entry AFTER the insert date
    select	min(day) into v_next_entry_date
    from	im_exchange_rates
    where	day > p_currency_date and manual_p = 't' and currency = p_currency;
    IF v_next_entry_date is NULL THEN v_next_entry_date := v_start_date + v_max; END IF;

    -- Delete entries between last and next
    delete from im_exchange_rates
    where	currency = p_currency and
		day <= v_next_entry_date and
		day >= v_prev_entry_date
		and manual_p = 'f';

    return 0;
end;$body$ language 'plpgsql';
-- select im_exchange_rate_invalidate_entries ('2005-07-02'::date, 'EUR');

-- Delete all automatically created entries in the relevant period.
create or replace function im_exchange_rate_invalidate_entries(char(3))
returns integer as $body$
DECLARE
    p_currency			alias for $1;
    v_max			integer;
    v_start_date		date;
    v_end_date			date;
BEGIN
    RAISE NOTICE 'im_exchange_rate_invalidate_entries: cur=%', p_currency;

    -- Delete entries since 2010.
    delete from im_exchange_rates
    where	currency = p_currency and
		day >= '2010-01-01'::date
		and manual_p = 'f';
    return 0;
end;$body$ language 'plpgsql';


-- Most generic variant of fill_holes:
-- Fill for all currencies in the last 5 years
create or replace function im_exchange_rate_invalidate_entries ()
returns integer as $body$
DECLARE
    row			RECORD;
BEGIN
    FOR row IN
    	select	iso
	from	currency_codes
	where	supported_p = 't'
    LOOP
	PERFORM im_exchange_rate_invalidate_entries(row.iso);
    END LOOP;

    return 0;
end;$body$ language 'plpgsql';




------------------------------------------------------------
-- Access Functions
------------------------------------------------------------

-- shortcut function to calculate the exchange rate for a
-- specific day. This function is relatively slow and should 
-- NOT be used within a SQL query loop. 
-- Instead, it is useful as a shortcut to convert a single
-- currency item.
--
create or replace function im_exchange_rate (date, char(3), char(3))
returns float as '
DECLARE
    p_day		alias for $1;
    p_from_cur		alias for $2;
    p_to_cur		alias for $3;

    v_from_rate		float;
    v_to_rate		float;
BEGIN
    -- Exchange rate of From-Currency to Dollar
    select	rate
    into	v_from_rate
    from	im_exchange_rates
    where	currency = p_from_cur
		and day = p_day;

    -- Exchange rate of Dollar to To-Currency
    select	rate
    into	v_to_rate
    from	im_exchange_rates
    where	currency = p_to_cur
		and day = p_day;

    return v_from_rate / v_to_rate;
end;' language 'plpgsql';

-- select im_exchange_rate(to_date('2005-07-01','YYYY-MM-DD'), 'EUR', 'USD');



------------------------------------------------------------
-- Portlets and Menus
------------------------------------------------------------

-- select im_component_plugin__del_module('intranet-exchange-rate');
-- select im_menu__del_module('intranet-exchange-rate');


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu		integer;
	v_admin_menu	integer;

	-- Groups
	v_accounting	integer;
	v_senman	integer;
	v_admins	integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''admin'';

    v_menu := im_menu__new (
	null,			-- p_menu_id
	''im_menu'',		-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	''intranet-exchange-rate'',  -- package_name
	''admin_exchange_rates'',    -- label
	''Exchange Rates'',	-- name
	''/intranet-exchange-rate/index'',   -- url
	80,			-- sort_order
	v_admin_menu,		-- parent_menu_id
	null			-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu		integer;
	v_finance_menu	integer;

	-- Groups
	v_accounting	integer;
	v_senman	integer;
	v_admins	integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';

    select menu_id
    into v_finance_menu
    from im_menus
    where label=''finance'';

    v_menu := im_menu__new (
	null,			-- p_menu_id
	''im_menu'',		-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	''intranet-exchange-rate'',  -- package_name
	''finance_exchange_rates'',    -- label
	''Exchange Rates'',	-- name
	''/intranet-exchange-rate/index'',   -- url
	80,			-- sort_order
	v_finance_menu,		-- parent_menu_id
	null			-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


