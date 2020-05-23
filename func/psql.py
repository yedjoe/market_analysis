from os.path import join
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine


# Variable
DB_URL: str = 'postgresql+psycopg2://market_analysis:market_analysis@localhost:5432/db_market_analysis'
SCRIPT_PATH: str = join(Path(__file__).parent.absolute(), '..', 'script')

class PSQL:
    __db_engine: Engine = create_engine(DB_URL)

    def fn_exporter(self):
        with self.__db_engine.connect() as db_con:
            for proname, prosrc in db_con.execute(
                '''
                    SELECT  proname, prosrc
                    FROM    pg_catalog.pg_namespace n
                    JOIN    pg_catalog.pg_proc p
                    ON      pronamespace = n.oid
                    WHERE   nspname = %s
                        AND proname LIKE %s;
                ''',
                ('public', 'fn_%')
            ).fetchall():
                with open(join(SCRIPT_PATH, f'{proname}.sql'), 'w+') as f:
                    f.write(prosrc.strip())

