from json import dumps
from typing import Any, Dict, List

from requests import Response, Session
from requests.adapters import HTTPAdapter
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine


# Variable
DB_URL: str = 'postgresql+psycopg2://market_analysis:market_analysis@localhost:5432/db_market_analysis'

class StockMarket:
    __db_engine: Engine = create_engine(DB_URL)

    def __init__(self):
        pass

    def __get_idx_stocks(self, session: Session, start: int=0, length: int=100) -> List[Dict[str, Any]]:
        response: Response = session.get(
            'https://www.idx.co.id/umbraco/Surface/StockData/GetSecuritiesStock',
            params={ 'start': start * length, 'length': length }
        )

        if response.status_code == 200:
            return response.json()['data']

        return []

    def update_idx_stock_master(self):
        session: Session = Session()
        session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/537.36'
        })
        session.mount('https://', HTTPAdapter(max_retries=200))

        json_data: List[Dict[str, Any]] = self.__get_idx_stocks(session)

        if len(json_data) > 0:
            with self.__db_engine.connect().execution_options(autocommit=True) as db_con:
                i: int = 1
                while len(json_data) > 0:
                    db_con.execute('SELECT public."fn_update_idx_stock_master"(%s);', (dumps(json_data)))
                    json_data = self.__get_idx_stocks(session, i)

                    i += 1
