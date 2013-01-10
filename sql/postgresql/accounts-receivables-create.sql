-- accounts-receivables-create.sql
--
-- @author Dekka Corp.
-- @ported from sql-ledger and combined with parts from OpenACS ecommerce package
-- @license GNU GENERAL PUBLIC LICENSE, Version 2, June 1991
-- @cvs-id
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
  description text,
  qty numeric,
  allocated numeric,
  sellprice numeric,
  fxsellprice numeric,
  discount numeric,
  assemblyitem varchar(1) DEFAULT 'f',
  unit varchar(5),
  project_id integer,
  deliverydate date,
  serialnumber text
);

CREATE TABLE qar_ar (
  id int DEFAULT nextval ( 'qal_id' ),
  invnumber text,
  transdate date DEFAULT current_date,
  customer_id integer,
  taxincluded varchar(1),
  amount numeric,
  netamount numeric,
  paid numeric,
  datepaid date,
  duedate date,
 -- expires when invoice must be renegotiated.
 -- part of company_status
  expire_date date,
  invoice varchar(1) DEFAULT 'f',
  shippingpoint text,
  terms integer DEFAULT 0,
  notes text,
  curr char(3),
  ordnumber text,
  employee_id integer,
  till varchar(20),
  quonumber text,
  intnotes text,
  department_id int default 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  status varchar(1),
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


--
CREATE TABLE qar_oe (
  id int default nextval('qal_id'),
  ordnumber text,
  transdate date default current_date,
  vendor_id integer,
  customer_id integer,
  amount numeric,
  netamount numeric,
  reqdate date,
  taxincluded varchar(1),
  shippingpoint text,
  notes text,
  curr char(3),
  employee_id integer,
  closed varchar(1) default 'f',
  quotation varchar(1) default 'f',
  quonumber text,
  intnotes text,
  department_id int default 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  terms int2 DEFAULT 0
);

CREATE TRIGGER qci_check_inventory AFTER UPDATE ON qar_oe FOR EACH ROW EXECUTE PROCEDURE qci_check_inventory();

--
CREATE TABLE qar_orderitems (
  trans_id integer,
  parts_id integer,
  description text,
  qty numeric,
  sellprice numeric,
  discount numeric,
  unit varchar(5),
  project_id integer,
  reqdate date,
  ship numeric,
  serialnumber text,
  id int default nextval('qar_orderitemsid')
);

-- part of company_dates
CREATE TABLE qar_recurring (
  id integer,
  reference text,
  startdate date,
  nextdate date,
  enddate date,
  repeat int2,
  unit varchar(6),
  howmany integer,
  payment varchar(1) default 'f'
);

CREATE TABLE qar_recurringemail (
  id integer,
  formname text,
  format text,
  message text
);
--
CREATE TABLE qar_recurringprint (
  id integer,
  formname text,
  format text,
  printer text
);


--
create index qar_ar_id_key on qar_ar (id);
create index qar_ar_transdate_key on qar_ar (transdate);
create index qar_ar_invnumber_key on qar_ar (invnumber);
create index qar_ar_ordnumber_key on qar_ar (ordnumber);
create index qar_ar_customer_id_key on qar_ar (customer_id);
create index qar_ar_employee_id_key on qar_ar (employee_id);
create index qar_ar_quonumber_key on qar_ar (quonumber);

--
create index qar_invoice_id_key on qar_invoice (id);
create index qar_invoice_trans_id_key on qar_invoice (trans_id);
--
create index qar_oe_id_key on qar_oe (id);
create index qar_oe_transdate_key on qar_oe (transdate);
create index qar_oe_ordnumber_key on qar_oe (ordnumber);
create index qar_oe_employee_id_key on qar_oe (employee_id);
create index qar_orderitems_trans_id_key on qar_orderitems (trans_id);
create index qar_orderitems_id_key on qar_orderitems (id);
--
CREATE FUNCTION qar_del_recurring() returns opaque as '
BEGIN
  DELETE FROM qar_recurring WHERE id = old.id;
  DELETE FROM qar_recurringemail WHERE id = old.id;
  DELETE FROM qar_recurringprint WHERE id = old.id;
  RETURN NULL;
END;
' language 'plpgsql';
--end function
CREATE TRIGGER qar_del_recurring AFTER DELETE ON qar_ar FOR EACH ROW EXECUTE PROCEDURE qar_del_recurring();
-- end trigger

CREATE TRIGGER qar_del_recurring AFTER DELETE ON qal_gl FOR EACH ROW EXECUTE PROCEDURE qar_del_recurring();
-- end trigger

-- accounts-ledger maintenance

CREATE TRIGGER qar_del_department AFTER DELETE ON qar_ar FOR EACH ROW EXECUTE PROCEDURE qal_del_department();
-- end trigger
CREATE TRIGGER qar_del_department AFTER DELETE ON qar_oe FOR EACH ROW EXECUTE PROCEDURE qal_del_department();
-- end trigger


CREATE TRIGGER qar_del_exchangerate BEFORE DELETE ON qar_ar FOR EACH ROW EXECUTE PROCEDURE qal_del_exchangerate();
-- end trigger
--
--
CREATE TRIGGER qar_del_exchangerate BEFORE DELETE ON qar_oe FOR EACH ROW EXECUTE PROCEDURE qal_del_exchangerate();
-- end trigger

CREATE TRIGGER qar_check_department AFTER INSERT OR UPDATE ON qar_ar FOR EACH ROW EXECUTE PROCEDURE qal_check_department();
-- end trigger
CREATE TRIGGER qar_check_department AFTER INSERT OR UPDATE ON qar_oe FOR EACH ROW EXECUTE PROCEDURE qal_check_department();
-- end trigger


-- following from ecommerce package

   create table qar_ec_user_session_offer_codes (
           user_session_id         integer not null references qal_ec_user_sessions,
           product_id              integer not null references qci_ec_products,
           offer_code              varchar(20) not null,
           primary key (user_session_id, product_id)
   );
   
   -- create some indices
   create index qar_ec_u_s_offer_codes_by_u_s_id on qar_ec_user_session_offer_codes(user_session_id);
   create index qar_ec_u_s_offer_codes_by_p_id on qar_ec_user_session_offer_codes(product_id);
   
   create sequence qar_ec_order_id_seq start 3000000;
   create view qar_ec_order_id_sequence as select nextval('qar_ec_order_id_seq') as nextval;
   

 
   create sequence qar_ec_creditcard_id_seq start 1;
   create view qar_ec_creditcard_id_sequence as select nextval('qar_ec_creditcard_id_seq') as nextval;
   
   create table qar_ec_creditcards (
           creditcard_id           integer not null primary key,
           user_id                 integer not null references users,
           -- Some credit card gateways do not ask for this but we'll store it anyway
           creditcard_type         char(1),
           -- no spaces; always 16 digits (oops; except for AMEX, which is 15)
           -- depending on admin settings, after we get success from the credit card gateway, 
           -- we may bash this to NULL
           creditcard_number       varchar(16),
           -- just the last four digits for subsequent UI
           creditcard_last_four    char(4),
           -- ##/## 
           creditcard_expire       char(5),

--      this used to reference ec_addresses, but now needs to reference contacts..
--   	billing_address 	integer references qal_ec_addresses(address_id),
         billing_address         integer,

           -- if it ever failed (conclusively), set this to 't' so we
           -- won't give them the option of using it again
           failed_p                boolean default 'f'
   );
   
   create index qar_ec_creditcards_by_user_idx on qar_ec_creditcards (user_id);




   -- Gift certificate stuff ----
   ------------------------------
   
   create sequence qar_ec_gift_cert_id_seq start 1000000;
   create view qar_ec_gift_cert_id_sequence as select nextval('qar_ec_gift_cert_id_seq') as nextval;
   
   create table qar_ec_gift_certificates (
           gift_certificate_id     integer primary key,
           gift_certificate_state  varchar(50) not null,
           amount                  numeric not null,
           -- a trigger will update this to f if the
           -- entire amount is used up (to speed up
           -- queries)
           amount_remaining_p      boolean default 't',
           issue_date              timestamptz,
           authorized_date         timestamptz,
           claimed_date            timestamptz,
           -- customer service rep who issued it
           issued_by               integer references users,
           -- customer who purchased it
           purchased_by            integer references users,
           expires                 timestamptz,
           user_id                 integer references users,
           -- if it's unclaimed, claim_check will be filled in,
           -- and user_id won't be filled in
           -- claim check should be unique (one way to do this
           -- is to always begin it with "$gift_certificate_id-")
           claim_check             varchar(50),
           certificate_message     varchar(200),
           certificate_to          varchar(100),
           certificate_from        varchar(100),
           recipient_email         varchar(100),
           voided_date             timestamptz,
           voided_by               integer references users,
           reason_for_void         varchar(4000),
           last_modified           timestamptz not null,
           last_modifying_user     integer not null references users,
           modified_ip_address     varchar(20) not null,
           check (user_id is not null or claim_check is not null)
   );
   
   create index qar_ec_gc_by_state on qar_ec_gift_certificates(gift_certificate_state);
   create index qar_ec_gc_by_amount_remaining on qar_ec_gift_certificates(amount_remaining_p);
   create index qar_ec_gc_by_user on qar_ec_gift_certificates(user_id);
   create index qar_ec_gc_by_claim_check on qar_ec_gift_certificates(claim_check);
   
   -- note: there's a trigger in ecommerce-plsql.sql which updates amount_remaining_p
   -- when a gift certificate is used
   
   -- note2: there's a 1-1 correspondence between user-purchased gift certificates
   -- and financial transactions.  qar_ec_financial_transactions stores the corresponding
   -- gift_certificate_id.
   
   create view qar_ec_gift_certificates_approved
   as 
   select * 
   from qar_ec_gift_certificates
   where gift_certificate_state in ('authorized');
   
   create view qar_ec_gift_certificates_purchased
   as
   select *
   from qar_ec_gift_certificates
   where gift_certificate_state in ('authorized');
   
   create view qar_ec_gift_certificates_issued
   as
   select *
   from qar_ec_gift_certificates
   where gift_certificate_state in ('authorized')
     and issued_by is not null;
   
   
   create table qar_ec_gift_certificates_audit (
           gift_certificate_id     integer,
           gift_certificate_state  varchar(50),
           amount                  numeric,
           issue_date              timestamptz,
           authorized_date         timestamptz,
           issued_by               integer,
           purchased_by            integer,
           expires                 timestamptz,
           user_id                 integer,
           claim_check             varchar(50),
           certificate_message     varchar(200),
           certificate_to          varchar(100),
           certificate_from        varchar(100),
           recipient_email         varchar(100),
           voided_date             timestamptz,
           voided_by               integer,
           reason_for_void         varchar(4000),
           last_modified           timestamptz,
           last_modifying_user     integer,
           modified_ip_address     varchar(20),
           delete_p                boolean default 'f' 
   );
   
   
   create function qar_ec_gift_certificates_audit_tr ()
   returns opaque as '
   begin
           insert into qar_ec_gift_certificates_audit (
           gift_certificate_id, amount,
           issue_date, authorized_date, issued_by, purchased_by, expires,
           user_id, claim_check, certificate_message,
           certificate_to, certificate_from,
           recipient_email, voided_date, voided_by, reason_for_void,
           last_modified,
           last_modifying_user, modified_ip_address
           ) values (
           old.gift_certificate_id, old.amount,
           old.issue_date, old.authorized_date, old.issued_by, old.purchased_by, old.expires,
           old.user_id, old.claim_check, old.certificate_message,
           old.certificate_to, old.certificate_from,
           old.recipient_email, old.voided_date, old.voided_by, old.reason_for_void,
           old.last_modified,
           old.last_modifying_user, old.modified_ip_address      
           );
   	return new;
   end;' language 'plpgsql';
   
   create trigger qar_ec_gift_certificates_audit_tr
   after update or delete on qar_ec_gift_certificates
   for each row execute procedure qar_ec_gift_certificates_audit_tr ();
   



   create table qar_ec_orders (
           order_id        	integer not null primary key,
           -- can be null, until they've checked out or saved their basket
           user_id			integer  references users,
           user_session_id		integer references qal_ec_user_sessions,
           order_state		varchar(50) default 'in_basket' not null,
           tax_exempt_p            boolean default 'f',
           shipping_method		varchar(20),    -- express or standard or pickup or 'no shipping'

--           used to reference ec_addresses, now needs to reference contacts
--           shipping_address        integer references qal_ec_addresses(address_id),
           shipping_address        integer,
           -- store credit card info in a different table
           creditcard_id		integer references qar_ec_creditcards(creditcard_id),
           -- information recorded upon FSM state changes
           -- we need this to figure out if order is stale
           -- and should be offered up for removal
           in_basket_date          timestamptz,
           confirmed_date          timestamptz,
           authorized_date         timestamptz,
           voided_date             timestamptz,
           expired_date            timestamptz,
           -- base shipping, which is added to the amount charged for each item
           shipping_charged        numeric,
           shipping_refunded       numeric,
           shipping_tax_charged    numeric,
           shipping_tax_refunded   numeric,
           -- entered by customer service
           cs_comments             varchar(4000),
           reason_for_void         varchar(4000),
           voided_by               integer references users,
           -- if the user chooses to save their shopping cart
           saved_p                 boolean
           check (user_id is not null or user_session_id is not null)
   );
   
   create index qar_ec_orders_by_user_idx on qar_ec_orders (user_id);
   create index qar_ec_orders_by_user_sess_idx on qar_ec_orders (user_session_id);
   create index qar_ec_orders_by_credit_idx on qar_ec_orders (creditcard_id);
   create index qar_ec_orders_by_addr_idx on qar_ec_orders (shipping_address);
   create index qar_ec_orders_by_conf_idx on qar_ec_orders (confirmed_date);
   create index qar_ec_orders_by_state_idx on qar_ec_orders (order_state);
   
   -- note that an order could essentially become uninteresting for financial
   -- accounting if all the items underneath it are individually voided or returned
   
   create view qar_ec_orders_reportable
   as 
   select * 
   from qar_ec_orders 
   where order_state <> 'in_basket'
   and order_state <> 'void';
   
   -- orders that have items which still need to be shipped
   create view qar_ec_orders_shippable
   as
   select *
   from qar_ec_orders
   where order_state in ('authorized','partially_fulfilled');
   
   create sequence refund_id_seq;
   create view refund_id_sequence as select nextval('refund_id_seq') as nextval;

   create table qar_ec_refunds (
           refund_id       integer not null primary key,
           order_id        integer not null references qar_ec_orders,
           -- not really necessary because it's in qar_ec_financial_transactions
           refund_amount   numeric not null,
           refund_date     timestamptz not null,
           refunded_by     integer not null references users,
           refund_reasons  varchar(4000)
   );
   
   create index qar_ec_refunds_by_order_idx on qar_ec_refunds (order_id);
   

   
   create table qar_ec_gift_certificate_usage (
           gift_certificate_id     integer not null references qar_ec_gift_certificates,
           order_id                integer references qar_ec_orders,
           amount_used             numeric,
           used_date               timestamptz,
           amount_reinstated       numeric,
           reinstated_date         timestamp
   );
   
   create index qar_ec_gift_cert_by_id on qar_ec_gift_certificate_usage (gift_certificate_id);
   
   
----------- end gift certificate procedures -----------
-------------------------------------------------------

-- CREDIT CARD STUFF ------------------------
---------------------------------------------

create sequence qar_ec_transaction_id_seq start 4000000;
create view qar_ec_transaction_id_sequence as select nextval('qar_ec_transaction_id_seq') as nextval;

create table qar_ec_financial_transactions (
        transaction_id          varchar(20) not null primary key,
	-- The charge transaction that a refund transaction refunded.
	refunded_transaction_id varchar(20) references qar_ec_financial_transactions,
        -- order_id or gift_certificate_id must be filled in
        order_id                integer references qar_ec_orders,
        -- The following two rows were added 1999-08-11.  They re
        -- not actually needed by the system right now, but
        -- they might be useful in the future (I can envision them
        -- being useful as factory functions are automated).
        shipment_id             integer references ecst_ec_shipments,
        refund_id               integer references qar_ec_refunds,
        -- this refers to the purchase of a gift certificate, not the use of one
        gift_certificate_id     integer references qar_ec_gift_certificates,
        -- creditcard_id is in here even though order_id has a creditcard_id associated with
        -- it in case a different credit card is used for a refund or a partial shipment.
        -- a trigger fills the creditcard_id in if it s not specified
        creditcard_id           integer not null references qar_ec_creditcards,
        transaction_amount      numeric not null,
        refunded_amount      	numeric,
        -- charge doesn't imply that a charge will actually occur; it s just
        -- an authorization to charge
        -- in the case of a refund, theres no such thing as an authorization
        -- to refund, so the refund really will occur
        transaction_type        varchar(6) not null check (transaction_type in ('charge','refund')),
        -- it starts out null, becomes t when we want to capture it, or becomes
        -- f it is known that we don't want to capture the transaction (although
        -- the f is mainly just for reassurance; we only capture ones with t)
        -- There's no need to set this for refunds.  Refunds are always to be captured.
        to_be_captured_p        boolean, 
        inserted_date           timestamptz not null,
        authorized_date         timestamptz,
        -- set when to_be_captured_p becomes 't'; used in cron jobs
        to_be_captured_date     timestamptz,
        marked_date             timestamptz,
        refunded_date           timestamptz,
        -- if the transaction failed, this will keep the cron jobs from continuing
        -- to retry it
        failed_p                boolean default 'f',
        check (order_id is not null or gift_certificate_id is not null)
);

