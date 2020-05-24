--
-- PostgreSQL database dump
--

-- Dumped from database version 12.2
-- Dumped by pg_dump version 12.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: tablefunc_crosstab_kpi; Type: TYPE; Schema: public; Owner: market_analysis
--

CREATE TYPE public.tablefunc_crosstab_kpi AS (
	kpi_trx_sid uuid,
	per_ttm character varying(255),
	per_a character varying(255),
	psr_ttm character varying(255),
	pbvr_mrq character varying(255),
	ptbr_mrq character varying(255),
	pcfr_ttm character varying(255),
	dy character varying(255),
	dy_avg5y character varying(255),
	dgr_5y character varying(255),
	dpr character varying(255),
	qrg_yoy character varying(255),
	qrg_5y character varying(255),
	qepsg_yoy character varying(255),
	qepsg_5y character varying(255),
	qr_mrq character varying(255),
	crr_mrq character varying(255),
	der_lt_mrq character varying(255),
	der_total_mrq character varying(255),
	gm_ttm character varying(255),
	gm_avg5y character varying(255),
	om_ttm character varying(255),
	om_avg5y character varying(255),
	ppm_ttm character varying(255),
	ppm_avg5y character varying(255),
	npm_ttm character varying(255),
	npm_avg5y character varying(255),
	roa_a character varying(255),
	roa_ttm character varying(255),
	roa_avg5y character varying(255),
	roe_a character varying(255),
	roe_ttm character varying(255),
	roe_avg5y character varying(255)
);


ALTER TYPE public.tablefunc_crosstab_kpi OWNER TO market_analysis;

--
-- Name: crosstab_kpi(text); Type: FUNCTION; Schema: public; Owner: market_analysis
--

CREATE FUNCTION public.crosstab_kpi(text) RETURNS SETOF public.tablefunc_crosstab_kpi
    LANGUAGE c STABLE STRICT
    AS '$libdir/tablefunc', 'crosstab';


ALTER FUNCTION public.crosstab_kpi(text) OWNER TO market_analysis;

--
-- Name: fn_get_config_sid(character varying, character varying); Type: FUNCTION; Schema: public; Owner: market_analysis
--

CREATE FUNCTION public.fn_get_config_sid(in_config_category_id character varying, in_config_id character varying) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
    BEGIN
	    RETURN (
			SELECT CFG.config_sid
			FROM public."tb_mst_config" CFG
				LEFT OUTER JOIN public."tb_mst_config_category" CAT ON CFG.config_category_sid = CAT.config_category_sid
			WHERE CAT.config_category_id = in_config_category_id
				AND CFG.config_id = in_config_id
		);
	END;
$$;


ALTER FUNCTION public.fn_get_config_sid(in_config_category_id character varying, in_config_id character varying) OWNER TO market_analysis;

--
-- Name: fn_get_configs(character varying); Type: FUNCTION; Schema: public; Owner: market_analysis
--

CREATE FUNCTION public.fn_get_configs(in_config_category_id character varying) RETURNS TABLE(config_sid uuid, config_category_id character varying, config_id character varying, config_val character varying, description character varying)
    LANGUAGE plpgsql
    AS $$
    BEGIN
	    RETURN QUERY
			SELECT CFG.config_sid,
				CAT.config_category_id,
				CFG.config_id,
				CFG.config_val,
				CFG.description
			FROM public."tb_mst_config" CFG
				LEFT OUTER JOIN public."tb_mst_config_category" CAT ON CFG.config_category_sid = CAT.config_category_sid
			WHERE CAT.config_category_id = in_config_category_id;
	END;
$$;


ALTER FUNCTION public.fn_get_configs(in_config_category_id character varying) OWNER TO market_analysis;

--
-- Name: fn_get_idx_rti_analytics_stock_period(); Type: FUNCTION; Schema: public; Owner: market_analysis
--

