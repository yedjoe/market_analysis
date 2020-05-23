BEGIN
		INSERT INTO public."tb_trx_stock_kpi"(kpi_alias_sid, period_sid, stock_sid, kpi_value)
		SELECT
			KPI.kpi_alias_sid,
			in_period_sid,
			in_stock_sid,
			trim("NEW"."kpi_value")		AS kpi_value
		FROM unnest(
			in_kpi_alias_ids,
			in_kpi_values
		) AS "NEW"("kpi_alias_id", "kpi_value")
		INNER JOIN public."tb_mst_kpi_alias" KPI ON
			"NEW"."kpi_alias_id" = KPI.kpi_alias_id;
	END;