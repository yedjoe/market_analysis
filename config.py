DB_USERNAME: str = 'market_analysis'
DB_PASSWORD: str = 'market_analysis'
DB_HOST: str = 'localhost'
DB_PORT: int = 5432
DB_NAME: str = 'db_market_analysis'
DB_URL: str = f'postgresql+psycopg2://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
