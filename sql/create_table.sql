CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public."tb_mst_config_category" (
	config_category_sid	uuid DEFAULT uuid_generate_v4(),
	config_category_id	varchar(255) UNIQUE NOT NULL,
	PRIMARY KEY(config_category_sid)
);

SELECT * FROM public."tb_mst_config_category";
INSERT INTO public."tb_mst_config_category"(config_category_id)
VALUES ('HTTP_REQ_METHOD');
INSERT INTO public."tb_mst_config_category"
VALUES
	(UUID('58e3a196-57b3-47fb-9b3b-5f45ea0228e3'),	'CURRENCY'),
	(UUID('1224dc0a-dc02-419c-8feb-7fbad457e43e'),	'STOCK_EXCHANGE'),
	(UUID('0863ae0a-b0f1-429b-af4f-1b7317eac75f'),	'LISTING_BOARD'),
	(UUID('fb4eb5c5-e700-4c1c-bc6e-67e487cd3776'),	'KPI_VALUE_TYPE'),
	(UUID('54efd3a0-5879-4cbe-9695-02812034427b'),	'SOURCE');


CREATE TABLE IF NOT EXISTS public."tb_mst_config" (
	config_sid			uuid DEFAULT uuid_generate_v4(),
	config_category_sid	uuid REFERENCES public."tb_mst_config_category"(config_category_sid) NOT NULL,
	config_id			varchar(255) NOT NULL,
	config_val			varchar(255) NOT NULL,
	"description"		varchar(255),
	PRIMARY KEY(config_sid),
	UNIQUE(config_id)
);
DROP TABLE public."tb_mst_config";
SELECT * FROM public."tb_mst_config";
INSERT INTO public."tb_mst_config"(config_category_sid, config_id, config_val)
VALUES
	(UUID('54efd3a0-5879-4cbe-9695-02812034427b'), 'GET', 'GET'),
	(UUID('54efd3a0-5879-4cbe-9695-02812034427b'), 'POST', 'POST');
INSERT INTO public."tb_mst_config"
VALUES
	(UUID('f7afce44-09d6-4fc2-ac74-5320dcad428d'),	UUID('58e3a196-57b3-47fb-9b3b-5f45ea0228e3'),	'IDR',		'IDR',			NULL),
	(UUID('939c76aa-04e8-44c7-adaf-442b393a5c1d'),	UUID('1224dc0a-dc02-419c-8feb-7fbad457e43e'),	'IDX',		'IDX',			NULL),
	(UUID('3436ebf1-ab5b-4054-9784-3f5d812bd77d'),	UUID('0863ae0a-b0f1-429b-af4f-1b7317eac75f'),	'MAIN',		'Utama',		NULL),
	(UUID('6a9786ef-ee46-4833-8063-380b0c1547f6'),	UUID('0863ae0a-b0f1-429b-af4f-1b7317eac75f'),	'DEV',		'Pengembangan',	NULL),
	(UUID('f7e89c19-026d-4355-bf9a-e3265354a527'),	UUID('0863ae0a-b0f1-429b-af4f-1b7317eac75f'),	'ACCL',		'Akselerasi',	NULL),
	(UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	UUID('fb4eb5c5-e700-4c1c-bc6e-67e487cd3776'),	'RATIO',	'RATIO',		NULL),
	(UUID('884eb8a5-aec9-4359-8638-9f764f15edae'),	UUID('fb4eb5c5-e700-4c1c-bc6e-67e487cd3776'),	'AMOUNT',	'AMOUNT',		NULL),
	(UUID('760b39e9-06bb-4f31-93a8-8f568d9a618e'),	UUID('54efd3a0-5879-4cbe-9695-02812034427b'),	'GET',		'GET',			NULL),
	(UUID('90666f03-6803-4e31-b5a6-7098f06971ec'),	UUID('54efd3a0-5879-4cbe-9695-02812034427b'),	'POST',		'POST',			NULL);

CREATE TABLE IF NOT EXISTS public."tb_trx_log" (
	log_sid			uuid DEFAULT uuid_generate_v4(),
	log_type_sid	uuid REFERENCES public."tb_mst_config"(config_sid) NOT NULL,
	"description"	text,
	PRIMARY KEY(log_sid)
);

SELECT * FROM public."tb_mst_stock";
DROP TABLE public."tb_mst_stock" CASCADE;
CREATE TABLE IF NOT EXISTS public."tb_mst_stock" (
	stock_sid			uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_exchange_sid	uuid REFERENCES public."tb_mst_config"(config_sid) NOT NULL,
	listing_board_sid	uuid REFERENCES public."tb_mst_config"(config_sid),
    stock_code			varchar(5) NOT NULL,
    stock_name			varchar(255) NOT NULL,
    shares				int8,
    listing_date		timestamp,
    is_listed			boolean DEFAULT TRUE NOT NULL
);

