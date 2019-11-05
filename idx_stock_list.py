from math import ceil

from psycopg2 import connect
from requests import get


TABLE_NAME = 'public.mst_stock'
STEPS = 100

json_response = get(
    'https://www.idx.co.id/umbraco/Surface/StockData/GetSecuritiesStock',
    {
        'start': 0,
        'length': STEPS
    }
).json()

ceiledTotalRecords = int(ceil(json_response['recordsTotal'] / 100.0)) * 100

db_conn = connect(
    host='satao.db.elephantsql.com',
    port=5432,
    dbname='xgpbnhoy',
    user='xgpbnhoy',
    password='DTAm6UYROwh1iDRZstKN1hXyJlAgC7-s'
)

db_cursor = db_conn.cursor()

for step_idx in range(1, int(ceiledTotalRecords / STEPS) + 1):
    for stock in json_response['data']:
        print(stock["Code"])

        db_cursor.execute(f'''
            SELECT stock_code
            FROM {TABLE_NAME}
            WHERE stock_code = \'{stock["Code"]}\';
        ''')

        if db_cursor.fetchone() == None:
            db_cursor.execute(f'''
                INSERT INTO {TABLE_NAME} (
                    stock_code,
                    stock_name,
                    stock_exchange_code,
                    listing_board,
                    total_asset_y_min_3_currency,
                    total_asset_y_min_2_currency,
                    total_asset_y_min_1_currency,
                    total_asset_y_currency,
                    total_equity_y_min_3_currency,
                    total_equity_y_min_2_currency,
                    total_equity_y_min_1_currency,
                    total_equity_y_currency,
                    net_income_y_min_3_currency,
                    net_income_y_min_2_currency,
                    net_income_y_min_1_currency,
                    net_income_y_currency,
                    latest_update
                )
                VALUES (
                    \'{stock["Code"].upper()}\',
                    \'{stock["Name"].title()}\',
                    \'IDX\',
                    \'{stock["ListingBoard"].title()}\',
                    \'IDR\',
                    \'IDR\',
                    \'IDR\',
                    \'IDR\',
                    \'IDR\',
                    \'IDR\',
                    \'IDR\',
                    \'IDR\',
                    \'IDR\',
                    \'IDR\',
                    \'IDR\',
                    \'IDR\',
                    NOW()
                );
            ''')
        # else:
        #     db_cursor.execute(
        #         'UPDATE public.mst_stock SET stock_code = %s, stock_name = %s, listing_board = %s WHERE stock_code = %s AND stock_exchange_code = \'IDX\';',
        #         (stock['Code'].upper(), stock['Name'].title(), stock['ListingBoard'].title(), stock['Code'])
        #     )

    db_conn.commit()

    json_response = get(f'https://www.idx.co.id/umbraco/Surface/StockData/GetSecuritiesStock?start={step_idx * STEPS}&length={STEPS}').json()

db_cursor.close()
db_conn.close()