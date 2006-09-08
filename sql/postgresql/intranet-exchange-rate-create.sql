-- /packages/intranet-exchange-rate/sql/postgresql/intranet-exchange-rate-create.sql
--
-- ]project[ Exchange Rate Module
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
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

-- Populate im_exchange_rates for the next 5 years
create or replace function inline_0 ()
returns integer as '
DECLARE
    v_max			integer;
    v_i				integer;
    v_first_block_of_month      integer;
    v_rate			numeric;
    row				RECORD;
BEGIN
    v_max := 365 * 5;
    FOR row IN
        select	iso as currency
	from	currency_codes
	where	supported_p = ''t''
    LOOP
	-- get the latest manually entered exchange rate
	select	rate
	into	v_rate
	from	im_exchange_rates 
	where	day = (
			select max(day) 
			from im_exchange_rates 
			where currency = row.currency
		)
		and manual_p = ''t''
		and currency = row.currency;

	-- use the latest exchange rate for the next few years...
	FOR v_i IN 0..v_max-1 LOOP
	
		insert into im_exchange_rates (
			day, rate, currency, manual_p
		) values (
			to_date(''2005-07-01'',''YYYY-MM-DD'') + v_i,
			v_rate, row.currency, ''f''		
		);

	END LOOP;
    END LOOP;
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


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


select im_component_plugin__del_module('intranet-exchange-rate');
select im_menu__del_module('intranet-exchange-rate');


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
	''acs_object'',		-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	''intranet-exchange-rate'',  -- package_name
	''admin_exchange_rates'',    -- label
	''Exchange Rates'',	-- name
	''/intranet-exchange-rate/'',   -- url
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
	''acs_object'',		-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	''intranet-exchange-rate'',  -- package_name
	''finance_exchange_rates'',    -- label
	''Exchange Rates'',	-- name
	''/intranet-exchange-rate/'',   -- url
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


