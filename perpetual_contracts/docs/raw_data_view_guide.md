# 原始数据视图使用指南

## 概述

`v_trading_info_raw` 视图提供各交易所的**完整原始数据**（JSONB 格式），包含所有 API 返回的字段。

## 视图对比

| 视图 | 数据类型 | 字段 | 用途 |
|------|---------|------|------|
| **v_trading_info** | 标准化数据 | 精选的统一字段 | 跨交易所对比、常规查询 |
| **v_trading_info_raw** | 原始完整数据 | 所有 API 字段 | 访问特殊字段、调试、深度分析 |

## 数据结构

### BTC-USDT 示例

```sql
SELECT * FROM v_trading_info_raw WHERE xt_symbol = 'btc_usdt';
```

返回：
```
xt_symbol: btc_usdt
normalized_pair: BTC_USDT
xt_raw_data: {所有 77 个 XT 字段}
binance_raw_data: {所有 29 个 Binance 字段}
okx_raw_data: {所有 48 个 OKX 字段}
bybit_raw_data: {所有 Bybit 字段}
gate_raw_data: {所有 Gate 字段}
kucoin_raw_data: {所有 KuCoin 字段}
mexc_raw_data: {所有 MEXC 字段}
```

### 各交易所原始字段数量

- **XT**: 77 个字段
- **Binance**: 29 个字段
- **OKX**: 48 个字段
- **Bybit**: 27 个字段
- **Gate**: 54 个字段
- **KuCoin**: 85 个字段
- **MEXC**: 79 个字段

## 使用方法

### 1. 查询完整原始数据

```sql
SELECT
    xt_symbol,
    xt_raw_data,
    binance_raw_data,
    okx_raw_data
FROM v_trading_info_raw
WHERE xt_symbol = 'btc_usdt';
```

### 2. 提取特定原始字段

```sql
SELECT
    xt_symbol,
    -- XT 原始字段
    xt_raw_data->>'symbol' as xt_symbol,
    xt_raw_data->>'minqty' as xt_minqty,
    xt_raw_data->>'contractsize' as xt_contractsize,
    xt_raw_data->>'priceprecision' as xt_price_precision,

    -- Binance 原始字段
    binance_raw_data->>'symbol' as bn_symbol,
    binance_raw_data->>'underlyingtype' as bn_underlying_type,
    binance_raw_data->>'contracttype' as bn_contract_type,

    -- OKX 原始字段
    okx_raw_data->>'instid' as okx_instid,
    okx_raw_data->>'ctval' as okx_ctval,
    okx_raw_data->>'ctmult' as okx_ctmult
FROM v_trading_info_raw
WHERE xt_symbol = 'btc_usdt';
```

### 3. 查看 Binance 特有字段

Binance 有一些标准化视图中没有的字段：

```sql
SELECT
    xt_symbol,
    binance_raw_data->>'underlyingtype' as underlying_type,
    binance_raw_data->>'contracttype' as contract_type,
    binance_raw_data->>'deliverydate' as delivery_date,
    binance_raw_data->>'onboarddate' as onboard_date,
    binance_raw_data->>'settlePlan' as settle_plan
FROM v_trading_info_raw
WHERE binance_raw_data IS NOT NULL
LIMIT 10;
```

### 4. 查看完整的 Binance filters

```sql
SELECT
    xt_symbol,
    binance_raw_data->>'filters' as filters,
    binance_raw_data->>'ordertypes' as order_types,
    binance_raw_data->>'timeinforce' as time_in_force
FROM v_trading_info_raw
WHERE xt_symbol = 'btc_usdt';
```

### 5. 对比标准化数据 vs 原始数据

```sql
SELECT
    ti.xt_symbol,

    -- 标准化视图
    ti.xt_info->>'min_qty' as standardized_min_qty,
    ti.xt_info->>'contract_size' as standardized_contract_size,

    -- 原始数据
    tir.xt_raw_data->>'minqty' as raw_min_qty,
    tir.xt_raw_data->>'contractsize' as raw_contract_size

FROM v_trading_info ti
JOIN v_trading_info_raw tir ON ti.xt_symbol = tir.xt_symbol
WHERE ti.xt_symbol = 'btc_usdt';
```

### 6. 查看某个交易所的所有字段名

```sql
SELECT DISTINCT
    jsonb_object_keys(xt_raw_data) as field_name
FROM v_trading_info_raw
WHERE xt_raw_data IS NOT NULL
ORDER BY field_name;
```

### 7. 统计各交易所的字段数量

```sql
SELECT
    'xt' as exchange,
    COUNT(DISTINCT jsonb_object_keys(xt_raw_data)) as field_count
FROM v_trading_info_raw
WHERE xt_raw_data IS NOT NULL

UNION ALL

SELECT
    'binance',
    COUNT(DISTINCT jsonb_object_keys(binance_raw_data))
FROM v_trading_info_raw
WHERE binance_raw_data IS NOT NULL

UNION ALL

SELECT
    'okx',
    COUNT(DISTINCT jsonb_object_keys(okx_raw_data))
FROM v_trading_info_raw
WHERE okx_raw_data IS NOT NULL;
```

### 8. 查找包含特定字段的交易所

例如，查找哪些交易所有 `leverage` 相关字段：