CREATE TABLE IF NOT EXISTS public."tb_mst_kpi" (
    kpi_sid			uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id			varchar(255) UNIQUE NOT NULL,
    kpi_name		varchar(255) NOT NULL,
    value_type_sid	uuid REFERENCES public."tb_mst_config"(config_sid) NOT NULL,
    description		text
);
DROP TABLE public."tb_mst_kpi";
SELECT * FROM public."tb_mst_kpi";
INSERT INTO public."tb_mst_kpi"
VALUES
	(UUID('63966b6b-6dc9-4f37-864b-27b11553d87d'),	'PER_TTM',			'Cash Ratio (Trailing 12 Months)',						UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('e3886060-9e98-4156-ae29-2655053b9950'),	'PER_A',			'Current Ratio (Annualised)',							UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('0108b4ca-3ddd-44c4-bb4c-0494ec0483f7'),	'PSR_TTM',			'Price to Sales Ratio (Trailing 12 Months)',			UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('3e3824e1-6062-4c55-ac91-91659b108246'),	'PBVR_MRQ',			'Price to Book Value Ratio (Most Recent Quarter)',		UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('51b3e6bc-e1d9-452f-8726-56153e585e14'),	'PTBR_MRQ',			'Price to Tangible Book Ratio (Most Recent Quarter)',	UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('a30f35bb-7368-4c3d-b8fe-e39963bd2324'),	'PCFR_TTM',			'Price to Cash Flow Ratio (Trailing 12 Months)',		UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('5a374ef7-57c2-474c-8480-dac20aaecd2a'),	'DY',				'Dividend Yield',										UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('cfd57a7e-87ab-4184-b08e-895b417e6e3c'),	'DY_AVG5Y',			'Dividend Yield (5 Years Average)',						UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('518d8cbd-2230-4f3f-ad3d-2fe4ec30aeec'),	'DGR_5Y',			'Dividend Growth Rate (5 Years)',						UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('346c7e48-6ffb-4b11-9d7d-0ccff71aa71b'),	'DPR',				'Dividend Payout Ratio',								UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('24d8edf7-4b95-4031-9410-69395ba0465a'),	'QRG_YOY',			'Quarterly Revenue Growth (Year on Year)',				UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('7e9dfbf1-b6e7-4473-aca8-66a1d4163afe'),	'QRG_5Y',			'Quarterly Revenue Growth (5 Years)',					UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('f021656c-b326-4441-b159-7f06179ff916'),	'QEPSG_YOY',		'Quarterly EPS Growth (Year on Year)',					UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('dbc05805-d10f-4933-9713-65b72f909f1e'),	'QEPSG_5Y',			'Quarterly EPS Growth (5 Years)',						UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('c765dd87-46f7-4051-8e5f-9c840c64bfc1'),	'QR_MRQ',			'Quick Ratio (Most Recent Quarter)',					UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('3b912d75-ca18-494d-a729-886f826da1d9'),	'CRR_MRQ',			'Current Ratio (Most Recent Quarter)',					UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('1bfd7f84-1093-46f0-a20c-499bae476508'),	'DER_LT_MRQ',		'Long Term Debt to Equity Ratio (Most Recent Quarter)',	UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('b6951c82-92bf-4c50-94a8-dce849fe84eb'),	'DER_TOTAL_MRQ',	'Total Debt to Equity Ratio (Most Recent Quarter)',		UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('880f2fae-1332-4b91-b786-e0d950b27887'),	'GM_TTM',			'Gross Margin (Trailing 12 Months)',					UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('273d42f6-595b-4b5e-acfa-5830f347888b'),	'GM_AVG5Y',			'Gross Margin (5 Years Average)',						UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('c3c9a76b-9cc1-417f-966a-4711a02aa676'),	'OM_TTM',			'Operating Margin (Trailing 12 Months)',				UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('207e17d5-64ef-43e3-adf1-06acfabc5bad'),	'OM_AVG5Y',			'Operating Margin (5 Years Average)',					UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('88532d18-938c-424e-b5f4-a8bb3db1b9a0'),	'PPM_TTM',			'Pretax Profit Margin (Trailing 12 Months)',			UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('5419cf39-0a1e-42d4-ab19-d08696ff58f9'),	'PPM_AVG5Y',		'Pretax Profit Margin (5 Years Average)',				UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('bed020f0-107a-4710-9fb1-bc87e96856de'),	'NPM_TTM',			'Net Profit Margin (Trailing 12 Months)',				UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('edfb76b5-086b-483b-a717-1321dac8c3e2'),	'NPM_AVG5Y',		'Net Profit Margin (5 Years Average)',					UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('72cd7155-8310-49f5-92a8-96a9dc476348'),	'ROA_A',			'Return on Asset (Annualised)',							UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('dd6c9727-fcca-4110-973e-b9d839b5281a'),	'ROA_TTM',			'Return on Asset (Trailing 12 Months)',					UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('f377d8d7-6862-4508-9198-70976f4b7e37'),	'ROA_AVG5Y',		'Return on Asset (5 Years Average)',					UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('fb312af9-01c2-4ba2-aca3-4b1c1e8e9d2d'),	'ROE_A',			'Return on Equity (Annualised)',						UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('7048949d-cbde-4299-a56c-f9f643dc3977'),	'ROE_TTM',			'Return on Equity (Trailing 12 Months)',				UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL),
	(UUID('68115272-11ed-44b3-aca2-e6f09a1ea9cd'),	'ROE_AVG5Y',		'Return on Equity (5 Years Average)',					UUID('9a9861e8-9093-4786-a88e-1d5a5d5b7eae'),	NULL);

