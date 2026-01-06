# 交易对映射查询示例（列式存储版）

映射表采用列式存储，每个交易所的symbol占一列，没有映射的为NULL。

## 表结构

```
normalized_pair | xt_symbol | binance_symbol | okx_symbol | bybit_symbol | gate_symbol | kucoin_symbol | mexc_symbol
```

## 1. 基础查询

```sql
-- 查看所有映射
SELECT * FROM pair_mappings ORDER BY exchange_count DESC, normalized_pair;

-- 只看symbol列
SELECT
    normalized_pair,
    xt_symbol,
    binance_symbol,
    okx_symbol,
    bybit_symbol,
    gate_symbol,
    kucoin_symbol,
    mexc_symbol
FROM pair_mappings
ORDER BY normalized_pair;
```

## 2. 查询特定交易对

```sql
-- 查询BTC的映射
SELECT
    normalized_pair,
    xt_symbol,
    binance_symbol,
    okx_symbol,
    bybit_symbol
FROM pair_mappings
WHERE normalized_pair = 'BTC_USDT';

-- 查询包含PEPE的交易对
SELECT
    normalized_pair,
    xt_symbol,
    binance_symbol
FROM pair_mappings
WHERE normalized_pair LIKE '%PEPE%';
```

## 3. 按交易所查询

```sql
-- 查询在Binance有映射的所有交易对
SELECT
    normalized_pair,
    xt_symbol,
    binance_symbol
FROM pair_mappings
WHERE binance_symbol IS NOT NULL
ORDER BY normalized_pair;

-- 查询同时在Binance和OKX都有的交易对
SELECT
    normalized_pair,
    xt_symbol,
    binance_symbol,
    okx_symbol
FROM pair_mappings
WHERE binance_symbol IS NOT NULL
  AND okx_symbol IS NOT NULL;

-- 查询只在XT和Gate有，其他交易所都没有的
SELECT
    normalized_pair,
    xt_symbol,
    gate_symbol
FROM pair_mappings
WHERE gate_symbol IS NOT NULL
  AND binance_symbol IS NULL
  AND okx_symbol IS NULL
  AND bybit_symbol IS NULL;
```

## 4. 统计查询

```sql
-- 统计各交易所覆盖率
SELECT
    '总映射数' as metric,
    COUNT(*) as count
FROM pair_mappings

UNION ALL

SELECT 'Binance覆盖', COUNT(*)
FROM pair_mappings WHERE binance_symbol IS NOT NULL

UNION ALL

SELECT 'OKX覆盖', COUNT(*)
FROM pair_mappings WHERE okx_symbol IS NOT NULL

UNION ALL

SELECT 'Bybit覆盖', COUNT(*)
FROM pair_mappings WHERE bybit_symbol IS NOT NULL

UNION ALL

SELECT 'Gate覆盖', COUNT(*)
FROM pair_mappings WHERE gate_symbol IS NOT NULL

UNION ALL

SELECT 'KuCoin覆盖', COUNT(*)
FROM pair_mappings WHERE kucoin_symbol IS NOT NULL

UNION ALL

SELECT 'MEXC覆盖', COUNT(*)
FROM pair_mappings WHERE mexc_symbol IS NOT NULL;
```

## 5. 支持多交易所的交易对

```sql
-- 查询支持7个交易所的交易对（最优质）
SELECT
    normalized_pair,
    xt_symbol,
    binance_symbol,
    okx_symbol,
    bybit_symbol,
    gate_symbol,
    kucoin_symbol,
    mexc_symbol
FROM pair_mappings
WHERE exchange_count = 7
ORDER BY normalized_pair;

-- 查询支持>=5个交易所的交易对
SELECT
    normalized_pair,
    xt_symbol,
    exchange_count
FROM pair_mappings
WHERE exchange_count >= 5
ORDER BY exchange_count DESC, normalized_pair;
```

## 6. 价格对比

```sql
-- 对比XT和Binance的价格
SELECT
    normalized_pair,
    xt_symbol,
    xt_price,
    binance_symbol,
    binance_price,
    ABS(xt_price - binance_price) / xt_price * 100 as price_diff_pct
FROM pair_mappings
WHERE binance_symbol IS NOT NULL
ORDER BY price_diff_pct DESC
LIMIT 20;

-- 查看所有交易所的价格
SELECT
    normalized_pair,
    xt_price,
    binance_price,
    okx_price,
    bybit_price,
    gate_price,
    kucoin_price,
    mexc_price
FROM pair_mappings
WHERE normalized_pair = 'BTC_USDT';
```

## 7. 查询特殊倍数的交易对

