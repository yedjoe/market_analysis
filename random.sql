SELECT *
FROM public.mst_stock
WHERE stock_exchange_code = 'IDX'
    AND stock_code = 'BNII'
    
    
SELECT name,
    abbrev,
    utc_offset,
    is_dst
FROM pg_timezone_names
WHERE utc_offset = '+07:00:00';