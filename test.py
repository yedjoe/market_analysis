total_asset_y_min_3 = 'NULL'
total_asset_y_min_2 = 'NULL'
total_asset_y_min_1 = 'NULL'
total_asset_y = 'NULL'

total_assets = [1, 2, 3]

try:
    total_asset_y = total_assets[0]
    total_asset_y_min_1 = total_assets[1]
    total_asset_y_min_2 = total_assets[2]
    total_asset_y_min_3 = total_assets[3]

except IndexError:
    pass

print(total_asset_y)
print(total_asset_y_min_1)
print(total_asset_y_min_2)
print(total_asset_y_min_3)