CREATE TABLE IF NOT EXISTS public."tb_mst_kpi_alias" (
    kpi_alias_sid	uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_sid		uuid REFERENCES public."tb_mst_config"(config_sid) NOT NULL,
    kpi_sid			uuid REFERENCES public."tb_mst_kpi"(kpi_sid) NOT NULL,
    kpi_alias_id	varchar(255) NOT NULL,
    kpi_alias_name	varchar(255) NOT NULL,
    description		text
);
DROP TABLE public."tb_mst_kpi_alias";
SELECT * FROM public."tb_mst_kpi_alias";
INSERT INTO public."tb_mst_kpi_alias"(source_sid, kpi_sid, kpi_alias_id, kpi_alias_name)
VALUES
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('63966b6b-6dc9-4f37-864b-27b11553d87d'),	'PER (TTM)',							'PER (TTM)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('0108b4ca-3ddd-44c4-bb4c-0494ec0483f7'),	'Price to Sales (TTM)',					'Price to Sales (TTM)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('e3886060-9e98-4156-ae29-2655053b9950'),	'PER (A)',								'PER (A)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('3e3824e1-6062-4c55-ac91-91659b108246'),	'Price to Book (MRQ)',					'Price to Book (MRQ)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('51b3e6bc-e1d9-452f-8726-56153e585e14'),	'Price to Tangible Book (MRQ)',			'Price to Tangible Book (MRQ)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('a30f35bb-7368-4c3d-b8fe-e39963bd2324'),	'Price to Cash Flow (TTM)',				'Price to Cash Flow (TTM)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('5a374ef7-57c2-474c-8480-dac20aaecd2a'),	'Dividend Yield',						'Dividend Yield'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('cfd57a7e-87ab-4184-b08e-895b417e6e3c'),	'Dividend Yield - 5 Years Avg.',		'Dividend Yield - 5 Years Avg.'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('518d8cbd-2230-4f3f-ad3d-2fe4ec30aeec'),	'Dividend 5 Years Growth Rate',			'Dividend 5 Years Growth Rate'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('346c7e48-6ffb-4b11-9d7d-0ccff71aa71b'),	'Payout Ratio',							'Payout Ratio'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('24d8edf7-4b95-4031-9410-69395ba0465a'),	'Sales vs Qtr. 1 Yr. Ago',				'Sales vs Qtr. 1 Yr. Ago'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('7e9dfbf1-b6e7-4473-aca8-66a1d4163afe'),	'Sales - 5 Yr. Growth Rate',			'Sales - 5 Yr. Growth Rate'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('f021656c-b326-4441-b159-7f06179ff916'),	'EPS vs Qtr. 1 Yr. Ago',				'EPS vs Qtr. 1 Yr. Ago'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('dbc05805-d10f-4933-9713-65b72f909f1e'),	'EPS - 5 Yr. Growth Rate',				'EPS - 5 Yr. Growth Rate'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('c765dd87-46f7-4051-8e5f-9c840c64bfc1'),	'Quick Ratio (MRQ)',					'Quick Ratio (MRQ)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('3b912d75-ca18-494d-a729-886f826da1d9'),	'Current Ratio (MRQ)',					'Current Ratio (MRQ)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('1bfd7f84-1093-46f0-a20c-499bae476508'),	'LT Debt to Equity (MRQ)',				'LT Debt to Equity (MRQ)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('b6951c82-92bf-4c50-94a8-dce849fe84eb'),	'Total Debt to Equity (MQR)',			'Total Debt to Equity (MQR)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('880f2fae-1332-4b91-b786-e0d950b27887'),	'Gross Margin (TTM)',					'Gross Margin (TTM)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('273d42f6-595b-4b5e-acfa-5830f347888b'),	'Gross Margin - 5 Yr. Avg.',			'Gross Margin - 5 Yr. Avg.'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('c3c9a76b-9cc1-417f-966a-4711a02aa676'),	'Operating Margin (TTM)',				'Operating Margin (TTM)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('207e17d5-64ef-43e3-adf1-06acfabc5bad'),	'Operating Margin - 5 Yr. Avg.',		'Operating Margin - 5 Yr. Avg.'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('88532d18-938c-424e-b5f4-a8bb3db1b9a0'),	'Pre-tax Margin (TTM)',					'Pre-tax Margin (TTM)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('5419cf39-0a1e-42d4-ab19-d08696ff58f9'),	'Pre-tax Margin - 5 Yr. Avg.',			'Pre-tax Margin - 5 Yr. Avg.'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('bed020f0-107a-4710-9fb1-bc87e96856de'),	'Net Profit Margin (TTM)',				'Net Profit Margin (TTM)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('edfb76b5-086b-483b-a717-1321dac8c3e2'),	'Net Profit Margin (5 Years Average)',	'Net Profit Margin (5 Years Average)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('dd6c9727-fcca-4110-973e-b9d839b5281a'),	'Return of Assets (TTM)',				'Return of Assets (TTM)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('f377d8d7-6862-4508-9198-70976f4b7e37'),	'Return of Assets - 5 Yr. Avg',			'Return of Assets - 5 Yr. Avg'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('7048949d-cbde-4299-a56c-f9f643dc3977'),	'Return of Equity (TTM)',				'Return of Equity (TTM)'),
	(UUID('33000643-e752-4f20-914b-0a10a93422e2'),	UUID('68115272-11ed-44b3-aca2-e6f09a1ea9cd'),	'Return of Equity - 5 Yr. Avg',			'Return of Equity - 5 Yr. Avg');
