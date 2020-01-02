import psycopg2


SCHEMA_NAME = 'public'
TABLE_NAME = 'mst_stock'

db_conn = psycopg2.connect(
    host='satao.db.elephantsql.com',
    port=5432,
    dbname='xgpbnhoy',
    user='xgpbnhoy',
    password='DTAm6UYROwh1iDRZstKN1hXyJlAgC7-s'
)

db_cursor = db_conn.cursor()

selector_query = f'''
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = '{SCHEMA_NAME}'
        AND table_name = '{TABLE_NAME}';
'''

db_cursor.execute(selector_query)

print(tuple(map(lambda x: x[0], db_cursor.fetchall())))

db_cursor.close()