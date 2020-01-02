--CREATE EXTENSION IF NOT EXISTS "uuid_min_ossp";

SET timezone = 'Asia/Jakarta';

DROP TABLE public.mst_stock;

CREATE TABLE public.mst_stock (
    sid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    stock_code varchar(4) NOT NULL,
    stock_name varchar(100) NOT NULL,
    stock_exchange_code varchar(5) NOT NULL,
    listing_board varchar(15) NULL,
    total_asset_y_currency bpchar(3) NOT NULL,
    total_asset_y numeric(23,2) NULL,
    total_asset_y_min_1_currency bpchar(3) NOT NULL,
    total_asset_y_min_1 numeric(23,2) NULL,
    total_asset_y_min_2_currency bpchar(3) NOT NULL,
    total_asset_y_min_2 numeric(23,2) NULL,
    total_asset_y_min_3_currency bpchar(3) NOT NULL,
    total_asset_y_min_3 numeric(23,2) NULL,
    total_equity_y_currency bpchar(3) NOT NULL,
    total_equity_y numeric(23,2) NULL,
    total_equity_y_min_1_currency bpchar(3) NOT NULL,
    total_equity_y_min_1 numeric(23,2) NULL,
    total_equity_y_min_2_currency bpchar(3) NOT NULL,
    total_equity_y_min_2 numeric(23,2) NULL,
    total_equity_y_min_3_currency bpchar(3) NOT NULL,
    total_equity_y_min_3 numeric(23,2) NULL,
    car_y numeric(10, 4) NULL,
    car_y_min_1 numeric(10, 4) NULL,
    car_y_min_2 numeric(10, 4) NULL,
    car_y_min_3 numeric(10, 4) NULL,
    npl_y numeric(10, 4) NULL,
    npl_y_min_1 numeric(10, 4) NULL,
    npl_y_min_2 numeric(10, 4) NULL,
    npl_y_min_3 numeric(10, 4) NULL,
    net_income_y_currency bpchar(3) NOT NULL,
    net_income_y numeric(23,2) NULL,
    net_income_y_min_1_currency bpchar(3) NOT NULL,
    net_income_y_min_1 numeric(23,2) NULL,
    net_income_y_min_2_currency bpchar(3) NOT NULL,
    net_income_y_min_2 numeric(23,2) NULL,
    net_income_y_min_3_currency bpchar(3) NOT NULL,
    net_income_y_min_3 numeric(23,2) NULL,
    eps_y int2 NULL,
    eps_y_min_1 int2 NULL,
    eps_y_min_2 int2 NULL,
    eps_y_min_3 int2 NULL,
    dividend_yield numeric(10, 4) NULL,
    per numeric(10, 4) NULL,
    psr numeric(10, 4) NULL,
    pbvr numeric(10, 4) NULL,
    pcfr numeric(8,2) NULL,    
    roe numeric(10, 4) NULL,
    roa numeric(10, 4) NULL,
    der numeric(10, 4) NULL,
    cr numeric(10, 4) NULL,
    qr numeric(10, 4) NULL,
    crr numeric(10,4) NULL, 
    latest_update timestamptz NULL,
    listed_status boolean DEFAULT TRUE NOT NULL
);