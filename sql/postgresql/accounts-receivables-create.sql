-- accounts-receivables-create.sql
--
-- @author Benjamin Birnk
-- @ported from sql-ledger and combined with parts from OpenACS ecommerce package
-- @license GNU GENERAL PUBLIC LICENSE, Version 2, June 1991
--

CREATE SEQUENCE qar_invoiceid;
SELECT nextval ('qar_invoiceid');

-- for invoice_status, invoice_credits see SL AR aging
-- for invoice_summary, see SL AR reports
-- for new_acct_payment,and new_company_info see shopping-basket orders, new customer registration, affiliate, referral_info, domain_name, plan_id,
-- for special fund collections such as server_fund table, create separate sku(s) for easy tracking.

CREATE SEQUENCE qar_orderitemsid;
SELECT nextval ('qar_orderitemsid');
--
CREATE TABLE qar_invoice (
  id integer DEFAULT nextval ( 'qar_invoiceid' ),
  trans_id integer,
  parts_id integer,
  -- one line description
  description varchar(300),
  qty numeric,
  allocated numeric,
  sellprice numeric,
  fxsellprice numeric,
  discount numeric,
  assemblyitem varchar(1) DEFAULT '0',
  unit varchar(5),
  project_id integer,
  -- was deliverydate
  delivery_time timestamptz,
  serialnumber varchar(300)
);

create index qar_invoice_id_idx on qar_invoice (id);
create index qar_invoice_trans_id_idx on qar_invoice (trans_id);


CREATE TABLE qar_ar (
  id integer DEFAULT nextval ( 'qal_id' ),
  invnumber varchar(300),
  -- was transdate
  transtime timestamptz DEFAULT current_timestamp,
  customer_id integer,
  taxincluded varchar(1),
  amount numeric,
  netamount numeric,
  paid numeric,
  -- was datepaid date
  paid_time timestamptz,
  -- was duedate
  due_time timestamptz,
 -- expires when invoice must be renegotiated.
 -- part of company_status
  expire_time timestamptz,
  invoice varchar(1) DEFAULT '0',
  shippingpoint varchar(300),
   -- terms should be a reference for handling pre-defined term list
   -- but for now it refers to days.
  terms integer DEFAULT '0',
  notes text,
  curr char(6),
  ordnumber varchar(300),
  employee_id integer,
  till varchar(20),
  quonumber varchar(300),
  intnotes text,
  department_id integer default '0',
  shipvia varchar(300),
  language_code varchar(6),
  ponumber varchar(300),
  status varchar(1)
  -- aka company_status.description
  -- 1 = paid (deprecated)
  -- 2 = closed/expired
  -- 3 = invoiced/past due/suspended
  -- 4 = invoiced/active
 --see also invoice_status_text.status_text
  -- 1 = unpaid
  -- 2 = paid
  -- 3 = void
  -- 4 = credit memo
  -- 5 = referral credit memo
  -- 6 = pending: server-a-thon
);

create index qar_ar_id_idx on qar_ar (id);
create index qar_ar_transdate_idx on qar_ar (transtime);
create index qar_ar_invnumber_idx on qar_ar (invnumber);
create index qar_ar_ordnumber_idx on qar_ar (ordnumber);
create index qar_ar_customer_id_idx on qar_ar (customer_id);
create index qar_ar_employee_id_idx on qar_ar (employee_id);
create index qar_ar_quonumber_idx on qar_ar (quonumber);


CREATE TABLE qar_oe (
  id integer default nextval('qal_id'),
  ordnumber varchar(300),
  -- was transdate date
  transtime timestamptz default current_timestamp,
  vendor_id integer,
  customer_id integer,
  amount numeric,
  netamount numeric,
  -- was reqdate date
  req_time timestamptz,
  taxincluded varchar(1),
  shippingpoint varchar(300),
  notes text,
  curr char(3),
  employee_id integer,
  closed varchar(1) default '0',
  quotation varchar(1) default '0',
  quonumber varchar(300),
  intnotes text,
  department_id integer default '0',
  shipvia varchar(300),
  language_code varchar(6),
  ponumber varchar(300),
  terms integer DEFAULT '0'
);

create index qar_oe_id_idx on qar_oe (id);
create index qar_oe_transdate_idx on qar_oe (transtime);
create index qar_oe_ordnumber_idx on qar_oe (ordnumber);
create index qar_oe_employee_id_idx on qar_oe (employee_id);

-- CREATE TRIGGER qci_check_inventory AFTER UPDATE ON qar_oe FOR EACH ROW EXECUTE PROCEDURE qci_check_inventory();
-- moving this trigger to the application level (tcl)

--
CREATE TABLE qar_orderitems (
  trans_id integer,
  parts_id integer,
  description varchar(300),
  qty numeric,
  sellprice numeric,
  discount numeric,
  unit varchar(50),
  project_id integer,
  -- was reqdate date,
  req_time timestamptz,
  ship numeric,
  serialnumber varchar(300),
  id integer default nextval('qar_orderitemsid')
);

create index qar_orderitems_trans_id_idx on qar_orderitems (trans_id);
create index qar_orderitems_id_idx on qar_orderitems (id);

-- part of company_dates
CREATE TABLE qar_recurring (
  id integer,
  reference varchar(300),
  -- was startdate date
  start_time timestamptz,
  -- was nextdate date,
  next_time timestamptz,
  -- was enddate date,
  end_time timestamptz,
  repeat integer,
  unit varchar(6),
  howmany integer,
  payment varchar(1) default '0'
);

CREATE TABLE qar_recurringemail (
  id integer,
  formname varchar(300),
  format varchar(300),
  message text
);
--
CREATE TABLE qar_recurringprint (
  id integer,
  formname varchar(300),
  format varchar(300),
  printer text
);




   
   create table qar_ec_creditcards (
           creditcard_id           integer not null,
	   -- references users
           user_id                 integer not null, 
           -- Some credit card gateways do not ask for this but we'll store it anyway
           creditcard_type         char(1),
           -- no spaces; always 16 digits (oops; except for AMEX, which is 15)
           -- depending on admin settings, after we get success from the credit card gateway, 
           -- we may bash this to NULL
	   -- see http://en.wikipedia.org/wiki/Bank_card_number
           creditcard_number       varchar(16),
           -- just the last four digits for subsequent UI
           creditcard_last_four    char(4),
           -- ##/## 
           creditcard_expire       char(5),

--      this used to reference ec_addresses, but now needs to reference contacts..
--   	billing_address 	integer references qal_ec_addresses(address_id),
         billing_address         integer,

           -- if it ever failed (conclusively), set this to '1' so we
           -- won't give them the option of using it again
           failed_p                boolean default '0'
   );
   
   create index qar_ec_creditcards_by_user_idx on qar_ec_creditcards (user_id);