```sql
-- 查询XT倍数不为1的交易对（如1000PEPE）
SELECT
    normalized_pair,
    xt_symbol,
    xt_multiplier,
    binance_symbol,
    binance_multiplier
FROM pair_mappings
WHERE xt_multiplier > 1
   OR binance_multiplier > 1
ORDER BY xt_multiplier DESC;
```

## 8. 反向查询（通过symbol找标准化名称）

```sql
-- 通过Binance symbol找XT symbol
SELECT
    binance_symbol,
    xt_symbol,
    normalized_pair
FROM pair_mappings
WHERE binance_symbol = 'BTCUSDT';

-- 通过任意交易所symbol找映射
SELECT
    normalized_pair,
    xt_symbol,
    binance_symbol,
    okx_symbol
FROM pair_mappings
WHERE binance_symbol = '1000PEPEUSDT'
   OR okx_symbol = '1000PEPE-USDT-SWAP'
   OR xt_symbol = 'pepe_usdt';
```

## 9. 导出映射

```sql
-- 导出XT-Binance映射CSV
COPY (
    SELECT
        normalized_pair,
        xt_symbol,
        binance_symbol,
        xt_price,
        binance_price
    FROM pair_mappings
    WHERE binance_symbol IS NOT NULL
    ORDER BY normalized_pair
) TO '/tmp/xt_binance_mapping.csv' WITH CSV HEADER;

-- 导出完整映射（所有交易所）
COPY (
    SELECT
        normalized_pair,
        xt_symbol,
        binance_symbol,
        okx_symbol,
        bybit_symbol,
        gate_symbol,
        kucoin_symbol,
        mexc_symbol,
        exchange_count
    FROM pair_mappings
    ORDER BY exchange_count DESC, normalized_pair
) TO '/tmp/all_exchange_mappings.csv' WITH CSV HEADER;
```

## 10. 缺失映射分析

```sql
-- 查找XT有但Binance没有的交易对
SELECT
    normalized_pair,
    xt_symbol,
    normalized_base,
    normalized_quote
FROM pair_mappings
WHERE binance_symbol IS NULL
ORDER BY normalized_pair;

-- 统计各交易所缺失的映射数量
SELECT
    'Binance缺失' as exchange,
    COUNT(*) as missing_count
FROM pair_mappings WHERE binance_symbol IS NULL

UNION ALL

SELECT 'OKX缺失', COUNT(*)
FROM pair_mappings WHERE okx_symbol IS NULL

UNION ALL

SELECT 'Bybit缺失', COUNT(*)
FROM pair_mappings WHERE bybit_symbol IS NULL

UNION ALL

SELECT 'Gate缺失', COUNT(*)
FROM pair_mappings WHERE gate_symbol IS NULL

UNION ALL

SELECT 'KuCoin缺失', COUNT(*)
FROM pair_mappings WHERE kucoin_symbol IS NULL

UNION ALL

SELECT 'MEXC缺失', COUNT(*)
FROM pair_mappings WHERE mexc_symbol IS NULL;
```

## 11. 创建视图简化查询

```sql
-- 创建只包含symbol的视图
CREATE VIEW v_pair_symbols AS
SELECT
    normalized_pair,
    xt_symbol,
    binance_symbol,
    okx_symbol,
    bybit_symbol,
    gate_symbol,
    kucoin_symbol,
    mexc_symbol,
    exchange_count
FROM pair_mappings;

-- 使用视图查询
SELECT * FROM v_pair_symbols WHERE normalized_pair = 'BTC_USDT';
```

## 12. 聚合分析

```sql
-- 按base asset统计支持的交易所数量
SELECT
    normalized_base,
    COUNT(*) as pair_count,
    AVG(exchange_count) as avg_exchange_support,
    MAX(exchange_count) as max_exchange_support
FROM pair_mappings
GROUP BY normalized_base
HAVING COUNT(*) >= 2
ORDER BY avg_exchange_support DESC
LIMIT 20;

-- 找出最受欢迎的base asset（支持交易所最多）
SELECT
    normalized_base,
    COUNT(*) as total_pairs,
    SUM(CASE WHEN binance_symbol IS NOT NULL THEN 1 ELSE 0 END) as binance_count,
    SUM(CASE WHEN okx_symbol IS NOT NULL THEN 1 ELSE 0 END) as okx_count
FROM pair_mappings
GROUP BY normalized_base
ORDER BY total_pairs DESC
LIMIT 20;
```

## 优势

列式存储的优势：
1. ✅ 查询简单直观，不需要解析JSONB
2. ✅ 每列可以独立索引
3. ✅ NULL值自动表示没有映射
4. ✅ 易于导出和可视化
5. ✅ 与传统SQL工具兼容性好