CREATE FUNCTION public.fn_get_idx_rti_analytics_stock_period() RETURNS TABLE(stock_sid uuid, stock_code character varying, period_sid uuid, period_value character varying)
    LANGUAGE plpgsql
    AS $$
	DECLARE
		var_config_category_id	varchar(255) := 'STOCK_EXCHANGE';
		var_stock_exchange_id	varchar(255) := 'IDX';
	BEGIN
		RETURN QUERY
		SELECT DISTINCT ON
			(
				STK.stock_code,
				PRD.period_value
			)
			STK.stock_sid,
			STK.stock_code,
			PRD.period_sid,
			PRD.period_value
		--	substring(upper(STK.stock_name), 'BANK') IS NOT NULL	AS is_bank
		FROM public."tb_mst_stock" STK
		CROSS JOIN public."tb_mst_period" PRD
		left OUTER JOIN public."tb_trx_stock_kpi" SKP ON
			STK.stock_sid = SKP.stock_sid
			AND PRD.period_sid = SKP.period_sid
		WHERE
			STK.stock_exchange_sid = (SELECT public."fn_get_config_sid"(var_config_category_id, var_stock_exchange_id))
			AND SKP.kpi_trx_sid IS NULL
		ORDER BY
			STK.stock_code,
			PRD.period_value;
	END;
$$;


ALTER FUNCTION public.fn_get_idx_rti_analytics_stock_period() OWNER TO market_analysis;

--
-- Name: fn_update_idx_rti_analytics_stock_kpi(uuid, uuid, character varying[], character varying[]); Type: FUNCTION; Schema: public; Owner: market_analysis
--

CREATE FUNCTION public.fn_update_idx_rti_analytics_stock_kpi(in_period_sid uuid, in_stock_sid uuid, in_kpi_alias_ids character varying[], in_kpi_values character varying[]) RETURNS void
    LANGUAGE plpgsql
    AS $$ 	BEGIN 		INSERT INTO public."tb_trx_stock_kpi"(kpi_alias_sid, period_sid, stock_sid, kpi_value) 		SELECT 			KPI.kpi_alias_sid, 			in_period_sid, 			in_stock_sid, 			CASE trim("NEW"."kpi_value") 				WHEN 'NA' THEN NULL 				ELSE trim("NEW"."kpi_value") 			END AS kpi_value 		FROM unnest( 			in_kpi_alias_ids, 			in_kpi_values 		) AS "NEW"("kpi_alias_id", "kpi_value") 		INNER JOIN public."tb_mst_kpi_alias" KPI ON 			"NEW"."kpi_alias_id" = KPI.kpi_alias_id; 	END; $$;


ALTER FUNCTION public.fn_update_idx_rti_analytics_stock_kpi(in_period_sid uuid, in_stock_sid uuid, in_kpi_alias_ids character varying[], in_kpi_values character varying[]) OWNER TO market_analysis;

--
-- Name: fn_update_idx_stock(json); Type: FUNCTION; Schema: public; Owner: market_analysis
--