create index qar_ec_finan_trans_by_order_idx on qar_ec_financial_transactions (order_id);
create index qar_ec_finan_trans_by_cc_idx on qar_ec_financial_transactions (creditcard_id);
create index qar_ec_finan_trans_by_gc_idx on qar_ec_financial_transactions (gift_certificate_id);

-- reportable transactions: those which have not failed which are to
-- be captured (note: refunds are always to be captured)
create view qar_ec_fin_transactions_reportable
as
select * from qar_ec_financial_transactions
where (transaction_type='charge' and to_be_captured_p='t' and failed_p='f')
or (transaction_type='refund' and failed_p='f');


-- fills creditcard_id into qar_ec_financial_transactions if it's missing
-- (using the credit card associated with the order)
create function fin_trans_ccard_update_tr ()
returns opaque as '
declare
        v_creditcard_id         qar_ec_creditcards.creditcard_id%TYPE;
begin
        IF new.order_id is not null THEN
                select into v_creditcard_id creditcard_id 
		    from qar_ec_orders where order_id=new.order_id;
                IF new.creditcard_id is null THEN
                        new.creditcard_id := v_creditcard_id;
                END IF;
        END IF;
	return new;
end;' language 'plpgsql';

create trigger fin_trans_ccard_update_tr
before insert on qar_ec_financial_transactions
for each row execute procedure fin_trans_ccard_update_tr ();

