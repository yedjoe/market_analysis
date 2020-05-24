from subprocess import call

from service.stock_scraper import StockScraper
from service.pg_dump import PGDump
from service.windows_inhibitor import WindowsInhibitor


class Console:
    __selection: str
    __win_inhibitor: WindowsInhibitor = WindowsInhibitor()

    def __init__(self):
        print('1. Update IDX Financial KPI')
        print('2. Export DB Schema')

        self.__selection = input('Choose an action: ')

        self.__win_inhibitor.inhibit()

        if self.__selection == '1':
            ss = StockScraper()
            ss.update_idx_rti_analytics_stock_kpi()

        elif self.__selection == '2':
            PGDump().execute()

        self.__win_inhibitor.uninhibit()
