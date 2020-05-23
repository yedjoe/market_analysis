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