CREATE FUNCTION public.fn_update_idx_stock(in_response_json json) RETURNS void
    LANGUAGE plpgsql
    AS $$
	DECLARE
		var_config_category_id	varchar(255) := 'STOCK_EXCHANGE';
		var_stock_exchange_id	varchar(255) := 'IDX';
		var_listing_board_id	varchar(255) := 'LISTING_BOARD';
	BEGIN
		CREATE TEMPORARY TABLE IF NOT EXISTS "tb_tmp_stock"(
		    stock_exchange_sid	uuid NOT NULL,
			listing_board_sid	uuid,
		    stock_code			varchar(5) NOT NULL,
		    stock_name			varchar(255) NOT NULL,
		    shares				int8,
		    listing_date		timestamp
		);
		
		INSERT INTO "tb_tmp_stock"(
			stock_exchange_sid,
			listing_board_sid,
			stock_code,
			stock_name,
			shares,
			listing_date
		)
		SELECT
			fn_get_config_sid(var_config_category_id, var_stock_exchange_id)	AS stock_exchange_sid,
			BRD.config_sid														AS listing_board_sid,
			TMP.stock_code,
			TMP.stock_name,
			TMP.shares,
			TMP.listing_date
		FROM (
			SELECT		
				upper(trim(t."Code"))				AS stock_code,
				trim(t."Name")						AS stock_name,
				trim(t."ListingDate")::timestamp	AS listing_date,
				t."Shares"							AS shares,
				initcap(trim(t."ListingBoard"))		AS listing_board
			FROM
				json_to_recordset(in_response_json) AS t(
				    "Code"			varchar(5),
				    "Name"			varchar(255),
				    "ListingDate"	varchar(20),
				    "Shares"		int8,
				    "ListingBoard"	varchar(255)
			)
		) TMP
		left OUTER JOIN (
			SELECT config_sid, config_val FROM fn_get_configs(var_listing_board_id)
		) BRD ON
			TMP.listing_board = BRD.config_val;
		
		-- Update value for existing stock
		UPDATE public."tb_mst_stock" AS MST
		SET
			listing_board_sid = TMP.listing_board_sid,
			stock_name = TMP.stock_name,
			shares = TMP.shares,
			listing_date = TMP.listing_date
		FROM "tb_tmp_stock" TMP
		WHERE
			MST.stock_exchange_sid = TMP.stock_exchange_sid
			AND MST.stock_code = TMP.stock_code;
		
		-- Add stock if previously unavailable on master
		INSERT INTO public."tb_mst_stock"(
			stock_exchange_sid,
			listing_board_sid,
		    stock_code,
		    stock_name,
		    shares,
		    listing_date
		)
		SELECT
			TMP.stock_exchange_sid,
			TMP.listing_board_sid,
		    TMP.stock_code,
		    TMP.stock_name,
		    TMP.shares,
		    TMP.listing_date
		FROM "tb_tmp_stock" TMP
			left OUTER JOIN public."tb_mst_stock" MST ON
				TMP.stock_exchange_sid = MST.stock_exchange_sid
				AND TMP.stock_code = MST.stock_code
		WHERE MST.stock_sid IS NULL;
	
		-- Deactivate stock if exist on master, not exist on temporary table
		UPDATE public."tb_mst_stock" AS MST
		SET is_listed = FALSE
		FROM "tb_tmp_stock" TMP
		WHERE
			MST.stock_exchange_sid <> TMP.stock_exchange_sid
			AND MST.stock_code <> TMP.stock_code;
		
		DELETE FROM "tb_tmp_stock";
	END;
$$;


ALTER FUNCTION public.fn_update_idx_stock(in_response_json json) OWNER TO market_analysis;

--
-- Name: fn_update_rti_analystics_period(character varying[]); Type: FUNCTION; Schema: public; Owner: market_analysis
--

