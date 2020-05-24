from json import dumps
# from operator import itemgetter
# from random import random
# from re import compile as re_compile, IGNORECASE, Match, search
from random import randint
from time import sleep
from typing import Any, Callable, Dict, List
from uuid import UUID

from bs4 import BeautifulSoup
from fake_headers import Headers
# from numpy import nan
# from pandas import DataFrame, read_html
from requests import Session
from requests.adapters import HTTPAdapter
from requests.exceptions import ConnectionError
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.sql import text

from config import DB_URL


class StockScraper:
    __db_engine: Engine = create_engine(DB_URL)
    __headers: Headers = Headers(headers=True)
    __session: Session = Session()

    def __init__(self):
        self.__session.mount('http://', HTTPAdapter(max_retries=999))
        self.__session.mount('https://', HTTPAdapter(max_retries=999))

    def __get_idx_stocks(self, start: int=0, length: int=100) -> List[Dict[str, Any]]:
        self.__session.headers.update(self.__headers.generate())

        with self.__session.get(
            'https://www.idx.co.id/umbraco/Surface/StockData/GetSecuritiesStock',
            params={ 'start': start * length, 'length': length }
        ) as response:
            return response.json()['data']

        return []

    def __update_idx_stock(self) -> None:
        json_data: List[Dict[str, Any]] = self.__get_idx_stocks()

        if len(json_data) > 0:
            with self.__db_engine.connect().execution_options(autocommit=True) as db_con:
                i: int = 1

                while len(json_data) > 0:
                    db_con.execute('SELECT public."fn_update_idx_stock"(%s);', (dumps(json_data)))
                    json_data = self.__get_idx_stocks(i)

                    i += 1

    def __update_rti_analytics_period(self) -> None:
        self.__session.headers.update(self.__headers.generate())

        with self.__session.get(
            'https://analytics2.rti.co.id/',
            params={ 'm_id': '1', 'sub_m': 's55' }
        ) as response:
            finrat_html_soup: BeautifulSoup = BeautifulSoup(response.text, 'html.parser')

        periods: map = map(
            lambda tag: tag['value'].strip(),
            finrat_html_soup \
                .select('#dtable > tr:nth-child(3) > td > form:nth-child(3) > div > div:nth-child(2) > div:nth-child(1) > table > tr > td:nth-child(1) > select > option')
        )

        del finrat_html_soup

        with self.__db_engine.connect().execution_options(autocommit=True) as db_con:
            db_con.execute(text('SELECT public."fn_update_rti_analystics_period"(:periods);'), { 'periods': list(periods) })

    def update_idx_rti_analytics_stock_kpi(self):
        self.__update_idx_stock()
        self.__update_rti_analytics_period()

        with self.__db_engine.connect() as db_con:
            period_sid: UUID
            period_value: str
            stock_sid: UUID
            stock_code: str

            for stock_sid, stock_code, period_sid, period_value in db_con.execute('SELECT * FROM public."fn_get_idx_rti_analytics_stock_period"()').fetchall():
                print('{stock_code} on {period_value}'.format(stock_code=stock_code, period_value=period_value))

                finrat_html_soup: BeautifulSoup

                while True:
                    try:
                        sleep(randint(1, 10))

                        self.__session.headers.update(self.__headers.generate())

                        finrat_html_soup = BeautifulSoup(self.__session.post(
                            'https://analytics2.rti.co.id/',
                            params={ 'm_id': '1', 'sub_m': 's55' },
                            data={
                                'comp_code': '',
                                'kode_rc1': stock_code,
                                'kode_rc2': '',
                                'kode_rc3': '',
                                'kode_rc4': '',
                                'kode_rc5': '',
                                'period_opt': period_value,
                                'stock_cb': 'on'
                            }
                        ).text, 'html.parser')

                    except ConnectionError:
                        pass

                    else:
                        break

                get_text: Callable = lambda tags: map(lambda tag: tag.find('div').getText().strip(), tags)

                kpis: map = get_text(finrat_html_soup.select('#form1 > div > div:nth-child(1) > div'))
                values: map = get_text(finrat_html_soup.select('#form1 > div > div:nth-child(2) > div'))

                with db_con.begin():
                    db_con.execute(
                        text('SELECT public."fn_update_idx_rti_analytics_stock_kpi"(:period_sid, :stock_sid, :kpi_alias_ids, :kpi_values);'),
                        {
                            'period_sid': period_sid,
                            'stock_sid': stock_sid,
                            'kpi_alias_ids': list(kpis),
                            'kpi_values': list(values)
                        }
                    )



    #             # A. Annual Balance Sheet (ABS)
    #             with session.get(
    #                 'https://analytics2.rti.co.id/',
    #                 params={
    #                     'm_id': '1',
    #                     'sub_m': 's2',
    #                     'sub_sub_m': '3',
    #                     's4m': '1',
    #                     'fin_prd': '1',
    #                     'codefld2': stock_code,
    #                     'hidden_period': 'daily',
    #                     'hidden_period_ic': '',
    #                     'hidden_scrollTo': 'header_ic2',
    #                     'codefld': stock_code
    #                 }
    #             ) as response:
    #                 abs_html_soup: BeautifulSoup = BeautifulSoup(response.text, 'html.parser')

    #             get_abs_data_idx: Callable = lambda phrase: int(
    #                 search(
    #                     r'id=r(\d+)c',
    #                     abs_html_soup.find('td', string=re_compile(phrase)).parent.find('script').get_text()
    #                 ).group(1)
    #             ) - 1

    #             abs_data_req_params: Match = search(
    #                 f'c= \'{stock_code}\';s= \'(.+)\';p= \'(.+)\';',
    #                 abs_html_soup.find('script', string=re_compile('var _0x9654')).get_text()
    #             )

    #             with session.get(
    #                 'https://analytics2.rti.co.id/query_financial.jsp',
    #                 params={
    #                     'type': search(r'fin_req\(\"(.+)\"\)', abs_html_soup.find('script', string=re_compile(r'fin_req\(\".+\"\)')).get_text()).group(1),
    #                     'code': stock_code,
    #                     'sector': abs_data_req_params.group(1),
    #                     'period': abs_data_req_params.group(2),
    #                     random(): ''
    #                 }
    #             ) as response:
    #                 balance_sheet: DataFrame = DataFrame([row.split('|') for row in response.text.split('|;')])

    #             balance_sheet.rename(
    #                 index={
    #                     0: 'statement_date',
    #                     get_abs_data_idx('Total Assets'): 'total_asset',
    #                     get_abs_data_idx('Total Stockholders\' Equity'): 'total_equity'
    #                 },
    #                 inplace=True
    #             )

    #             if is_bank:
    #                 balance_sheet.rename(
    #                     index={
    #                         get_abs_data_idx('(Capital Adequacy Ratio)'): 'car',
    #                         get_abs_data_idx('(Non Performing Loan)'): 'npl'
    #                     },
    #                     inplace=True
    #                 )

    #             balance_sheet = balance_sheet[balance_sheet.index.to_series().str.strip().notna()].transpose()

    #             del abs_html_soup, get_abs_data_idx, abs_data_req_params

    #             # B. Annual Income Statement (AIS)
    #             with session.get(
    #                 'https://analytics2.rti.co.id/',
    #                 params={
    #                     'm_id': '1',
    #                     'sub_m': 's2',
    #                     'sub_sub_m': '3',
    #                     's4m': '2',
    #                     'fin_prd': '1',
    #                     'codefld2': stock_code,
    #                     'hidden_period': 'daily',
    #                     'hidden_period_ic': '',
    #                     'hidden_scrollTo': 'header_ic2',
    #                     'codefld': stock_code
    #                 }
    #             ) as response:
    #                 ais_html_soup = BeautifulSoup(response.text, 'html.parser')

    #             get_ais_data_idx: Callable = lambda phrase: int(
    #                 search(
    #                     r'id=r(\d+)c',
    #                     ais_html_soup.find('td', string=phrase).parent.find('script').get_text()
    #                 ).group(1)
    #             ) - 1

    #             ais_data_req_params: Match = search(
    #                 f'c= \'{stock_code}\';s= \'(.+)\';p= \'(.+)\';',
    #                 ais_html_soup.find('script', string=re_compile('var _0x9654')).get_text()
    #             )

    #             with session.get(
    #                 'https://analytics2.rti.co.id/query_financial.jsp',
    #                 params={
    #                     'type': search(r'fin_req\("(.+)"\)', ais_html_soup.find('script', string=re_compile(r'fin_req\(".+"\)')).get_text()).group(1),
    #                     'code': stock_code,
    #                     'sector': ais_data_req_params.group(1),
    #                     'period': ais_data_req_params.group(2),
    #                     random(): ''
    #                 }
    #             ) as response:
    #                 income_statement: DataFrame = DataFrame([row.split('|') for row in response.text.split('|;')])

    #             income_statement.rename(
    #                 index={
    #                     0: 'statement_date',
    #                     get_ais_data_idx('Net Income'): 'net_income'
    #                 },
    #                 inplace=True
    #             )

    #             del ais_html_soup, get_ais_data_idx, ais_data_req_params

    #             income_statement = income_statement[income_statement.index.to_series().str.strip().notna()].transpose()

    #             # C. Profile
    #             with session.get(
    #                 'https://analytics2.rti.co.id/',
    #                 params={
    #                     'm_id': '1',
    #                     'sub_m': 's2',
    #                     'sub_sub_m': '4',
    #                     'codefld2': stock_code,
    #                     'hidden_period': 'daily',
    #                     'hidden_period_ic': '',
    #                     'hidden_scrollTo': 'header_ic2',
    #                     'codefld': stock_code
    #                 }
    #             ) as response:
    #                 profile_html_soup = BeautifulSoup(response.text, 'html.parser')

    #             # C1. EPS
    #             stats: List[DataFrame] = [
    #                 stat \
    #                     .rename(index=stat[0].str.strip()) \
    #                     .drop(0, axis='columns') \
    #                     .transpose()
    #                 for stat
    #                 in itemgetter(*[1, 4, 5, 7, 8, 9, 10])(read_html(str(profile_html_soup.select_one('#dtable > tr:nth-child(3) > td > form > table:nth-child(4) > tr > td:nth-child(2) > table')), flavor='bs4'))
    #             ]

    #             concat(stats[1:], axis='columns').rename({
    #                 'Financial Stmt Date': 'statement_date',
    #                 'Financial Year End',
    #                 'Issued Shares',
    #                 'Market Cap',
    #                 'Stock Index (Base=100)',
    #                 'Sales',
    #                 'Equity',
    #                 'Asset',
    #                 'Liability',
    #                 'Cash Flow',
    #                 'Operating Profit',
    #                 'Net Profit',
    #                 'Dividend Per Share (DPS)',
    #                 'Earnings Per Share (EPS)*',
    #                 'Revenue Per Share (RPS)*',
    #                 'Book Value Per Share (BVPS)',
    #                 'Cash Flow Per Share (CFPS)*',
    #                 'Cash Eqvl Per Share (CEPS)',
    #                 'Net Asset Value Per Sh. (NAVS)',
    #                 'Dividend Yield',
    #                 'Price Earnings Ratio (PER)*',
    #                 'Price Sales Ratio (PSR)*',
    #                 'Price Book Value Rt. (PBVR)', 'Price Cash Flow Rt. (PCFR)*',
    #    'Gross Profit Margin (GPM)', 'Operating Profit Margin (OPM)',
    #    'Net Profit Margin (NPM)', 'Earnings-Int&Tax Margin(EBITM)',
    #    'Dividend Payout Ratio (DPR)', 'Return On Equity (ROE)*',
    #    'Return On Assets (ROA)*', 'Debt Equity Ratio (DER)', 'Cash Ratio (CR)',
    #    'Quick Ratio (QR)', 'Current Ratio (CRR)'
    #             })

    #             print(stats)

                # C2. Percentage-Based Values (ROE, ROA, DER, CR, QR, CRR)
