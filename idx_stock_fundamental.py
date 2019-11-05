import random
import re
import time

from bs4 import BeautifulSoup
import psycopg2
import requests


TABLE_NAME = 'public.mst_stock'
STOCK_EXCHANGE_CODE = 'IDX'
RESPONSE_INDEX_TOTAL_ASSET = 19
RESPONSE_INDEX_TOTAL_EQUITY = 40
RESPONSE_INDEX_CAR = 42
RESPONSE_INDEX_NPL = 44

def ajdustUnitless(stringVal):
    nominal = 'NULL'

    try:
        nominal = str(round(float(stringVal), 2))
    
    except ValueError:
        return nominal

    return nominal

def ajdustPercentage(stringVal):
    nominal = 'NULL'

    try:
        nominal = str(round(float(stringVal) / 100, 4))
    
    except ValueError:
        return nominal

    return nominal

def adjustNominal(stringVal):
    nominal = 'NULL'

    try:
        nominal, multiplier = stringVal.replace(',', '').split(' ')
    
    except ValueError:
        return nominal     
    
    if multiplier == 'M':
        return str(float(nominal) * 1000000)
    
    elif multiplier == 'B':
        return str(float(nominal) * 1000000000)

    elif multiplier == 'T':
        return str(float(nominal) * 1000000000000)

    return nominal


session = requests.Session()
retries = requests.packages.urllib3.util.retry.Retry(total=100, backoff_factor=1, status_forcelist=[502, 503, 504])
session.mount('http://', requests.adapters.HTTPAdapter(max_retries=retries))

db_conn = psycopg2.connect(
    host='satao.db.elephantsql.com',
    port=5432,
    dbname='xgpbnhoy',
    user='xgpbnhoy',
    password='DTAm6UYROwh1iDRZstKN1hXyJlAgC7-s'
)

db_cursor = db_conn.cursor()

selector_query = f'''
    SELECT stock_code,
        stock_name
    FROM {TABLE_NAME}
    WHERE stock_exchange_code = \'{STOCK_EXCHANGE_CODE}\'
        AND latest_update < \'2019-11-04 14:21:06\'::timestamptz
    ORDER BY stock_code;
'''

db_cursor.execute(selector_query)