CREATE FUNCTION public.fn_update_rti_analystics_period(in_period_values character varying[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
	DECLARE
		var_source_sid	uuid := (SELECT config_sid FROM public."tb_mst_config" WHERE config_id = 'RTI_ANALYTICS');
	BEGIN
		INSERT INTO public."tb_mst_period"(source_sid, period_value, period_date)
		SELECT
			var_source_sid	AS source_sid,
			"NEW"."period_value",
			(
				date_trunc(
					'MONTH',
					format('%s-%s-1', left(trim("NEW"."period_value"), 4), right(trim("NEW"."period_value"), 1)::int * 3)::date
				) + interval '1 MONTH - 1 day'
			)::date			AS period_date
		FROM
			unnest(in_period_values) AS "NEW"("period_value")
			left outer JOIN public."tb_mst_period" PRD ON
				PRD.source_sid = var_source_sid
				AND "NEW".period_value = PRD.period_value
		WHERE PRD.period_value IS NULL;
	END;
$$;


ALTER FUNCTION public.fn_update_rti_analystics_period(in_period_values character varying[]) OWNER TO market_analysis;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: tb_mst_config; Type: TABLE; Schema: public; Owner: market_analysis
--

CREATE TABLE public.tb_mst_config (
    config_sid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    config_category_sid uuid NOT NULL,
    config_id character varying(255) NOT NULL,
    config_val character varying(255) NOT NULL,
    description character varying(255)
);


ALTER TABLE public.tb_mst_config OWNER TO market_analysis;

--
-- Name: tb_mst_config_category; Type: TABLE; Schema: public; Owner: market_analysis
--

CREATE TABLE public.tb_mst_config_category (
    config_category_sid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    config_category_id character varying(255) NOT NULL
);


ALTER TABLE public.tb_mst_config_category OWNER TO market_analysis;

--
-- Name: tb_mst_kpi; Type: TABLE; Schema: public; Owner: market_analysis
--

CREATE TABLE public.tb_mst_kpi (
    kpi_sid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    kpi_id character varying(255) NOT NULL,
    kpi_name character varying(255) NOT NULL,
    value_type_sid uuid NOT NULL,
    description text
);


ALTER TABLE public.tb_mst_kpi OWNER TO market_analysis;

--
-- Name: tb_mst_kpi_alias; Type: TABLE; Schema: public; Owner: market_analysis
--

CREATE TABLE public.tb_mst_kpi_alias (
    kpi_alias_sid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    source_sid uuid NOT NULL,
    kpi_sid uuid NOT NULL,
    kpi_alias_id character varying(255) NOT NULL,
    kpi_alias_name character varying(255) NOT NULL,
    description text
);


ALTER TABLE public.tb_mst_kpi_alias OWNER TO market_analysis;

--
-- Name: tb_mst_period; Type: TABLE; Schema: public; Owner: market_analysis
--

CREATE TABLE public.tb_mst_period (
    period_sid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    source_sid uuid NOT NULL,
    period_value character varying(20) NOT NULL,
    period_date date NOT NULL
);


ALTER TABLE public.tb_mst_period OWNER TO market_analysis;

--
-- Name: tb_mst_stock; Type: TABLE; Schema: public; Owner: market_analysis
--

CREATE TABLE public.tb_mst_stock (
    stock_sid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    stock_exchange_sid uuid NOT NULL,
    listing_board_sid uuid,
    stock_code character varying(5) NOT NULL,
    stock_name character varying(255) NOT NULL,
    shares bigint,
    listing_date timestamp without time zone,
    is_listed boolean DEFAULT true NOT NULL
);


ALTER TABLE public.tb_mst_stock OWNER TO market_analysis;

--
-- Name: tb_trx_log; Type: TABLE; Schema: public; Owner: market_analysis
--

CREATE TABLE public.tb_trx_log (
    log_sid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    log_type_sid uuid NOT NULL,
    description text
);


ALTER TABLE public.tb_trx_log OWNER TO market_analysis;

--
-- Name: tb_trx_stock_kpi; Type: TABLE; Schema: public; Owner: market_analysis
--

CREATE TABLE public.tb_trx_stock_kpi (
    kpi_trx_sid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    kpi_alias_sid uuid NOT NULL,
    period_sid uuid NOT NULL,
    stock_sid uuid NOT NULL,
    kpi_value character varying(255),
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tb_trx_stock_kpi OWNER TO market_analysis;

--
-- Name: tb_mst_config_category tb_mst_config_category_config_category_id_key; Type: CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_config_category
    ADD CONSTRAINT tb_mst_config_category_config_category_id_key UNIQUE (config_category_id);


--
-- Name: tb_mst_config_category tb_mst_config_category_pkey; Type: CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_config_category
    ADD CONSTRAINT tb_mst_config_category_pkey PRIMARY KEY (config_category_sid);


--
-- Name: tb_mst_config tb_mst_config_config_id_key; Type: CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_config
    ADD CONSTRAINT tb_mst_config_config_id_key UNIQUE (config_id);


--
-- Name: tb_mst_config tb_mst_config_pkey; Type: CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_config
    ADD CONSTRAINT tb_mst_config_pkey PRIMARY KEY (config_sid);


--
-- Name: tb_mst_kpi_alias tb_mst_kpi_alias_pkey; Type: CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_kpi_alias
    ADD CONSTRAINT tb_mst_kpi_alias_pkey PRIMARY KEY (kpi_alias_sid);


--
-- Name: tb_mst_kpi tb_mst_kpi_kpi_id_key; Type: CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_kpi
    ADD CONSTRAINT tb_mst_kpi_kpi_id_key UNIQUE (kpi_id);


--
-- Name: tb_mst_kpi tb_mst_kpi_pkey; Type: CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_kpi
    ADD CONSTRAINT tb_mst_kpi_pkey PRIMARY KEY (kpi_sid);


--
-- Name: tb_mst_period tb_mst_period_pkey; Type: CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_period
    ADD CONSTRAINT tb_mst_period_pkey PRIMARY KEY (period_sid);


--
-- Name: tb_mst_stock tb_mst_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_stock
    ADD CONSTRAINT tb_mst_stock_pkey PRIMARY KEY (stock_sid);


--
-- Name: tb_trx_log tb_trx_log_pkey; Type: CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_trx_log
    ADD CONSTRAINT tb_trx_log_pkey PRIMARY KEY (log_sid);


--
-- Name: tb_trx_stock_kpi tb_trx_stock_kpi_pkey; Type: CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_trx_stock_kpi
    ADD CONSTRAINT tb_trx_stock_kpi_pkey PRIMARY KEY (kpi_trx_sid);


--
-- Name: tb_mst_config tb_mst_config_config_category_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_config
    ADD CONSTRAINT tb_mst_config_config_category_sid_fkey FOREIGN KEY (config_category_sid) REFERENCES public.tb_mst_config_category(config_category_sid);


--
-- Name: tb_mst_kpi_alias tb_mst_kpi_alias_kpi_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_kpi_alias
    ADD CONSTRAINT tb_mst_kpi_alias_kpi_sid_fkey FOREIGN KEY (kpi_sid) REFERENCES public.tb_mst_kpi(kpi_sid);


--
-- Name: tb_mst_kpi_alias tb_mst_kpi_alias_source_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_kpi_alias
    ADD CONSTRAINT tb_mst_kpi_alias_source_sid_fkey FOREIGN KEY (source_sid) REFERENCES public.tb_mst_config(config_sid);


--
-- Name: tb_mst_kpi tb_mst_kpi_value_type_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_kpi
    ADD CONSTRAINT tb_mst_kpi_value_type_sid_fkey FOREIGN KEY (value_type_sid) REFERENCES public.tb_mst_config(config_sid);


--
-- Name: tb_mst_period tb_mst_period_source_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_period
    ADD CONSTRAINT tb_mst_period_source_sid_fkey FOREIGN KEY (source_sid) REFERENCES public.tb_mst_config(config_sid);


--
-- Name: tb_mst_stock tb_mst_stock_listing_board_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_stock
    ADD CONSTRAINT tb_mst_stock_listing_board_sid_fkey FOREIGN KEY (listing_board_sid) REFERENCES public.tb_mst_config(config_sid);


--
-- Name: tb_mst_stock tb_mst_stock_stock_exchange_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_mst_stock
    ADD CONSTRAINT tb_mst_stock_stock_exchange_sid_fkey FOREIGN KEY (stock_exchange_sid) REFERENCES public.tb_mst_config(config_sid);


--
-- Name: tb_trx_log tb_trx_log_log_type_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_trx_log
    ADD CONSTRAINT tb_trx_log_log_type_sid_fkey FOREIGN KEY (log_type_sid) REFERENCES public.tb_mst_config(config_sid);


--
-- Name: tb_trx_stock_kpi tb_trx_stock_kpi_kpi_alias_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_trx_stock_kpi
    ADD CONSTRAINT tb_trx_stock_kpi_kpi_alias_sid_fkey FOREIGN KEY (kpi_alias_sid) REFERENCES public.tb_mst_kpi_alias(kpi_alias_sid);


--
-- Name: tb_trx_stock_kpi tb_trx_stock_kpi_period_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_trx_stock_kpi
    ADD CONSTRAINT tb_trx_stock_kpi_period_sid_fkey FOREIGN KEY (period_sid) REFERENCES public.tb_mst_period(period_sid);


--
-- Name: tb_trx_stock_kpi tb_trx_stock_kpi_stock_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: market_analysis
--

ALTER TABLE ONLY public.tb_trx_stock_kpi
    ADD CONSTRAINT tb_trx_stock_kpi_stock_sid_fkey FOREIGN KEY (stock_sid) REFERENCES public.tb_mst_stock(stock_sid);


--
-- PostgreSQL database dump complete
--

