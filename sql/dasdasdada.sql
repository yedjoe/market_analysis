SELECT
	RAW.report_date,
	CASE
		WHEN RAW.total_asset_multiplier = 'M' THEN RAW.total_asset * 1000000
		WHEN RAW.total_asset_multiplier = 'B' THEN RAW.total_asset * 1000000000
		WHEN RAW.total_asset_multiplier = 'T' THEN RAW.total_asset * 10000000000000
		END																				AS total_asset	
FROM (
	SELECT
		to_date(substring(upper(trim(t."report_date")), '(\d{2}-[A-Z]{3}-\d{4})'), 'DD-MON-YYYY')	AS report_date,
		regexp_replace(trim(t."total_asset"), '\D', '', 'g')::numeric								AS total_asset,
		substring(trim(t."total_asset"), '[A-Z]')													AS total_asset_multiplier	
	FROM unnest(
		ARRAY[
			'&nbsp; (in Rp):31-Mar-2020',
			'31-Dec-2019',
			'31-Dec-2018',
			'31-Dec-2017',
			'31-Dec-2016',
			'31-Dec-2015'
		],
		ARRAY[
			'29,218,599 M',
			'26,974,124 M',
			'26,856,967 M',
			'24,935,426 M',
			'24,226,122 M',
			'21,512,371 M'
		]
	) AS t("report_date", "total_asset")
) RAW;



SELECT *
FROM
	json_to_recordset(
		'[{"year":"&nbsp; (in Rp):31-Dec-2019","net_income":"286,684 M"},{"year":"31-Dec-2018","net_income":"342,536 M"},{"year":"31-Dec-2017","net_income":"455,635 M"},{"year":"31-Dec-2016","net_income":"410,154 M"}]'
	) AS t(
		report_date varchar,
		net_income varchar
	);