-- END CREDIT CARD STUFF ----------------------------
-----------------------------------------------------


   -- these are the items that make up each order
   create sequence qar_ec_item_id_seq start 1; 
   create view qar_ec_item_id_sequence as select nextval('qar_ec_item_id_seq') as nextval;
   
   create table qar_ec_items (
           item_id         integer not null primary key,
           order_id        integer not null references qar_ec_orders,
           product_id      integer not null references qci_ec_products,
           color_choice    varchar(4000),
           size_choice     varchar(4000),
           style_choice    varchar(4000),

-- this should probably be changed at some point to not require the relation
-- or move the reference to ecst_ec_shipments, to not require shipping-tracking
           shipment_id     integer references ecst_ec_shipments,

           -- this is the date that user put this item into their shopping basket
           in_cart_date    timestamptz,
           voided_date     timestamptz,
           voided_by       integer references users,
           expired_date    timestamptz,
           item_state      varchar(50) default 'in_basket',
           -- NULL if not received back
           received_back_date      timestamptz,
           -- columns for reporting (e.g., what was done, what was made)
           price_charged           numeric,
           price_refunded          numeric,
           shipping_charged        numeric,
           shipping_refunded       numeric,
           price_tax_charged       numeric,
           price_tax_refunded      numeric,
           shipping_tax_charged    numeric,
           shipping_tax_refunded   numeric,
           -- like Our Price or Sale Price or Introductory Price
           price_name              varchar(30),
           -- did we go through a merchant-initiated refund?
           refund_id               integer references qar_ec_refunds,
           -- comments entered by customer service (CS)
           cs_comments             varchar(4000)
   );
   
   create index qar_ec_items_by_product on qar_ec_items(product_id);
   create index qar_ec_items_by_order on qar_ec_items(order_id);
   create index qar_ec_items_by_shipment on qar_ec_items(shipment_id);
   
   create view qar_ec_items_reportable 
   as 
   select * 
   from qar_ec_items
   where item_state in ('to_be_shipped', 'shipped', 'arrived');
   
   create view qar_ec_items_refundable
   as
   select *
   from qar_ec_items
   where item_state in ('shipped','arrived')
   and refund_id is null;
   
   create view qar_ec_items_shippable
   as
   select *
   from qar_ec_items
   where item_state in ('to_be_shipped');
   
   -- This view displays:
   -- order_id
   -- shipment_date
   -- bal_price_charged sum(price_charged - price_refunded) for all items in the shipment
   -- bal_shipping_charged
   -- bal_tax_charged
   -- The purpose: payment is recognized when an item ships so this sums the various
   -- parts of payment (price, shipping, tax) for all the items in each shipment
   
   -- gilbertw - there is a note in OpenACS 3.2.5 from DRB:
   -- DRB: this view is never used and blows out Postgres, which thinks
   -- it's too large even with a block size of (gulp) 16384!
   -- gilbertw - this view is used now. 
   