UPDATE public."tb_mst_kpi_alias"
SET kpi_alias_id = 'Net Profit Margin - 5 Yr. Avg.'
WHERE kpi_alias_sid = '710c7b21-ee99-4690-b8b3-3cf8e25a4132';



CREATE TABLE IF NOT EXISTS public."tb_mst_period" (
    period_sid		uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_sid		uuid REFERENCES public."tb_mst_config"(config_sid) NOT NULL,
    period_value	varchar(20) NOT NULL,
    period_date		date NOT NULL
);
SELECT * FROM public."tb_mst_period";
DROP TABLE public."tb_mst_period";

SELECT * FROM public."tb_trx_stock_kpi";
UPDATE public."tb_trx_stock_kpi" SET kpi_value = NULL WHERE upper(kpi_value) = 'NA';
DROP TABLE public."tb_trx_stock_kpi";
CREATE TABLE IF NOT EXISTS public."tb_trx_stock_kpi" (
    kpi_trx_sid		uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_alias_sid	uuid REFERENCES public."tb_mst_kpi_alias"(kpi_alias_sid) NOT NULL,
    period_sid		uuid REFERENCES public."tb_mst_period"(period_sid) NOT NULL,
    stock_sid		uuid REFERENCES public."tb_mst_stock"(stock_sid) NOT NULL,
    kpi_value		varchar(255),
    created_on		timestamp DEFAULT now() NOT NULL
);
SELECT
	STK.stock_code,
	PRD.period_value,
	KPI.kpi_id,
	CASE
		WHEN (CFG1.config_id = 'RATIO') OR (CFG1.config_id = 'AMOUNT') THEN SKP.kpi_value::numeric
	END AS kpi_value,
	KPI.kpi_name
FROM public."tb_trx_stock_kpi" SKP
left OUTER JOIN public."tb_mst_stock" STK ON
	SKP.stock_sid = STK.stock_sid
left OUTER JOIN public."tb_mst_period" PRD ON
	SKP.period_sid = PRD.period_sid
left OUTER JOIN public."tb_mst_kpi_alias" ALS ON
	SKP.kpi_alias_sid = ALS.kpi_alias_sid
left OUTER JOIN public."tb_mst_kpi" KPI ON
	ALS.kpi_sid = KPI.kpi_sid
left OUTER JOIN public."tb_mst_config" CFG1 ON
	KPI.value_type_sid = CFG1.config_sid
ORDER BY 
	STK.stock_code,
	PRD.period_value;