for [stockCode, stockName] in db_cursor.fetchall():
    print(f'{stockCode}, {stockName}')

    is_bank_entity = bool(re.search('bank', stockName, re.IGNORECASE))

    # A. Financial Report - Annual Balance Sheet
    res = session.get(
        'https://analytics2.rti.co.id/', 
        params={
            'm_id': '1',
            'sub_m': 's2',
            'sub_sub_m': '3',
            's4m': '1',
            'fin_prd': '1',
            'codefld2': stockCode,
            'hidden_period': 'daily',
            'hidden_period_ic': '',
            'hidden_scrollTo': 'header_ic2',
            'codefld': stockCode
        }
    )

    html_soup = BeautifulSoup(res.text, 'html.parser')

    params_re = re.search(f'c= \'{stockCode}\';s= \'(.+)\';p= \'(.+)\';', html_soup.find('script', string=re.compile('var _0x9654')).get_text())

    res = session.get(
        'https://analytics2.rti.co.id/query_financial.jsp', 
        params={
            'type': re.search('fin_req\(\"(.+)\"\)', html_soup.find('script', string=re.compile('fin_req\(\".+\"\)')).get_text()).group(1),
            'code': stockCode,
            'sector': params_re.group(1),
            'period': params_re.group(2),
            random.random(): ''
        }
    )

    # A1. Total Assets
    total_asset = {
        'y': 'NULL',
        'y_min_1': 'NULL',
        'y_min_2': 'NULL',
        'y_min_3': 'NULL'
    }

    total_asset_key_phrase = 'Total Assets'
    total_asset_idx = int(re.search('id=r(\d+)c', html_soup.find('td', string=total_asset_key_phrase).parent.find('script').get_text()).group(1)) - 1
    
    try:
        total_asset_list = [adjustNominal(each_total_asset) for each_total_asset in res.text.split('|;')[total_asset_idx].split('|')]
    
        total_asset["y"] = total_asset_list[0]
        total_asset["y_min_1"] = total_asset_list[1]
        total_asset["y_min_2"] = total_asset_list[2]
        total_asset["y_min_3"] = total_asset_list[3]

    except IndexError:
        pass

    # A2. Total Equity
    total_equity = {
        'y': 'NULL',
        'y_min_1': 'NULL',
        'y_min_2': 'NULL',
        'y_min_3': 'NULL'
    }

    total_equity_key_phrase = 'Total Stockholders\' Equity'
    total_equity_idx = int(re.search('id=r(\d+)c', html_soup.find('td', string=total_equity_key_phrase).parent.find('script').get_text()).group(1)) - 1
    
    try:
        total_equity_list = [adjustNominal(each_total_equity) for each_total_equity in res.text.split('|;')[total_equity_idx].split('|')]
    
        total_equity["y"] = total_equity_list[0]
        total_equity["y_min_1"] = total_equity_list[1]
        total_equity["y_min_2"] = total_equity_list[2]
        total_equity["y_min_3"] = total_equity_list[3]

    except IndexError:
        pass

    # A3. CAR & NPL (Bank Only)
    car = {
        'y': 'NULL',
        'y_min_1': 'NULL',
        'y_min_2': 'NULL',
        'y_min_3': 'NULL'
    }

    npl = {
        'y': 'NULL',
        'y_min_1': 'NULL',
        'y_min_2': 'NULL',
        'y_min_3': 'NULL'
    }

    if is_bank_entity:
        # CAR
        car_key_phrase = '(Capital Adequacy Ratio)'
        car_idx = int(re.search('id=r(\d+)c', html_soup.find('td', string=re.compile(car_key_phrase)).parent.find('script').get_text()).group(1)) - 1
        
        try:
            car_list = [ajdustUnitless(each_car) for each_car in res.text.split('|;')[car_idx].split('|')]
        
            car["y"] = car_list[0]
            car["y_min_1"] = car_list[1]
            car["y_min_2"] = car_list[2]
            car["y_min_3"] = car_list[3]
        
        except IndexError:
            pass


        # NPL
        npl_key_phrase = '(Non Performing Loan)'
        npl_idx = int(re.search('id=r(\d+)c', html_soup.find('td', string=re.compile(npl_key_phrase)).parent.find('script').get_text()).group(1)) - 1
        
        try:
            npl_list = [ajdustUnitless(each_npl) for each_npl in res.text.split('|;')[npl_idx].split('|')]
        
            npl["y"] = npl_list[0]
            npl["y_min_1"] = npl_list[1]
            npl["y_min_2"] = npl_list[2]
            npl["y_min_3"] = npl_list[3]
        
        except IndexError:
            pass

    time.sleep(random.randint(3, 5))


    # B. Financial Report - Annual Income Statement
    res = session.get(
        'https://analytics2.rti.co.id/', 
        params={
            'm_id': '1',
            'sub_m': 's2',
            'sub_sub_m': '3',
            's4m': '2',
            'fin_prd': '1',
            'codefld2': stockCode,
            'hidden_period': 'daily',
            'hidden_period_ic': '',
            'hidden_scrollTo': 'header_ic2',
            'codefld': stockCode
        }
    )

    html_soup = BeautifulSoup(res.text, 'html.parser')

    params_re = re.search(f'c= \'{stockCode}\';s= \'(.+)\';p= \'(.+)\';', html_soup.find('script', string=re.compile('var _0x9654')).get_text())

    res = session.get(
        'https://analytics2.rti.co.id/query_financial.jsp', 
        params={
            'type': re.search('fin_req\(\"(.+)\"\)', html_soup.find('script', string=re.compile('fin_req\(\".+\"\)')).get_text()).group(1),
            'code': stockCode,
            'sector': params_re.group(1),
            'period': params_re.group(2),
            random.random(): ''
        }
    )

    # B1. Net Income
    net_income = {
        'y': 'NULL',
        'y_min_1': 'NULL',
        'y_min_2': 'NULL',
        'y_min_3': 'NULL'
    }

    net_income_key_phrase = 'Net Income'
    net_income_idx = int(re.search('id=r(\d+)c', html_soup.find('td', string=net_income_key_phrase).parent.find('script').get_text()).group(1)) - 1
    
    try:
        net_income_list = [adjustNominal(each_net_income) for each_net_income in res.text.split('|;')[net_income_idx].split('|')]
    
        net_income["y"] = net_income_list[0]
        net_income["y_min_1"] = net_income_list[1]
        net_income["y_min_2"] = net_income_list[2]
        net_income["y_min_3"] = net_income_list[3]

    except IndexError:
        pass

    time.sleep(random.randint(3, 5))


    # C. Profile
    res = session.get(
        'https://analytics2.rti.co.id/', 
        params={
            'm_id': '1',
            'sub_m': 's2',
            'sub_sub_m': '4',
            'codefld2': stockCode,
            'hidden_period': 'daily',
            'hidden_period_ic': '',
            'hidden_scrollTo': 'header_ic2',
            'codefld': stockCode
        }
    )

    html_soup = BeautifulSoup(res.text, 'html.parser')

    # C1. EPS
    eps = {
        'y': 'NULL',
        'y_min_1': 'NULL',
        'y_min_2': 'NULL',
        'y_min_3': 'NULL'
    }

    eps_key_phrase = 'Earnings Per Share (EPS)'
    
    try:
        eps_list = [ajdustUnitless(each_eps.get_text()) for each_eps in html_soup.find('div', string=eps_key_phrase).find_parent('td').find('table').find('td', string=re.compile('EPS')).find_parent('tr').find_all('td')[1:]]
        eps_list.reverse()

        eps["y"] = eps_list[0]
        eps["y_min_1"] = eps_list[1]
        eps["y_min_2"] = eps_list[2]
        eps["y_min_3"] = eps_list[3]
    
    except IndexError:
        pass

    # C2. Percentage-Based Values (ROE, ROA, DER, CR, QR, CRR)
    percentage_based_value = {
        'dividend_yield': 'NULL',
        'roe': 'NULL',
        'roa': 'NULL',
        'der': 'NULL',
        'cr': 'NULL',
        'qr': 'NULL',
        'crr': 'NULL'
    }

    percentage_based_key_phrase = {
        'dividend_yield': 'Dividend Yield',
        'roe': 'Return On Equity \(ROE\)\*',
        'roa': 'Return On Assets \(ROA\)\*',
        'der': 'Debt Equity Ratio \(DER\)',
        'cr': 'Cash Ratio \(CR\)',
        'qr': 'Quick Ratio \(QR\)',
        'crr': 'Current Ratio \(CRR\)'
    }

    for key_phrase_key in percentage_based_key_phrase.keys():
        try:
            percentage_based_value[key_phrase_key] = ajdustPercentage(re.search(
                ': (\d*\.?\d+)%',
                html_soup \
                    .find('td', string=re.compile(percentage_based_key_phrase[key_phrase_key])).find_parent('tr').find_all('td')[1].get_text()) \
                    .group(1)
            )
        
        except AttributeError:
            pass

    # C3. Unitless-Based Values (PER, PSR, PBVR, PCFR)
    unitless_based_value = {
        'per': 'NULL',
        'psr': 'NULL',
        'pbvr': 'NULL',
        'pcfr': 'NULL'
    }

    unitless_based_key_phrase = {
        'per': 'Price Earnings Ratio \(PER\)\*',
        'psr': 'Price Sales Ratio \(PSR\)\*',
        'pbvr': 'Price Book Value Rt. \(PBVR\)',
        'pcfr': 'Price Cash Flow Rt. \(PCFR\)\*'
    }

    for key_phrase_key in unitless_based_key_phrase.keys():
        try:
            unitless_based_value[key_phrase_key] = ajdustUnitless(re.search(
                ': (\d*\.?\d+)x',
                html_soup.find('td', string=re.compile(unitless_based_key_phrase[key_phrase_key])).find_parent('tr').find_all('td')[1].get_text()
            ).group(1))
        
        except AttributeError:
            pass


    # Update Database
    update_query = f'''
        UPDATE {TABLE_NAME}
        SET total_asset_y = {total_asset["y"]},
            total_asset_y_min_1 = {total_asset["y_min_1"]},
            total_asset_y_min_2 = {total_asset["y_min_2"]},
            total_asset_y_min_3 = {total_asset["y_min_3"]},
            total_equity_y = {total_equity["y"]},
            total_equity_y_min_1 = {total_equity["y_min_1"]},
            total_equity_y_min_2 = {total_equity["y_min_2"]},
            total_equity_y_min_3 = {total_equity["y_min_3"]},
            car_y = {car["y"]},
            car_y_min_1 = {car["y_min_1"]},
            car_y_min_2 = {car["y_min_2"]},
            car_y_min_3 = {car["y_min_3"]},
            npl_y = {npl["y"]},
            npl_y_min_1 = {npl["y_min_1"]},
            npl_y_min_2 = {npl["y_min_2"]},
            npl_y_min_3 = {npl["y_min_3"]},
            net_income_y = {net_income["y"]},
            net_income_y_min_1 = {net_income["y_min_1"]},
            net_income_y_min_2 = {net_income["y_min_2"]},
            net_income_y_min_3 = {net_income["y_min_3"]},
            eps_y = {eps["y"]},
            eps_y_min_1 = {eps["y_min_1"]},
            eps_y_min_2 = {eps["y_min_2"]},
            eps_y_min_3 = {eps["y_min_3"]},
            dividend_yield = {percentage_based_value["dividend_yield"]},
            per = {unitless_based_value["per"]},
            psr = {unitless_based_value["psr"]},
            pbvr = {unitless_based_value["pbvr"]},
            pcfr = {unitless_based_value["pcfr"]},
            roe = {percentage_based_value["roe"]},
            roa = {percentage_based_value["roa"]},
            der = {percentage_based_value["der"]},
            cr = {percentage_based_value["cr"]},
            qr = {percentage_based_value["qr"]},
            crr = {percentage_based_value["crr"]},
            latest_update = NOW()
        WHERE stock_exchange_code = \'{STOCK_EXCHANGE_CODE}\'
            AND stock_code = \'{stockCode}\';
    '''

    db_cursor.execute(update_query)
    db_conn.commit()

db_cursor.close()
db_conn.close()