-- create view ec_items_money_view
--   as
--   select i.shipment_id, i.order_id, s.shipment_date, coalesce(sum(i.price_charged),0) - coalesce(sum(i.price_refunded),0) as bal_price_charged,
--   coalesce(sum(i.shipping_charged),0) - coalesce(sum(i.shipping_refunded),0) as bal_shipping_charged,
--   coalesce(sum(i.price_tax_charged),0) - coalesce(sum(i.price_tax_refunded),0) + coalesce(sum(i.shipping_tax_charged),0)
--     - coalesce(sum(i.shipping_tax_refunded),0) as bal_tax_charged
--   from ec_items i, ec_shipments s
--   where i.shipment_id=s.shipment_id
--   and i.item_state <> 'void'
--   group by i.order_id, i.shipment_id, s.shipment_date;
   
   -- a set of triggers to update order_state based on what happens
   -- to the items in the order
   -- partially_fulfilled: some but not all non-void items have shipped
   -- fulfilled: all non-void items have shipped
   -- returned: all non-void items received_back
   -- void: all items void
   -- We're not interested in partial returns.
   
   -- this is hellish because you can't select a count of the items
   -- in a given item_state from ec_items when you're updating ec_items,
   -- so we have to do a horrid "trio" (temporary table, row level trigger,
   -- system level trigger) as discussed in
   -- http://photo.net/doc/site-wide-search.html (we use a temporary
   -- table instead of a package because they're better)
   
   -- I. temporary table to hold the order_ids that have to have their
   -- state updated as a result of the item_state changes
   
   -- gilbertw - this table is not needed in PostgreSQL
   --create global temporary table ec_state_change_order_ids (
   --        order_id        integer
   --);
   
   -- gilbertw - this trigger is not needed
   -- II. row-level trigger which updates ec_state_change_order_ids 
   -- so we know which rows to update in ec_orders
   -- create function ec_order_state_before_tr ()
   -- returns opaque as '
   -- begin
   --         insert into ec_state_change_order_ids (order_id) values (new.order_id);
   -- 	return new;
   -- end;' language 'plpgsql';
   
   -- create trigger ec_order_state_before_tr
   -- before update on ec_items
   -- for each row execute procedure ec_order_state_before_tr ();
   
   -- III. System level trigger to update all the rows that were changed
   -- in the before trigger.
   
   -- gilbertw - I took the trigger procedure from OpenACS 3.2.5.
   create function qar_ec_order_state_after_tr ()
   returns opaque as '
   declare
           -- v_order_id              integer;
           n_items                 integer;
           n_shipped_items         integer;
           n_received_back_items   integer;
           n_void_items            integer;
           n_nonvoid_items         integer;
   
   begin
   	select count(*) into n_items from qar_ec_items where order_id=NEW.order_id;
           select count(*) into n_shipped_items from qar_ec_items 
   	    where order_id=NEW.order_id
   	    and item_state=''shipped'' or item_state=''arrived'';
           select count(*) into n_received_back_items
   	    from qar_ec_items where order_id=NEW.order_id
   	    and item_state=''received_back'';
           select count(*) into n_void_items from qar_ec_items 
   	    where order_id=NEW.order_id and item_state=''void'';
   
           IF n_items = n_void_items THEN
               update qar_ec_orders set order_state=''void'', voided_date=now()
   		where order_id=NEW.order_id;
           ELSE
               n_nonvoid_items := n_items - n_void_items;
               IF n_nonvoid_items = n_received_back_items THEN
                   update qar_ec_orders set order_state=''returned'' 
   		    where order_id=NEW.order_id;
               ELSE 
   		IF n_nonvoid_items = n_received_back_items + n_shipped_items THEN
   		    update qar_ec_orders set order_state=''fulfilled'' 
   			where order_id=NEW.order_id;
               	ELSE
   		    IF n_shipped_items >= 1 or n_received_back_items >=1 THEN
   			update qar_ec_orders set order_state=''partially_fulfilled''
   			    where order_id=NEW.order_id;
               	    END IF;
           	END IF;
   	    END IF;
   	END IF;
   	return new;
   end;' language 'plpgsql';
   
   create trigger qar_ec_order_state_after_tr 
   after update on qar_ec_items 
   for each row execute procedure qar_ec_order_state_after_tr ();
   


   -- If a user comes to product.tcl with an offer_code in the url,
   -- I'm going to shove it into this table and then check this
   -- table each time I try to determine the price for the users'
   -- products.  The alternative is to store the offer_codes in a
   -- cookie and look at that each time I try to determine the price
   -- for a product.  But I think this will be a little faster.

   create sequence qar_ec_offer_seq start 1;
   create view qar_ec_offer_sequence as select nextval('qar_ec_offer_seq') as nextval;
   
   create table qar_ec_offers (
           offer_id                integer not null primary key,
           product_id              integer not null references qci_ec_products,
           retailer_location_id    integer not null references qar_ec_retailer_locations,
           store_sku               integer,
           retailer_premiums       varchar(500),
           price                   numeric not null,
           shipping                numeric,
           shipping_unavailable_p  boolean,
           -- o = out of stock, q = ships quickly, m = ships
           -- moderately quickly, s = ships slowly, i = in stock
           -- with no message about the speed of the shipment (shipping
           -- messages are in parameters .ini file)
           stock_status            char(1) check (stock_status in ('o','q','m','s','i')),
           special_offer_p         boolean,
           special_offer_html      varchar(500),
           offer_begins            timestamptz not null,
           offer_ends              timestamptz not null,
           deleted_p               boolean default 'f',
           last_modified           timestamptz not null,
           last_modifying_user     integer not null references users,
           modified_ip_address     varchar(20) not null
   );
   
   create view qar_ec_offers_current
   as
   select * from qar_ec_offers
   where deleted_p='f'
   and now() >= offer_begins
   and now() <= offer_ends;
   
   
   create table qar_ec_offers_audit (
           offer_id                integer,
           product_id              integer,
           retailer_location_id    integer,
           store_sku               integer,
           retailer_premiums       varchar(500),
           price                   numeric,
           shipping                numeric,
           shipping_unavailable_p  boolean,
           stock_status            char(1) check (stock_status in ('o','q','m','s','i')),
           special_offer_p         boolean,
           special_offer_html      varchar(500),
           offer_begins            timestamptz,
           offer_ends              timestamptz,
           deleted_p               boolean default 'f',
           last_modified           timestamptz,
           last_modifying_user     integer,
           modified_ip_address     varchar(20),
           -- This differs from the deleted_p column!
           -- deleted_p refers to the user request to stop offering
           -- delete_p indicates the row has been deleted from the main offers table
           delete_p                boolean default 'f'
   );
   
   
   create function qar_ec_offers_audit_tr ()
   returns opaque as '
   begin
           insert into qar_ec_offers_audit (
           offer_id,
           product_id, retailer_location_id,
           store_sku, retailer_premiums,
           price, shipping,
           shipping_unavailable_p, stock_status,
           special_offer_p, special_offer_html,
           offer_begins, offer_ends,
           deleted_p,
           last_modified,
           last_modifying_user, modified_ip_address
           ) values (
           old.offer_id,
           old.product_id, old.retailer_location_id,
           old.store_sku, old.retailer_premiums,
           old.price, old.shipping,
           old.shipping_unavailable_p, old.stock_status,
           old.special_offer_p, old.special_offer_html,
           old.offer_begins, old.offer_ends,
           old.deleted_p,
           old.last_modified,
           old.last_modifying_user, old.modified_ip_address
           );
   	return new;
   end;' language 'plpgsql';
   
   create trigger qar_ec_offers_audit_tr
   after update or delete on qar_ec_offers
   for each row execute procedure qar_ec_offers_audit_tr ();




