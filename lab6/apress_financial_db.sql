--
-- PostgreSQL database dump
--

\restrict r2Op80XHn44d5CatT1Gw3FisMVAoAYvq6dHgSMJgDrQphy3UIFfobe3yytCK7SV

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.6 (Debian 18.6-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: CustomerDetails; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA "CustomerDetails";


ALTER SCHEMA "CustomerDetails" OWNER TO postgres;

--
-- Name: ShareDetails; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA "ShareDetails";


ALTER SCHEMA "ShareDetails" OWNER TO postgres;

--
-- Name: TransactionDetails; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA "TransactionDetails";


ALTER SCHEMA "TransactionDetails" OWNER TO postgres;

--
-- Name: fn_instransactions(); Type: FUNCTION; Schema: CustomerDetails; Owner: postgres
--

CREATE FUNCTION "CustomerDetails".fn_instransactions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE
"CustomerDetails".customers
SET clearbalance = clearbalance + COALESCE((
SELECT
CASE
WHEN tt.credittype = false THEN (i.amount * -1)::money
ELSE (i.amount)::money
END
FROM NEW AS i
JOIN "TransactionDetails".transactiontypes AS tt
ON tt.transactiontypesid = i.transactiontype
WHERE tt.affectcashbalance = true), 0::money)
WHERE customerid = NEW.customerid;
RETURN NULL;
END;
$$;


ALTER FUNCTION "CustomerDetails".fn_instransactions() OWNER TO postgres;

--
-- Name: spu_inscustomer(character varying, character varying, integer, character varying, integer, character varying, integer); Type: PROCEDURE; Schema: CustomerDetails; Owner: postgres
--

CREATE PROCEDURE "CustomerDetails".spu_inscustomer(IN firstname character varying, IN lastname character varying, IN custtitle integer, IN custinitials character varying, IN addressid integer, IN accountnumber character varying, IN accounttypeid integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO "CustomerDetails".customers (
customertitleid,
customerfirstname,
customerotherinitials,
customerlastname,
addressid,
accountnumber,
accounttypeid,
clearbalance,
unclearbalance)
VALUES (
custtitle,
firstname,
custinitials,
lastname,
addressid,
accountnumber,
accounttypeid,
0,
0);
END;
$$;


ALTER PROCEDURE "CustomerDetails".spu_inscustomer(IN firstname character varying, IN lastname character varying, IN custtitle integer, IN custinitials character varying, IN addressid integer, IN accountnumber character varying, IN accounttypeid integer) OWNER TO postgres;

--
-- Name: fn_intcalc(numeric, date, date, numeric); Type: FUNCTION; Schema: TransactionDetails; Owner: postgres
--

CREATE FUNCTION "TransactionDetails".fn_intcalc(amount numeric, fromdate date, todate date, interestrate numeric DEFAULT 10) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
IntCalculated decimal (18,5);
BEGIN
IntCalculated := Amount * (InterestRate / 100.00) * (EXTRACT(DAY FROM ToDate::timestamp-FromDate::timestamp)/365.0);
RETURN COALESCE(IntCalculated,0);
END;
$$;


ALTER FUNCTION "TransactionDetails".fn_intcalc(amount numeric, fromdate date, todate date, interestrate numeric) OWNER TO postgres;

--
-- Name: fn_returntransactions(bigint); Type: FUNCTION; Schema: TransactionDetails; Owner: postgres
--

CREATE FUNCTION "TransactionDetails".fn_returntransactions(custid bigint) RETURNS TABLE(transactionid bigint, customerid bigint, transactiondescription character varying, dateentered timestamp without time zone, amount money)
    LANGUAGE sql
    AS $$
SELECT 
t.transactionid as transactionid,
t.customerid as customerid,
tt.transactiondescription as transactiondescription,
t.dateentered as dateentered,
t.amount as amount
FROM
"TransactionDetails".transactions t
JOIN "TransactionDetails".transactiontypes tt
ON tt.transactiontypesid = t.transactiontype
WHERE t.customerid = CustID;
$$;


ALTER FUNCTION "TransactionDetails".fn_returntransactions(custid bigint) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: customerproducts; Type: TABLE; Schema: CustomerDetails; Owner: postgres
--

CREATE TABLE "CustomerDetails".customerproducts (
    customerfinancialproductid bigint NOT NULL,
    customerid bigint NOT NULL,
    financialproductid bigint NOT NULL,
    amounttocollect money NOT NULL,
    frequency integer NOT NULL,
    lastcollected timestamp(0) without time zone NOT NULL,
    lascollection timestamp(0) without time zone NOT NULL,
    renewable boolean DEFAULT false NOT NULL,
    CONSTRAINT ck_custprod_amountcheck CHECK ((amounttocollect > (0)::money)),
    CONSTRAINT ck_last_collected_amount CHECK ((lascollection >= lastcollected))
);


ALTER TABLE "CustomerDetails".customerproducts OWNER TO postgres;

--
-- Name: customerproducts_customerfinancialproductid_seq; Type: SEQUENCE; Schema: CustomerDetails; Owner: postgres
--

ALTER TABLE "CustomerDetails".customerproducts ALTER COLUMN customerfinancialproductid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "CustomerDetails".customerproducts_customerfinancialproductid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customers; Type: TABLE; Schema: CustomerDetails; Owner: postgres
--

CREATE TABLE "CustomerDetails".customers (
    customerid bigint NOT NULL,
    customertitleid integer NOT NULL,
    customerfirstname character varying(50) NOT NULL,
    customerotherinitials character varying(10),
    customerlastname character varying(50) NOT NULL,
    addressid bigint NOT NULL,
    accountnumber character(15) NOT NULL,
    accounttypeid integer NOT NULL,
    clearbalance money NOT NULL,
    unclearbalance money NOT NULL,
    dateadded date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE "CustomerDetails".customers OWNER TO postgres;

--
-- Name: customers_customerid_seq; Type: SEQUENCE; Schema: CustomerDetails; Owner: postgres
--

ALTER TABLE "CustomerDetails".customers ALTER COLUMN customerid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "CustomerDetails".customers_customerid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: financialproducts; Type: TABLE; Schema: CustomerDetails; Owner: postgres
--

CREATE TABLE "CustomerDetails".financialproducts (
    productid bigint NOT NULL,
    productname character varying(50) NOT NULL
);


ALTER TABLE "CustomerDetails".financialproducts OWNER TO postgres;

--
-- Name: v_custfinproducts; Type: MATERIALIZED VIEW; Schema: CustomerDetails; Owner: postgres
--

CREATE MATERIALIZED VIEW "CustomerDetails".v_custfinproducts AS
 SELECT (((c.customerfirstname)::text || ' '::text) || (c.customerlastname)::text) AS customername,
    c.accountnumber,
    fp.productname,
    cp.amounttocollect,
    cp.frequency,
    cp.lastcollected
   FROM (("CustomerDetails".customers c
     JOIN "CustomerDetails".customerproducts cp ON ((cp.customerid = c.customerid)))
     JOIN "CustomerDetails".financialproducts fp ON ((fp.productid = cp.financialproductid)))
  WITH NO DATA;


ALTER MATERIALIZED VIEW "CustomerDetails".v_custfinproducts OWNER TO postgres;

--
-- Name: transactions; Type: TABLE; Schema: TransactionDetails; Owner: postgres
--

CREATE TABLE "TransactionDetails".transactions (
    transactionid bigint NOT NULL,
    customerid bigint NOT NULL,
    transactiontype integer NOT NULL,
    dateentered timestamp(0) without time zone NOT NULL,
    amount numeric(18,5) NOT NULL,
    notes character varying,
    referencedetails character varying(50),
    relatedproductid bigint NOT NULL,
    relatedshareid bigint
);


ALTER TABLE "TransactionDetails".transactions OWNER TO postgres;

--
-- Name: transactiontypes; Type: TABLE; Schema: TransactionDetails; Owner: postgres
--

CREATE TABLE "TransactionDetails".transactiontypes (
    transactiontypesid integer NOT NULL,
    transactiondescription character varying(30) NOT NULL,
    credittype boolean NOT NULL,
    affectcashbalance boolean NOT NULL
);


ALTER TABLE "TransactionDetails".transactiontypes OWNER TO postgres;

--
-- Name: v_custtrans; Type: VIEW; Schema: CustomerDetails; Owner: postgres
--

CREATE VIEW "CustomerDetails".v_custtrans AS
 SELECT c.accountnumber,
    c.customerfirstname,
    c.customerotherinitials,
    tt.transactiondescription,
    t.dateentered,
    t.amount,
    t.referencedetails
   FROM (("CustomerDetails".customers c
     JOIN "TransactionDetails".transactions t ON ((t.customerid = c.customerid)))
     JOIN "TransactionDetails".transactiontypes tt ON ((tt.transactiontypesid = t.transactiontype)))
  ORDER BY c.accountnumber, t.dateentered DESC;


ALTER VIEW "CustomerDetails".v_custtrans OWNER TO postgres;

--
-- Name: shareprices; Type: TABLE; Schema: ShareDetails; Owner: postgres
--

CREATE TABLE "ShareDetails".shareprices (
    sharepriceid bigint NOT NULL,
    shareid bigint NOT NULL,
    price numeric(18,5) NOT NULL,
    pricedate timestamp(0) without time zone NOT NULL
);


ALTER TABLE "ShareDetails".shareprices OWNER TO postgres;

--
-- Name: shareprices_sharepriceid_seq; Type: SEQUENCE; Schema: ShareDetails; Owner: postgres
--

ALTER TABLE "ShareDetails".shareprices ALTER COLUMN sharepriceid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "ShareDetails".shareprices_sharepriceid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: shares; Type: TABLE; Schema: ShareDetails; Owner: postgres
--

CREATE TABLE "ShareDetails".shares (
    shareid bigint NOT NULL,
    sharedesc character varying(50) NOT NULL,
    sharetickerid character varying(50) NOT NULL,
    currentprice numeric(18,5) NOT NULL
);


ALTER TABLE "ShareDetails".shares OWNER TO postgres;

--
-- Name: shares_shareid_seq; Type: SEQUENCE; Schema: ShareDetails; Owner: postgres
--

ALTER TABLE "ShareDetails".shares ALTER COLUMN shareid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "ShareDetails".shares_shareid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: v_currentshares; Type: VIEW; Schema: ShareDetails; Owner: postgres
--

CREATE VIEW "ShareDetails".v_currentshares AS
 SELECT shareid,
    sharedesc,
    sharetickerid,
    currentprice AS "Last Price"
   FROM "ShareDetails".shares
  WHERE (currentprice > (0)::numeric)
  ORDER BY sharedesc;


ALTER VIEW "ShareDetails".v_currentshares OWNER TO postgres;

--
-- Name: v_currentshares1; Type: VIEW; Schema: ShareDetails; Owner: postgres
--

CREATE VIEW "ShareDetails".v_currentshares1 AS
 SELECT sharedesc,
    sharetickerid,
    currentprice AS "Last Price"
   FROM "ShareDetails".shares
  WHERE (currentprice > (0)::numeric)
  ORDER BY sharedesc;


ALTER VIEW "ShareDetails".v_currentshares1 OWNER TO postgres;

--
-- Name: v_shareprices; Type: VIEW; Schema: ShareDetails; Owner: postgres
--

CREATE VIEW "ShareDetails".v_shareprices AS
 SELECT sp.shareid,
    sp.price,
    sp.pricedate,
    vcs.sharedesc
   FROM ("ShareDetails".shareprices sp
     JOIN "ShareDetails".v_currentshares vcs ON ((sp.shareid = vcs.shareid)))
  ORDER BY vcs.sharedesc, sp.pricedate DESC;


ALTER VIEW "ShareDetails".v_shareprices OWNER TO postgres;

--
-- Name: transactions_transactionid_seq; Type: SEQUENCE; Schema: TransactionDetails; Owner: postgres
--

ALTER TABLE "TransactionDetails".transactions ALTER COLUMN transactionid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "TransactionDetails".transactions_transactionid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: transactiontypes_transactiontypesid_seq; Type: SEQUENCE; Schema: TransactionDetails; Owner: postgres
--

ALTER TABLE "TransactionDetails".transactiontypes ALTER COLUMN transactiontypesid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "TransactionDetails".transactiontypes_transactiontypesid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: v_currentshares; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_currentshares AS
 SELECT sharedesc,
    sharetickerid,
    currentprice AS "Last Price"
   FROM "ShareDetails".shares
  WHERE (currentprice > (0)::numeric)
  ORDER BY sharedesc;


ALTER VIEW public.v_currentshares OWNER TO postgres;

--
-- Name: v_shareprices; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_shareprices AS
 SELECT sp.shareid,
    sp.price,
    sp.pricedate,
    vcs.sharedesc
   FROM ("ShareDetails".shareprices sp
     JOIN "ShareDetails".v_currentshares vcs ON ((sp.shareid = vcs.shareid)))
  ORDER BY vcs.sharedesc, sp.pricedate DESC;


ALTER VIEW public.v_shareprices OWNER TO postgres;

--
-- Name: vv_curentshares; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vv_curentshares AS
 SELECT shareid,
    sharedesc,
    sharetickerid,
    currentprice AS "Last Price"
   FROM "ShareDetails".shares
  WHERE (currentprice > (0)::numeric)
  ORDER BY sharedesc;


ALTER VIEW public.vv_curentshares OWNER TO postgres;

--
-- Data for Name: customerproducts; Type: TABLE DATA; Schema: CustomerDetails; Owner: postgres
--

COPY "CustomerDetails".customerproducts (customerfinancialproductid, customerid, financialproductid, amounttocollect, frequency, lastcollected, lascollection, renewable) FROM stdin;
1	1	1	$200.00	1	2021-08-31 00:00:00	2031-08-31 00:00:00	f
2	1	2	$50.00	1	2023-08-24 00:00:00	2025-03-24 00:00:00	f
3	2	4	$150.00	3	2023-08-20 00:00:00	2025-08-20 00:00:00	t
4	3	3	$500.00	0	2023-08-24 00:00:00	2025-08-24 00:00:00	t
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: CustomerDetails; Owner: postgres
--

COPY "CustomerDetails".customers (customerid, customertitleid, customerfirstname, customerotherinitials, customerlastname, addressid, accountnumber, accounttypeid, clearbalance, unclearbalance, dateadded) FROM stdin;
5	1	Brust	Andrew	J.	133	18176111       	1	$200.00	$2.00	2026-09-21
6	3	Lobel	Leonardo	B.	145	53431993       	1	$437.97	-$10.56	2026-09-21
8	2	Julie	A	Dewson	2134	81625422       	1	$53.32	-$12.21	2026-09-21
9	1	Kirsty	\N	McGlee	4312	96565334       	1	$1,276.32	$0.00	2026-09-21
7	3	Bernie	I	McGee	314	65368765       	1	$431,122.00	$0.00	2026-09-21
2	2	Jane	JD	Dyson	444333	222-233        	124	$60.00	$20.00	2026-09-21
10	1	Henry	\N	Williams	431	22 August 2025 	1	$0.00	$0.00	2026-09-22
11	1	Julie	A	Dewson	643	ss865          	7	$0.00	$0.00	2026-09-22
1	1	John	JD	Dyson	555444	332-233        	123	$237.97	$10.00	2026-09-21
\.


--
-- Data for Name: financialproducts; Type: TABLE DATA; Schema: CustomerDetails; Owner: postgres
--

COPY "CustomerDetails".financialproducts (productid, productname) FROM stdin;
1	Regular Savings
2	Bonds Account
3	Share Account
4	Life Insurance
\.


--
-- Data for Name: shareprices; Type: TABLE DATA; Schema: ShareDetails; Owner: postgres
--

COPY "ShareDetails".shareprices (sharepriceid, shareid, price, pricedate) FROM stdin;
1	1	2.15500	2023-08-01 10:10:00
2	1	2.21250	2023-08-01 10:12:00
3	1	2.41750	2023-08-01 10:16:00
4	2	41.10000	2023-08-01 10:10:00
5	2	45.20000	2023-08-03 10:10:00
6	2	43.22000	2023-08-02 10:10:00
\.


--
-- Data for Name: shares; Type: TABLE DATA; Schema: ShareDetails; Owner: postgres
--

COPY "ShareDetails".shares (shareid, sharedesc, sharetickerid, currentprice) FROM stdin;
1	ACME'S HOMEBAKE COOKIES INC	AHCI	2.34125
2	My secret company'S BANK INC	BFD	3.50000
3	FAT-BELLY.COM	FBC	45.20000
4	NetRadio INC	NRI	29.79000
5	Texas Oil Industries	TOI	0.45550
6	London Bridge Club	LBC	1.46000
7	FAT-BELLY.COM	FBC	45.20000
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: TransactionDetails; Owner: postgres
--

COPY "TransactionDetails".transactions (transactionid, customerid, transactiontype, dateentered, amount, notes, referencedetails, relatedproductid, relatedshareid) FROM stdin;
1	1	1	2023-08-01 00:00:00	100.00000	\N	\N	1	\N
2	1	1	2023-08-03 00:00:00	75.67000	\N	\N	1	\N
3	1	2	2023-08-05 00:00:00	35.20000	\N	\N	1	\N
4	1	2	2023-08-06 00:00:00	20.00000	\N	\N	1	\N
7	1	3	2026-09-22 00:00:00	200.00000	\N	\N	1	\N
8	1	3	2026-09-22 00:00:00	200.00000	\N	\N	1	\N
9	1	3	2026-09-22 00:00:00	200.00000	\N	\N	1	\N
\.


--
-- Data for Name: transactiontypes; Type: TABLE DATA; Schema: TransactionDetails; Owner: postgres
--

COPY "TransactionDetails".transactiontypes (transactiontypesid, transactiondescription, credittype, affectcashbalance) FROM stdin;
1	proc+	t	t
2	proc-	f	t
\.


--
-- Name: customerproducts_customerfinancialproductid_seq; Type: SEQUENCE SET; Schema: CustomerDetails; Owner: postgres
--

SELECT pg_catalog.setval('"CustomerDetails".customerproducts_customerfinancialproductid_seq', 4, true);


--
-- Name: customers_customerid_seq; Type: SEQUENCE SET; Schema: CustomerDetails; Owner: postgres
--

SELECT pg_catalog.setval('"CustomerDetails".customers_customerid_seq', 11, true);


--
-- Name: shareprices_sharepriceid_seq; Type: SEQUENCE SET; Schema: ShareDetails; Owner: postgres
--

SELECT pg_catalog.setval('"ShareDetails".shareprices_sharepriceid_seq', 6, true);


--
-- Name: shares_shareid_seq; Type: SEQUENCE SET; Schema: ShareDetails; Owner: postgres
--

SELECT pg_catalog.setval('"ShareDetails".shares_shareid_seq', 7, true);


--
-- Name: transactions_transactionid_seq; Type: SEQUENCE SET; Schema: TransactionDetails; Owner: postgres
--

SELECT pg_catalog.setval('"TransactionDetails".transactions_transactionid_seq', 9, true);


--
-- Name: transactiontypes_transactiontypesid_seq; Type: SEQUENCE SET; Schema: TransactionDetails; Owner: postgres
--

SELECT pg_catalog.setval('"TransactionDetails".transactiontypes_transactiontypesid_seq', 2, true);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: CustomerDetails; Owner: postgres
--

ALTER TABLE ONLY "CustomerDetails".customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customerid);


--
-- Name: customerproducts pk_customersproducts; Type: CONSTRAINT; Schema: CustomerDetails; Owner: postgres
--

ALTER TABLE ONLY "CustomerDetails".customerproducts
    ADD CONSTRAINT pk_customersproducts PRIMARY KEY (customerfinancialproductid);


--
-- Name: shares shareid_key; Type: CONSTRAINT; Schema: ShareDetails; Owner: postgres
--

ALTER TABLE ONLY "ShareDetails".shares
    ADD CONSTRAINT shareid_key UNIQUE (shareid);


--
-- Name: transactiontypes pk_transactiontypes; Type: CONSTRAINT; Schema: TransactionDetails; Owner: postgres
--

ALTER TABLE ONLY "TransactionDetails".transactiontypes
    ADD CONSTRAINT pk_transactiontypes PRIMARY KEY (transactiontypesid);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: TransactionDetails; Owner: postgres
--

ALTER TABLE ONLY "TransactionDetails".transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transactionid);


--
-- Name: ix_customers_customerid; Type: INDEX; Schema: CustomerDetails; Owner: postgres
--

CREATE UNIQUE INDEX ix_customers_customerid ON "CustomerDetails".customers USING btree (customerid);


--
-- Name: ix_customersproducts; Type: INDEX; Schema: CustomerDetails; Owner: postgres
--

CREATE INDEX ix_customersproducts ON "CustomerDetails".customerproducts USING btree (customerid);


--
-- Name: ix_shareprices; Type: INDEX; Schema: ShareDetails; Owner: postgres
--

CREATE UNIQUE INDEX ix_shareprices ON "ShareDetails".shareprices USING btree (shareid, pricedate DESC, price);


--
-- Name: ix_transactions_ttypes; Type: INDEX; Schema: TransactionDetails; Owner: postgres
--

CREATE INDEX ix_transactions_ttypes ON "TransactionDetails".transactions USING btree (transactiontype);


--
-- Name: ix_transactiontypes; Type: INDEX; Schema: TransactionDetails; Owner: postgres
--

CREATE UNIQUE INDEX ix_transactiontypes ON "TransactionDetails".transactiontypes USING btree (transactiontypesid);

ALTER TABLE "TransactionDetails".transactiontypes CLUSTER ON ix_transactiontypes;


--
-- Name: transactions tg_instransactions; Type: TRIGGER; Schema: TransactionDetails; Owner: postgres
--

CREATE TRIGGER tg_instransactions AFTER INSERT ON "TransactionDetails".transactions REFERENCING NEW TABLE AS new FOR EACH ROW EXECUTE FUNCTION "CustomerDetails".fn_instransactions();


--
-- Name: transactions fk_transactions_shared; Type: FK CONSTRAINT; Schema: TransactionDetails; Owner: postgres
--

ALTER TABLE ONLY "TransactionDetails".transactions
    ADD CONSTRAINT fk_transactions_shared FOREIGN KEY (relatedshareid) REFERENCES "ShareDetails".shares(shareid);


--
-- Name: v_custfinproducts; Type: MATERIALIZED VIEW DATA; Schema: CustomerDetails; Owner: postgres
--

REFRESH MATERIALIZED VIEW "CustomerDetails".v_custfinproducts;


--
-- PostgreSQL database dump complete
--

\unrestrict r2Op80XHn44d5CatT1Gw3FisMVAoAYvq6dHgSMJgDrQphy3UIFfobe3yytCK7SV

