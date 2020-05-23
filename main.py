# from func.psql import PSQL
from func.stock_market import StockMarket


def main():
    # psql = PSQL()
    # psql.fn_exporter()

    sm = StockMarket()
    sm.update_idx_rti_analytics_stock_kpi()


if __name__ == '__main__':
    main()
