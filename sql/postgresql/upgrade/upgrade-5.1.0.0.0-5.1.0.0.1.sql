-- upgrade-5.1.0.0.0-5.1.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-exchange-rate/sql/postgresql/upgrade/upgrade-5.1.0.0.0-5.1.0.0.1.sql','');


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