--------------- price calculations -------------------
-------------------------------------------------------

-- just the price of an order, not shipping, tax, or gift certificates
-- this is actually price_charged minus price_refunded
create function qar_ec_total_price (integer) 
returns numeric as '
DECLARE
	v_order_id	alias for $1;
        price           numeric;
BEGIN
	select into price
	    coalesce(sum(price_charged),0) - coalesce(sum(price_refunded),0)
            FROM qar_ec_items
            WHERE order_id=v_order_id
            and item_state <> ''void'';

	return price;

END;' language 'plpgsql';


-- just the shipping of an order, not price, tax, or gift certificates
-- this is actually total shipping minus total shipping refunded
create function qar_ec_total_shipping (integer)
returns numeric as '
DECLARE
	v_order_id		alias for $1;
        order_shipping          numeric;
        item_shipping           numeric;
BEGIN
        select into order_shipping
        coalesce(shipping_charged,0) - coalesce(shipping_refunded,0)
        FROM qar_ec_orders
        WHERE order_id=v_order_id;

        select into item_shipping
        coalesce(sum(shipping_charged),0) - coalesce(sum(shipping_refunded),0)
        FROM qar_ec_items
        WHERE order_id=v_order_id
        and item_state <> ''void'';

        return order_shipping + item_shipping;
END;' language 'plpgsql';

-- OK
-- just the tax of an order, not price, shipping, or gift certificates
-- this is tax minus tax refunded
create function qar_ec_total_tax (integer)
returns numeric as '
DECLARE
	v_order_id			alias for $1;
        order_tax               	numeric;
        item_price_tax          	numeric;
        item_shipping_tax       	numeric;
BEGIN
        select into order_tax
        coalesce(shipping_tax_charged,0) - coalesce(shipping_tax_refunded,0)
        FROM qar_ec_orders
        WHERE order_id=v_order_id;

        select into item_price_tax
        coalesce(sum(price_tax_charged),0) - coalesce(sum(price_tax_refunded),0)
        FROM qar_ec_items
        WHERE order_id=v_order_id
        and item_state <> ''void'';

        select into item_shipping_tax
        coalesce(sum(shipping_tax_charged),0) - coalesce(sum(shipping_tax_refunded),0)
        FROM qar_ec_items
        WHERE order_id=v_order_id;

        return order_tax + item_price_tax + item_shipping_tax;
END;' language 'plpgsql';


-- OK
-- just the price of a shipment, not shipping, tax, or gift certificates
-- this is the price charged minus the price refunded of the shipment
create function qar_ec_shipment_price (integer)
returns numeric as '
DECLARE
	v_shipment_id		alias for $1;
        shipment_price          numeric;
BEGIN
        SELECT into shipment_price coalesce(sum(price_charged),0) - coalesce(sum(price_refunded),0)
        FROM qar_ec_items
        WHERE shipment_id=v_shipment_id
        and item_state <> ''void'';

        RETURN shipment_price;
END;' language 'plpgsql';

-- OK
-- just the shipping charges of a shipment, not price, tax, or gift certificates
-- note: the base shipping charge is always applied to the first shipment in an order.
-- this is the shipping charged minus the shipping refunded
create function qar_ec_shipment_shipping (integer)
returns numeric as '
DECLARE
	v_shipment_id 		alias for $1;
        item_shipping           numeric;
        base_shipping           numeric;
        v_order_id              qar_ec_orders.order_id%TYPE;
        min_shipment_id         qar_ec_shipments.shipment_id%TYPE;
BEGIN
        SELECT into v_order_id order_id 
	    FROM qar_ec_shipments where shipment_id=v_shipment_id;
        SELECT into min_shipment_id min(s.shipment_id) 
	    from qar_ec_shipments s, qar_ec_items i, qci_ec_products p
	    where s.order_id = v_order_id
	    and s.shipment_id = i.shipment_id
	    and i.product_id = p.product_id
	    and p.no_shipping_avail_p = ''f'';
        IF v_shipment_id=min_shipment_id THEN
                SELECT into base_shipping 
		    coalesce(shipping_charged,0) - coalesce(shipping_refunded,0)
		    FROM qar_ec_orders where order_id=v_order_id;
        ELSE
                base_shipping := 0;
        END IF;
        SELECT into item_shipping 
	    coalesce(sum(shipping_charged),0) - coalesce(sum(shipping_refunded),0) 
	    FROM qar_ec_items where shipment_id=v_shipment_id 
	    and item_state <> ''void'';
        RETURN item_shipping + base_shipping;
END;' language 'plpgsql';

-- OK
-- just the tax of a shipment, not price, shipping, or gift certificates
-- note: the base shipping tax charge is always applied to the first shipment in an order.
-- this is the tax charged minus the tax refunded
create function qar_ec_shipment_tax (integer)
returns numeric as '
DECLARE
	v_shipment_id 		alias for $1;
        item_price_tax          numeric;
        item_shipping_tax       numeric;
        base_shipping_tax       numeric;
        v_order_id              qar_ec_orders.order_id%TYPE;
        min_shipment_id         qar_ec_shipments.shipment_id%TYPE;
