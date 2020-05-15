CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public."tb_mst_config_category" (
	config_category_sid	uuid DEFAULT uuid_generate_v4(),
	config_category_id	varchar(255) UNIQUE NOT NULL,
	PRIMARY KEY(config_category_sid)
);

SELECT * FROM public."tb_mst_config";
CREATE TABLE IF NOT EXISTS public."tb_mst_config" (
	config_sid			uuid DEFAULT uuid_generate_v4(),
	config_category_sid	uuid REFERENCES public."tb_mst_config_category"(config_category_sid) NOT NULL,
	config_id			varchar(255) NOT NULL,
	config_val			varchar(255) NOT NULL,
	"description"		varchar(255),
	PRIMARY KEY(config_sid),
	UNIQUE(config_id)
);

CREATE TABLE IF NOT EXISTS public."tb_trx_log" (
	log_sid			uuid DEFAULT uuid_generate_v4(),
	log_type_sid	uuid REFERENCES public."tb_mst_config"(config_sid) NOT NULL,
	"description"	text,
	PRIMARY KEY(log_sid)
);

SELECT * FROM public."tb_mst_stock";
DROP TABLE public."tb_mst_stock" CASCADE;
CREATE TABLE IF NOT EXISTS public."tb_mst_stock" (
	stock_sid			uuid DEFAULT uuid_generate_v4(),
    stock_exchange_sid	uuid REFERENCES public."tb_mst_config"(config_sid) NOT NULL,
	listing_board_sid	uuid REFERENCES public."tb_mst_config"(config_sid),
    stock_code			varchar(5) NOT NULL,
    stock_name			varchar(255) NOT NULL,
    shares				int8,
    listing_date		timestamp,
    is_listed			boolean DEFAULT TRUE NOT NULL,
    PRIMARY KEY(stock_sid)
)

DROP TABLE public."tb_trx_stock_kpi";
CREATE TABLE IF NOT EXISTS public."tb_trx_stock_kpi" (
    trx_sid					uuid DEFAULT uuid_generate_v4(),
    stock_sid				uuid REFERENCES public."tb_mst_stock"(stock_sid) NOT NULL,
    "year"					int NOT NULL,
    total_asset_currency	char(3) NOT NULL,
    total_asset				decimal(23,2),
    total_equity_currency	char(3) NOT NULL,
    total_equity			decimal(23,2),
    car						decimal(10,4),
    npl						decimal(10,4),
    net_income_currency		char(3) NOT NULL,
    net_income				decimal(23,2),
    eps						int,
    dividend_yield			decimal(10,4),
    per						decimal(10,4),
    psr						decimal(10,4),
    pbvr					decimal(10,4),
    pcfr					decimal(8,2),
    roe						decimal(10,4),
    roa						decimal(10,4),
    der						decimal(10,4),
    cr						decimal(10,4),
    qr						decimal(10,4),
    crr						decimal(10,4),
    latest_update			timestamp,
    PRIMARY KEY(trx_sid)
);
