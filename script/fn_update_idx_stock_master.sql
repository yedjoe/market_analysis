CREATE OR REPLACE FUNCTION public."fn_update_idx_stock_master"(
	in_response_json	json
)
RETURNS void
LANGUAGE plpgsql
AS $function$
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
$function$;