BEGIN
        SELECT into v_order_id order_id 
	    FROM qar_ec_shipments where shipment_id=v_shipment_id;
        SELECT into min_shipment_id min(s.shipment_id) 
	    from qar_ec_shipments s, qar_ec_items i, qar_ec_products p
	    where s.order_id = v_order_id
	    and s.shipment_id = i.shipment_id
	    and i.product_id = p.product_id
	    and p.no_shipping_avail_p = ''f'';
        IF v_shipment_id=min_shipment_id THEN
                SELECT into base_shipping_tax 
		coalesce(shipping_tax_charged,0) - coalesce(shipping_tax_refunded,0) 
		FROM qar_ec_orders where order_id=v_order_id;
        ELSE
                base_shipping_tax := 0;
        END IF;
        SELECT into item_price_tax 
	coalesce(sum(price_tax_charged),0) - coalesce(sum(price_tax_refunded),0) 
	FROM qar_ec_items where shipment_id=v_shipment_id and item_state <> ''void'';
        SELECT into item_shipping_tax 
	coalesce(sum(shipping_tax_charged),0) - coalesce(sum(shipping_tax_refunded),0) 
	FROM qar_ec_items where shipment_id=v_shipment_id and item_state <> ''void'';
        RETURN item_price_tax + item_shipping_tax + base_shipping_tax;
END;' language 'plpgsql';


-- OK
-- the gift certificate amount used on one order
create function qar_ec_order_gift_cert_amount (integer)
returns numeric as '
DECLARE
	v_order_id		alias for $1;
        gift_cert_amount        numeric;
BEGIN
        select into gift_cert_amount
        coalesce(sum(amount_used),0) - coalesce(sum(amount_reinstated),0)
        FROM qar_ec_gift_certificate_usage
        WHERE order_id=v_order_id;

        return gift_cert_amount;
END;' language 'plpgsql';


