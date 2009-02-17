-- /packages/intranet-hr/sql/oracle/intranet-hr-drop.sql
--
-- ]project[ Exchange Rate Module
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
-- @author frank.bergmann@project-open.com


drop function im_exchange_rate (date, char(3), char(3));
drop table im_exchange_rates;

select im_component_plugin__del_module('intranet-exchange-rate');
select im_menu__del_module('intranet-exchange-rate');

