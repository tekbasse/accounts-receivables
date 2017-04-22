-- accounts-receivables-drop.sql
--
-- @author Benjamin Birnk
-- @ported from sql-ledger and combined with parts from OpenACS ecommerce package
-- @license GNU GENERAL PUBLIC LICENSE, Version 2, June 1991
--

drop index qar_ec_creditcards_by_user_idx;

drop table qar_ec_creditcards;

drop table qar_recurringprint;

drop table qar_recurringemail;

drop table qar_recurring;


drop index qar_orderitems_id_idx;
drop index qar_orderitems_trans_id_idx;

drop table qar_orderitems;

drop index qar_oe_employee_id_idx;
drop index qar_oe_ordnumber_idx;
drop index qar_oe_transdate_idx;
drop index qar_oe_id_idx;

drop table qar_oe;


drop index qar_ar_quonumber_idx;
drop index qar_ar_employee_id_idx;
drop index qar_ar_customer_id_idx;
drop index qar_ar_ordnumber_idx;
drop index qar_ar_invnumber_idx;
drop index qar_ar_transdate_idx;
drop index qar_ar_id_idx;

drop table qar_ar;


drop index qar_invoice_trans_id_idx;
drop index qar_invoice_id_idx;

drop table qar_invoice;


drop sequence qar_orderitemsid;


drop sequence qar_invoiceid;

drop sequence qar_id;