-- OK
-- tells how much of the gift certificate amount used on the order is to be applied
-- to a shipment (it's applied chronologically)
create function qar_ec_shipment_gift_certificate (integer)
returns numeric as '
DECLARE
	v_shipment_id		alias for $1;
        v_order_id              qar_ec_orders.order_id%TYPE;
        gift_cert_amount        numeric;
        past_ship_amount        numeric;
BEGIN
        SELECT into v_order_id order_id 
	    FROM qar_ec_shipments WHERE shipment_id=v_shipment_id;
        gift_cert_amount := qar_ec_order_gift_cert_amount(v_order_id);
        SELECT into past_ship_amount 
	    coalesce(sum(qar_ec_shipment_price(shipment_id)) + sum(qar_ec_shipment_shipping(shipment_id))+sum(qar_ec_shipment_tax(shipment_id)),0) 
	    FROM qar_ec_shipments WHERE order_id = v_order_id and shipment_id <> v_shipment_id;

        IF past_ship_amount > gift_cert_amount THEN
                return 0;
        ELSE
                return least(gift_cert_amount - past_ship_amount, coalesce(qar_ec_shipment_price(v_shipment_id) + qar_ec_shipment_shipping(v_shipment_id) + qar_ec_shipment_tax(v_shipment_id),0));
        END IF;
END;' language 'plpgsql';

--CHECK OUTER JOIN BELOW

-- OK
-- this can be used for either an item or order
-- given price and shipping, computes tax that needs to be charged (or refunded)
-- order_id is an argument so that we can get the usps_abbrev (and thus the tax rate),
create function qar_ec_tax (numeric, numeric, integer) 
returns numeric as '
DECLARE
	v_price			alias for $1;
	v_shipping		alias for $2;
	v_order_id		alias for $3;
        taxes                   qar_ec_sales_tax_by_state%ROWTYPE;
        tax_exempt_p            qar_ec_orders.tax_exempt_p%TYPE;
BEGIN
        SELECT into tax_exempt_p tax_exempt_p 
        FROM qar_ec_orders
        WHERE order_id = v_order_id;

        IF tax_exempt_p = ''t'' THEN
                return 0;
        END IF; 
        
        --SELECT t.* into taxes
        --FROM qar_ec_orders o, qar_ec_addresses a, qar_ec_sales_tax_by_state t
        --WHERE o.shipping_address=a.address_id
        --AND a.usps_abbrev=t.usps_abbrev(+)
        --AND o.order_id=v_order_id;

        SELECT into taxes t.* 
	FROM qar_ec_orders o
	    JOIN 
	qar_ec_addresses a on (o.shipping_address=a.address_id)
	    LEFT JOIN
	qar_ec_sales_tax_by_state t using (usps_abbrev)
	WHERE o.order_id=v_order_id;
	

        IF coalesce(taxes.shipping_p,''f'') = ''f'' THEN
                return coalesce(taxes.tax_rate,0) * v_price;
        ELSE
                return coalesce(taxes.tax_rate,0) * (v_price + v_shipping);
        END IF;
END;' language 'plpgsql';

-- OK
-- total order cost (price + shipping + tax - gift certificate)
-- this should be equal to the amount that the order was authorized for
-- (if no refunds have been made)
create function qar_ec_order_cost (integer)
returns numeric as '
DECLARE
	v_order_id	alias for $1;
        v_price         numeric;
        v_shipping      numeric;
        v_tax           numeric;
        v_certificate   numeric;
BEGIN
        v_price := qar_ec_total_price(v_order_id);
        v_shipping := qar_ec_total_shipping(v_order_id);
        v_tax := qar_ec_total_tax(v_order_id);
        v_certificate := qar_ec_order_gift_cert_amount(v_order_id);

        return v_price + v_shipping + v_tax - v_certificate;
END;' language 'plpgsql';

-- OK
-- total shipment cost (price + shipping + tax - gift certificate)
create function qar_ec_shipment_cost (integer)
returns numeric as '
DECLARE
	v_shipment_id	alias for $1;
        v_price         numeric;
        v_shipping      numeric;
        v_certificate   numeric;
        v_tax           numeric;
BEGIN
        v_price := qar_ec_shipment_price(v_shipment_id);
        v_shipping := qar_ec_shipment_shipping(v_shipment_id);
        v_tax := qar_ec_shipment_tax(v_shipment_id);
        v_certificate := qar_ec_shipment_gift_certificate(v_shipment_id);

        return v_price + v_shipping - v_certificate + v_tax;
END;' language 'plpgsql';

-- OK
-- total amount refunded on an order so far
create function qar_ec_total_refund (integer)
returns numeric as '
DECLARE
	v_order_id 	alias for $1;
        v_order_refund  numeric;
        v_items_refund  numeric;
BEGIN
        select into v_order_refund 
	    coalesce(shipping_refunded,0) + coalesce(shipping_tax_refunded,0) 
	    from qar_ec_orders where order_id=v_order_id;
        select into v_items_refund 
	    sum(coalesce(price_refunded,0)) + sum(coalesce(shipping_refunded,0)) + sum(coalesce(price_tax_refunded,0)) + sum(coalesce(shipping_tax_refunded,0)) from qar_ec_items where order_id=v_order_id;
        return v_order_refund + v_items_refund;
END;' language 'plpgsql';

-------------- end price calculations -----------------
-------------------------------------------------------
  
--
-- BMA (PGsql port)
-- Postgres is way cooler than Oracle with MVCC, which allows it
-- to have triggers updating the same table. Thus, we get rid of this
-- trio crap and we have a simple trigger for everything.

create function trig_qar_ec_cert_amount_remains()
returns opaque
as '
DECLARE
        bal_amount_used         numeric;
        original_amount         numeric;
BEGIN
        select amount into original_amount
        from qar_ec_gift_certificates where gift_certificate_id= NEW.certificate_id for update;

        select coalesce(sum(amount_used), 0) - coalesce(sum(amount_reinstated), 0)
        into bal_amount_used
        from qar_ec_gift_certificate_usage
        where gift_certificate_id= NEW.gift_certificate_id;

        UPDATE qar_ec_gift_certificates
        SET amount_remaining_p = case when amount > bal_amount_used then ''t'' else ''f'' end
        WHERE gift_certificate_id = gift_certificate_rec.gift_certificate_id;
	return new;
END;
' language 'plpgsql';

create trigger qar_ec_cert_amount_remains
after update on qar_ec_gift_certificate_usage
for each row
execute procedure trig_qar_ec_cert_amount_remains();


-- OK
-- calculates how much a user has in their gift certificate account
create function qar_ec_gift_certificate_balance (integer)
returns numeric as '
DECLARE
	v_user_id alias for $1;
	original_amount                 numeric;
	total_amount_used               numeric;
        -- these only look at unexpired gift certificates 
	-- where amount_remaining_p is t,
        -- hence the word subset in their names
BEGIN
        SELECT coalesce(sum(amount),0)
	into original_amount
        FROM qar_ec_gift_certificates_approved
        WHERE user_id=v_user_id
        AND amount_remaining_p=''t''
        AND expires > now();

        SELECT coalesce(sum(u.amount_used),0) - 
    	    coalesce(sum(u.amount_reinstated),0)
	into total_amount_used
        FROM qar_ec_gift_certificates_approved c, qar_ec_gift_certificate_usage u
        WHERE c.gift_certificate_id=u.gift_certificate_id
        AND c.user_id=v_user_id
        AND c.amount_remaining_p=''t''
        AND c.expires > now();

        RETURN original_amount - total_amount_used;
END;' language 'plpgsql';

-- OK
-- Returns price + shipping + tax - gift certificate amount applied
-- for one order.
-- Requirement: qar_ec_orders.shipping_charged, qar_ec_orders.shipping_tax_charged,
-- qar_ec_items.price_charged, qar_ec_items.shipping_charged, qar_ec_items.price_tax_chaged,
-- and qar_ec_items.shipping_tax_charged should already be filled in.

create function qar_ec_order_amount_owed (integer)
returns numeric as '
DECLARE
	v_order_id			alias for $1;
        pre_gc_amount_owed              numeric;
        gc_amount                       numeric;
BEGIN
        pre_gc_amount_owed := qar_ec_total_price(v_order_id) + qar_ec_total_shipping(v_order_id) + qar_ec_total_tax(v_order_id);
        gc_amount := qar_ec_order_gift_cert_amount(v_order_id);

        RETURN pre_gc_amount_owed - gc_amount;
END;' language 'plpgsql';

-- OK
-- the amount remaining in an individual gift certificate
create function gift_certificate_amount_left (integer)
returns numeric as '
DECLARE
	v_gift_certificate_id 	alias for $1;
        original_amount         numeric;
        total_amount_used       numeric;
BEGIN
        SELECT coalesce(sum(amount_used),0) - coalesce(sum(amount_reinstated),0)
	into total_amount_used
        FROM qar_ec_gift_certificate_usage
        WHERE gift_certificate_id = v_gift_certificate_id;

        SELECT amount
	into original_amount
        FROM qar_ec_gift_certificates
        WHERE gift_certificate_id = v_gift_certificate_id;

        RETURN original_amount - total_amount_used;
END;' language 'plpgsql';

-- I DON'T USE THIS PROCEDURE ANYMORE BECAUSE THERE'S A MORE
-- FAULT-TOLERANT TCL VERSION
-- This applies gift certificate balance to an entire order
-- by iteratively applying unused/unexpired gift certificates
-- to the order until the order is completely paid for or
-- the gift certificates run out.
-- Requirement: qar_ec_orders.shipping_charged, qar_ec_orders.shipping_tax_charged,
-- qar_ec_items.price_charged, qar_ec_items.shipping_charged, qar_ec_items.price_tax_charged,
-- qar_ec_items.shipping_tax_charged should already be filled in.
-- Call this within a transaction.
--create or replace procedure qar_ec_apply_gift_cert_balance (v_order_id IN integer, v_user_id IN integer)
--IS
--        CURSOR gift_certificate_to_use_cursor IS
--                SELECT *
--                FROM qar_ec_gift_certificates_approved
--                WHERE user_id = v_user_id
--                AND (expires is null or now() < expires )
--                AND amount_remaining_p = ''t''
--                ORDER BY expires;
--        amount_owed                     number;
--        gift_certificate_balance        number;
--        certificate                     qar_ec_gift_certificates_approved%ROWTYPE;
--BEGIN
--        gift_certificate_balance := qar_ec_gift_certificate_balance(v_user_id);
--        amount_owed := qar_ec_order_amount_owed(v_order_id);
--
--        OPEN gift_certificate_to_use_cursor;
--        WHILE amount_owed > 0 and gift_certificate_balance > 0
--                LOOP
--                        FETCH gift_certificate_to_use_cursor INTO certificate;
--
--                        INSERT into qar_ec_gift_certificate_usage
--                        (gift_certificate_id, order_id, amount_used, used_date)
--                        VALUES
--                        (certificate.gift_certificate_id, v_order_id, least(gift_certificate_amount_left(certificate.gift_certificate_id), amount_owed), now());
--
--                        gift_certificate_balance := qar_ec_gift_certificate_balance(v_user_id);
--                        amount_owed := qar_ec_order_amount_owed(v_order_id);        
--                END LOOP;
--        CLOSE gift_certificate_to_use_cursor;
--END qar_ec_apply_gift_cert_balance;
--/
--show errors

-- OK
-- reinstates all gift certificates used on an order (as opposed to
-- individual items), e.g. if the order was voided or an auth failed

create function qar_ec_reinst_gift_cert_on_order (integer)
returns integer as '
DECLARE
	v_order_id	alias for $1;
BEGIN
        insert into qar_ec_gift_certificate_usage
        (gift_certificate_id, order_id, amount_reinstated, reinstated_date)
        select gift_certificate_id, v_order_id, coalesce(sum(amount_used),0)-coalesce(sum(amount_reinstated),0), now()
        from qar_ec_gift_certificate_usage
        where order_id=v_order_id
        group by gift_certificate_id;

	return 0;
END;' language 'plpgsql';

-- Given an amount to refund to an order, this tells
-- you how much of that is to be refunded in cash (as opposed to 
-- reinstated in gift certificates).  Then you know you have to
-- go and reinstate v_amount minus (what this function returns)
-- in gift certificates.
-- (when I say cash I'm really talking about credit card
-- payment -- as opposed to gift certificates)

-- Call this before inserting the amounts that are being refunded
-- into the database.
create function qar_ec_cash_amount_to_refund (numeric, integer) 
returns numeric as '
DECLARE
	v_amount			alias for $1;
	v_order_id			alias for $2;
        amount_paid                     numeric;
        items_amount_paid               numeric;
        order_amount_paid               numeric;
        amount_refunded                 numeric;
        curr_gc_amount                  numeric;
        max_cash_refundable             numeric;
        cash_to_refund                  numeric;
BEGIN
        -- the maximum amount of cash refundable is equal to
        -- the amount paid (in cash + certificates) for shipped items only (since
        --  money is not paid until an item actually ships)
        -- minus the amount refunded (in cash + certificates) (only occurs for shipped items)
        -- minus the current gift certificate amount applied to this order
        -- or 0 if the result is negative

        select sum(coalesce(price_charged,0)) + sum(coalesce(shipping_charged,0)) + sum(coalesce(price_tax_charged,0)) + sum(coalesce(shipping_tax_charged,0)) into items_amount_paid from qar_ec_items where order_id=v_order_id and shipment_id is not null and item_state <> ''void'';

        select coalesce(shipping_charged,0) + coalesce(shipping_tax_charged,0) into order_amount_paid from qar_ec_orders where order_id=v_order_id;

        amount_paid := items_amount_paid + order_amount_paid;
        amount_refunded := qar_ec_total_refund(v_order_id);
        curr_gc_amount := qar_ec_order_gift_cert_amount(v_order_id);
        
        max_cash_refundable := amount_paid - amount_refunded - curr_gc_amount;
        cash_to_refund := least(max_cash_refundable, v_amount);

        RETURN cash_to_refund;
END;' language 'plpgsql';

-- The amount of a given gift certificate used on a given order.
-- This is a helper function for qar_ec_gift_cert_unshipped_amount.
create function qar_ec_one_gift_cert_on_one_order (integer, integer) 
returns numeric as '
DECLARE
	v_gift_certificate_id	alias for $1;
	v_order_id		alias for $2;
        bal_amount_used         numeric;
BEGIN
        select coalesce(sum(amount_used),0)-coalesce(sum(amount_reinstated),0) into bal_amount_used
        from qar_ec_gift_certificate_usage
        where order_id=v_order_id
        and gift_certificate_id=v_gift_certificate_id;

        RETURN bal_amount_used;

END;' language 'plpgsql'; 

-- The amount of all gift certificates used on a given order that
-- expire before* a given gift certificate (*in the event that two
-- expire at precisely the same time, the one with a higher
-- gift_certificate_id is defined to expire last).
-- This is a helper function for qar_ec_gift_cert_unshipped_amount.
create function qar_ec_earlier_certs_on_one_order (integer, integer)
returns numeric as '
DECLARE
	v_gift_certificate_id	alias for $1;
	v_order_id		alias for $2;
        bal_amount_used         numeric;
BEGIN
        select coalesce(sum(u.amount_used),0)-coalesce(sum(u.amount_reinstated),0) into bal_amount_used
        from qar_ec_gift_certificate_usage u, qar_ec_gift_certificates g, qar_ec_gift_certificates g2
        where u.gift_certificate_id=g.gift_certificate_id
        and g2.gift_certificate_id=v_gift_certificate_id
        and u.order_id=v_order_id
        and (g.expires < g2.expires or (g.expires = g2.expires and g.gift_certificate_id < g2.gift_certificate_id));

        return bal_amount_used;
END;' language 'plpgsql';

-- The amount of a gift certificate that is applied to the upshipped portion of an order.
-- This is a helper function for qar_ec_gift_cert_unshipped_amount.
create function qar_ec_cert_unshipped_one_order (integer, integer)
returns numeric as '
DECLARE
	v_gift_certificate_id	alias for $1;	
	v_order_id		alias for $2;
        total_shipment_cost     numeric;
        earlier_certs           numeric;
        total_tied_amount       numeric;
BEGIN
        select coalesce(sum(coalesce(qar_ec_shipment_price(shipment_id),0) + coalesce(qar_ec_shipment_shipping(shipment_id),0) + coalesce(qar_ec_shipment_tax(shipment_id),0)),0) into total_shipment_cost
        from qar_ec_shipments
        where order_id=v_order_id;

        earlier_certs := qar_ec_earlier_certs_on_one_order(v_gift_certificate_id, v_order_id);

        IF total_shipment_cost <= earlier_certs THEN
                total_tied_amount := qar_ec_one_gift_cert_on_one_order(v_gift_certificate_id, v_order_id);
        ELSE
	    IF total_shipment_cost > earlier_certs + qar_ec_one_gift_cert_on_one_order(v_gift_certificate_id, v_order_id) THEN
                total_tied_amount := 0;
            ELSE
                total_tied_amount := qar_ec_one_gift_cert_on_one_order(v_gift_certificate_id, v_order_id) - (total_shipment_cost - earlier_certs);
	    END IF;
        END IF;

        RETURN total_tied_amount;               
END;' language 'plpgsql';

--HERE

-- Returns the amount of a gift certificate that is applied to the unshipped portions of orders
-- (this amount is still considered outstanding since revenue, and thus gift certificate usage,
-- isnt recognized until the items ship).
create function qar_ec_gift_cert_unshipped_amount (integer)
returns numeric as '
DECLARE
	v_gift_certificate_id		alias for $1;
        tied_but_unshipped_amount       numeric;
BEGIN
        select coalesce(sum(qar_ec_cert_unshipped_one_order(v_gift_certificate_id,order_id)),0) into tied_but_unshipped_amount
        from qar_ec_orders
        where order_id in (select distinct order_id from qar_ec_gift_certificate_usage where gift_certificate_id=v_gift_certificate_id);

        return tied_but_unshipped_amount;
END;' language 'plpgsql';




---------- end gift certificate procedures ------------
-------------------------------------------------------

------------ tax related calculations --------
-----------------------------------------
-- 
-- -- this is populated by the rules the administrator sets in packages/ecommerce/www/admin]/sales-tax.tcl
 create table qar_ec_sales_tax_by_state (
           -- Jerry
            usps_abbrev             char(2) not null primary key references us_states(abbrev),
            -- this a decimal number equal to the percentage tax divided by 100
            tax_rate                numeric not null,
            -- charge tax on shipping?
            shipping_p              boolean not null,
            last_modified           timestamptz not null,
            last_modifying_user     integer not null references users,
            modified_ip_address     varchar(20) not null
    );
    
    create table qar_ec_sales_tax_by_state_audit (
            usps_abbrev             char(2),
            tax_rate                numeric,
            shipping_p              boolean,
            last_modified           timestamptz,
            last_modifying_user     integer,
            modified_ip_address     varchar(20),
            delete_p                boolean default 'f'
    );
    
    
    -- Jerry - I removed usps_abbrev and/or state here
    create function qar_ec_sales_tax_by_state_audit_tr ()
    returns opaque as '
    begin
            insert into qar_ec_sales_tax_by_state_audit (
            usps_abbrev, tax_rate,
            shipping_p,
            last_modified,
            last_modifying_user, modified_ip_address
            ) values (
            old.usps_abbrev, old.tax_rate,
            old.shipping_p,
            old.last_modified,
            old.last_modifying_user, old.modified_ip_address              
            );
    	return new;
    end;' language 'plpgsql';
    
    create trigger qar_ec_sales_tax_by_state_audit_tr
    after update or delete on qar_ec_sales_tax_by_state
    for each row execute procedure qar_ec_sales_tax_by_state_audit_tr ();
    
