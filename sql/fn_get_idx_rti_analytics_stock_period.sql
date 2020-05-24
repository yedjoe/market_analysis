CREATE OR REPLACE FUNCTION public.fn_get_idx_rti_analytics_stock_period()
RETURNS TABLE(
	stock_sid		uuid,
	stock_code		varchar(5),
	period_sid		uuid,
	period_value	varchar(255)
)
LANGUAGE plpgsql
AS $function$
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
$function$;
