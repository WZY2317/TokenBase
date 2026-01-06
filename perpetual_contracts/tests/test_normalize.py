"""
测试标准化函数
"""
from utils.pair_mapping import normalize_pair, create_mapping_key

# 测试XT
multiplier1, base1, quote1 = normalize_pair('1000shib', 'usdt')
print(f"XT: 1000shib/usdt -> multiplier={multiplier1}, base={base1}, quote={quote1}")
key1 = create_mapping_key('1000shib', 'usdt')
print(f"  Key: {key1}")

# 测试Binance
multiplier2, base2, quote2 = normalize_pair('1000SHIB', 'USDT')
print(f"\nBinance: 1000SHIB/USDT -> multiplier={multiplier2}, base={base2}, quote={quote2}")
key2 = create_mapping_key('1000SHIB', 'USDT')
print(f"  Key: {key2}")

print(f"\n匹配: {key1 == key2}")