```sql
SELECT
    xt_symbol,
    CASE WHEN xt_raw_data ? 'maxleverage' THEN 'XT' END as xt_has_leverage,
    CASE WHEN okx_raw_data ? 'lever' THEN 'OKX' END as okx_has_leverage,
    CASE WHEN mexc_raw_data ? 'maxleverage' THEN 'MEXC' END as mexc_has_leverage
FROM v_trading_info_raw
WHERE xt_symbol = 'btc_usdt';
```

## 常用原始字段

### XT 特有字段

```sql
SELECT
    xt_symbol,
    xt_raw_data->>'initleverage' as init_leverage,
    xt_raw_data->>'maxleverage' as max_leverage,
    xt_raw_data->>'fundingratecap' as funding_rate_cap,
    xt_raw_data->>'fundinginterval' as funding_interval
FROM v_trading_info_raw
WHERE xt_symbol = 'btc_usdt';
```

### Binance 特有字段

```sql
SELECT
    xt_symbol,
    binance_raw_data->>'underlyingtype' as underlying_type,
    binance_raw_data->>'contracttype' as contract_type,
    binance_raw_data->>'deliverydate' as delivery_date,
    binance_raw_data->>'liquidationFee' as liquidation_fee,
    binance_raw_data->>'marketTakeBound' as market_take_bound
FROM v_trading_info_raw
WHERE binance_raw_data IS NOT NULL
LIMIT 10;
```

### OKX 特有字段

```sql
SELECT
    xt_symbol,
    okx_raw_data->>'instfamily' as inst_family,
    okx_raw_data->>'category' as category,
    okx_raw_data->>'settleccy' as settle_ccy,
    okx_raw_data->>'listtime' as list_time,
    okx_raw_data->>'exptime' as exp_time
FROM v_trading_info_raw
WHERE okx_raw_data IS NOT NULL
LIMIT 10;
```

## 高级查询

### 1. JSON 数组处理（如 Binance filters）

```sql
SELECT
    xt_symbol,
    jsonb_array_elements(binance_raw_data->'filters') as filter
FROM v_trading_info_raw
WHERE xt_symbol = 'btc_usdt';
```

### 2. 条件过滤原始字段

查找最大杠杆 > 100 的交易对：

```sql
SELECT
    xt_symbol,
    (xt_raw_data->>'maxleverage')::int as xt_max_leverage,
    (okx_raw_data->>'lever')::text as okx_max_leverage
FROM v_trading_info_raw
WHERE (xt_raw_data->>'maxleverage')::int > 100
   OR (okx_raw_data->>'lever')::text::int > 100;
```

### 3. 聚合统计

统计各交易所的平均最大杠杆：

```sql
SELECT
    AVG((xt_raw_data->>'maxleverage')::numeric) as avg_xt_leverage,
    AVG((okx_raw_data->>'lever')::numeric) as avg_okx_leverage,
    AVG((mexc_raw_data->>'maxleverage')::numeric) as avg_mexc_leverage
FROM v_trading_info_raw
WHERE xt_raw_data IS NOT NULL;
```

## 性能提示

1. **使用索引**：虽然视图已经 JOIN 了映射表，但对频繁查询的字段建议提取到独立列

2. **限制返回数据**：原始数据量大，建议只查询需要的字段
   ```sql
   -- ❌ 不好：返回所有原始数据
   SELECT * FROM v_trading_info_raw;

   -- ✅ 好：只查询需要的字段
   SELECT xt_symbol, xt_raw_data->>'minqty' FROM v_trading_info_raw;
   ```

3. **过滤条件**：优先使用 xt_symbol 或 normalized_pair 过滤
   ```sql
   -- ✅ 好：使用索引字段
   WHERE xt_symbol = 'btc_usdt'
   ```

## 应用场景

### 1. 调试和验证

对比原始数据和标准化数据，确保转换正确：

```sql
SELECT
    ti.xt_symbol,
    ti.okx_info->>'min_qty' as standardized,
    tir.okx_raw_data->>'minsz' as raw,
    ti.okx_info->>'contract_size' as ct_val,
    tir.okx_raw_data->>'ctval' as raw_ct_val
FROM v_trading_info ti
JOIN v_trading_info_raw tir ON ti.xt_symbol = tir.xt_symbol
WHERE ti.xt_symbol = 'btc_usdt';
```

### 2. 访问特殊字段

某些交易所特有的字段（如 Binance 的 underlyingType）：

```sql
SELECT
    xt_symbol,
    binance_raw_data->>'underlyingtype',
    binance_raw_data->>'contracttype'
FROM v_trading_info_raw
WHERE binance_raw_data IS NOT NULL;
```

### 3. 数据分析

导出所有原始数据进行离线分析：

```sql
COPY (
    SELECT xt_symbol, xt_raw_data, binance_raw_data, okx_raw_data
    FROM v_trading_info_raw
) TO '/tmp/raw_trading_data.csv' CSV HEADER;
```

## 总结

| 特性 | v_trading_info | v_trading_info_raw |
|------|----------------|-------------------|
| 数据 | 标准化精选字段 | 完整原始数据 |
| 字段数 | 固定的统一字段 | 所有 API 字段 |
| 查询速度 | 快 | 中等 |
| 用途 | 日常查询、跨交易所对比 | 深度分析、调试、访问特殊字段 |
| 推荐使用 | ✅ 优先使用 | 需要特殊字段时使用 |

**建议**：
- 日常查询优先使用 `v_trading_info`
- 需要访问特殊字段或调试时使用 `v_trading_info_raw`
- 两者可以 JOIN 使用，对比标准化数据和原始数据
