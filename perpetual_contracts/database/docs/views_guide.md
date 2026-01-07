# 数据库视图使用指南

## 核心视图

本项目保留 **3 个核心视图**，覆盖所有业务场景：

---

### 1. v_unified_trading_info

**文件**: `unified_trading_info_view.sql`

**用途**: 统一交易信息视图（精确匹配 + 模糊匹配）- 标准化数据

**数据源**: `unified_pair_mappings` 表

**特点**:
- 包含所有映射关系（exact + fuzzy）
- 长格式：每个 XT 交易对在每个交易所的映射占一行
- 包含匹配质量指标：`match_type`, `string_similarity`, `price_diff`
- 同时提供宽表版本：`v_unified_trading_info_wide`
- **所有数量字段已标准化为币本位**（OKX 的张数已换算）

**返回字段**:
- `xt_symbol`, `normalized_pair/base/quote`
- `match_type`: 'exact' 或 'fuzzy'
- `string_similarity`: 字符串相似度（0-1）
- `price_diff`: 价格差异百分比
- `matched_exchange`: 匹配到的交易所
- `xt_info`: XT 交易信息 (JSONB)
- `binance_info/okx_info/bybit_info/gate_info/kucoin_info/mexc_info`: 各交易所信息 (JSONB)

**使用场景**:
```sql
-- 1. 查询某个 XT 交易对在所有交易所的映射（包括模糊匹配）
SELECT * FROM v_unified_trading_info
WHERE xt_symbol = 'btc_usdt';

-- 2. 只查询精确匹配
SELECT * FROM v_unified_trading_info
WHERE xt_symbol = 'btc_usdt' AND match_type = 'exact';

-- 3. 查询高质量的模糊匹配
SELECT * FROM v_unified_trading_info
WHERE match_type = 'fuzzy'
  AND string_similarity > 0.9
  AND ABS(price_diff) < 0.01;

-- 4. 使用宽表版本（一行展示所有交易所）
SELECT * FROM v_unified_trading_info_wide
WHERE xt_symbol = 'btc_usdt';

-- 5. 提取并比较各交易所的最小下单量（已标准化为币本位）
SELECT
    xt_symbol,
    matched_exchange,
    xt_info->>'min_qty' as xt_min_qty,
    CASE
        WHEN matched_exchange = 'binance' THEN binance_info->>'min_qty'
        WHEN matched_exchange = 'okx' THEN okx_info->>'min_qty'
        WHEN matched_exchange = 'bybit' THEN bybit_info->>'min_qty'
        WHEN matched_exchange = 'gate' THEN gate_info->>'min_qty'
        WHEN matched_exchange = 'kucoin' THEN kucoin_info->>'min_qty'
        WHEN matched_exchange = 'mexc' THEN mexc_info->>'min_qty'
    END as exchange_min_qty
FROM v_unified_trading_info
WHERE xt_symbol = 'btc_usdt';
```

**注意**:
- 数量字段（min_qty等）已做标准化换算，OKX 的张数已转换为币本位
- 每个交易所的 info 是 JSONB 格式，使用 `->` 或 `->>` 提取字段

---

### 2. v_unified_trading_info_wide

**文件**: `unified_trading_info_view.sql`（在同一文件中）

**用途**: 统一交易信息宽表视图 - 一行展示一个 XT 交易对在所有交易所的信息

**数据源**: `unified_pair_mappings` 表

**特点**:
- 宽表格式：一个 XT 交易对占一行
- 每列是一个交易所的信息
- 方便横向对比所有交易所
- 每个交易所 info 包含 match_type 和 similarity

**使用场景**:
```sql
-- 1. 查看某个交易对在所有交易所的情况
SELECT * FROM v_unified_trading_info_wide WHERE xt_symbol = 'btc_usdt';

-- 2. 查看有 Binance 映射的所有交易对
SELECT xt_symbol, xt_info, binance_info
FROM v_unified_trading_info_wide
WHERE binance_info IS NOT NULL;

-- 3. 查看同时有精确和模糊匹配的交易对
SELECT
    xt_symbol,
    binance_info->>'match_type' as bn_match,
    okx_info->>'match_type' as okx_match,
    bybit_info->>'match_type' as bb_match
FROM v_unified_trading_info_wide
WHERE binance_info IS NOT NULL OR okx_info IS NOT NULL OR bybit_info IS NOT NULL;
```

---

### 3. v_raw_data

**文件**: `raw_data_view.sql`

**用途**: 原始数据视图 - 返回所有交易所的完整原始数据（未标准化）

**数据源**: `unified_pair_mappings` + 各交易所原始表

**特点**:
- 返回完整的原始 JSONB 数据（所有 API 字段）
- 基于 unified_pair_mappings，支持精确和模糊匹配
- 用于调试、查看未标准化的字段、对比原始数据

**返回字段**:
- `xt_symbol`, `normalized_pair/base/quote`
- `matched_exchange`: 匹配到的交易所
- `match_type`: 'exact' 或 'fuzzy'
- `string_similarity`, `price_diff`: 匹配质量指标
- `xt_raw_data`: XT 原始数据 (JSONB)
- `exchange_raw_data`: 匹配交易所的原始数据 (JSONB)

**使用场景**:
```sql
-- 1. 查询单个 XT 交易对在所有交易所的原始数据
SELECT * FROM v_raw_data WHERE xt_symbol = 'btc_usdt';

-- 2. 查询 Binance 的特定原始字段
SELECT
    xt_symbol,
    matched_exchange,
    exchange_raw_data->>'symbol' as symbol,
    exchange_raw_data->>'underlyingType' as underlying_type,
    exchange_raw_data->>'contractType' as contract_type,
    exchange_raw_data->>'filters' as filters
FROM v_raw_data
WHERE matched_exchange = 'binance'
  AND xt_symbol = 'btc_usdt';

-- 3. 查询 OKX 的所有原始字段（查看字段列表）
SELECT DISTINCT jsonb_object_keys(exchange_raw_data)
FROM v_raw_data
WHERE matched_exchange = 'okx'
LIMIT 1;

-- 4. 对比标准化数据和原始数据
SELECT
    r.xt_symbol,
    r.matched_exchange,
    -- 标准化后的字段
    u.okx_info->>'min_qty' as standardized_min_qty,
    -- 原始字段
    r.exchange_raw_data->>'minsz' as raw_min_qty,
    r.exchange_raw_data->>'ctval' as raw_ctval,
    r.exchange_raw_data->>'ctmult' as raw_ctmult
FROM v_raw_data r
JOIN v_unified_trading_info u
  ON r.xt_symbol = u.xt_symbol AND r.matched_exchange = u.matched_exchange
WHERE r.xt_symbol = 'btc_usdt' AND r.matched_exchange = 'okx';

-- 5. 查看 Binance 的完整 filters 原始数据
SELECT
    xt_symbol,
    exchange_raw_data->>'filters' as filters,
    exchange_raw_data->>'orderTypes' as order_types,
    exchange_raw_data->>'timeInForce' as time_in_force
FROM v_raw_data
WHERE xt_symbol = 'btc_usdt' AND matched_exchange = 'binance';

-- 6. 统计每个交易所有多少原始字段
SELECT
    matched_exchange,
    COUNT(DISTINCT jsonb_object_keys(exchange_raw_data)) as field_count
FROM v_raw_data
WHERE exchange_raw_data IS NOT NULL
GROUP BY matched_exchange
ORDER BY field_count DESC;
```

---

## 视图选择指南

| 场景 | 推荐视图 |
|------|---------|
| 需要模糊匹配数据 | `v_unified_trading_info` |
| 需要筛选匹配质量 | `v_unified_trading_info` |
| **跨交易所比较（标准化数据）** | `v_unified_trading_info` / `v_unified_trading_info_wide` ⭐ |
| 查看所有交易所（宽表） | `v_unified_trading_info_wide` |
| **查看原始 API 字段** | `v_raw_data` ⭐ |
| 调试数据映射问题 | `v_raw_data` |
| 查找未标准化的字段 | `v_raw_data` |

---

## 数据标准化说明

### 数量字段标准化（v_unified_trading_info）

不同交易所使用不同的数量单位，`v_unified_trading_info` 已将所有数量字段统一换算为**币本位**：

| 交易所 | 原始单位 | 换算公式 | 标准化后 |
|--------|---------|---------|----------|
| XT | 张数 | `张数 × contract_size` | 币本位 |
| Binance | 币本位 | 直接使用 | 币本位 |
| OKX | 张数 | `张数 × ctVal × ctMult` | 币本位 |
| Bybit | 币本位 | 直接使用 | 币本位 |
| Gate | 张数 | `张数 × contract_size` | 币本位 |
| KuCoin | 币本位 | 直接使用 | 币本位 |
| MEXC | 张数 | `张数 × contract_size` | 币本位 |

**示例**：
- XT: 1 张 × 0.0001 BTC/张 = 0.0001 BTC
- OKX: 0.01 张 × 0.01 BTC/张 × 1 = 0.0001 BTC
- Binance: 0.001 BTC（直接使用）

### 原始数据（v_raw_data）

`v_raw_data` 返回未经标准化的原始数据，可以看到各交易所 API 返回的真实字段：
- XT: `minqty`, `contractsize`
- OKX: `minsz`, `ctval`, `ctmult`
- Binance: `filters.LOT_SIZE.minQty`

---

## 常见问题

### Q: 为什么需要 3 个视图？

**A**:
- `v_unified_trading_info` / `v_unified_trading_info_wide`: 业务使用，数据已标准化
- `v_raw_data`: 调试和查看原始字段

### Q: 什么时候用 long 格式，什么时候用 wide 格式？

**A**:
- Long 格式（`v_unified_trading_info`）：需要过滤、聚合、分析多个交易所
- Wide 格式（`v_unified_trading_info_wide`）：需要横向对比所有交易所

### Q: 如何从 JSONB 提取字段？

**A**:
```sql
-- 提取为文本
SELECT okx_info->>'min_qty' FROM v_unified_trading_info;

-- 提取为数值
SELECT (okx_info->>'min_qty')::numeric FROM v_unified_trading_info;

-- 提取嵌套字段
SELECT exchange_raw_data->'filters'->0 FROM v_raw_data;
```

### Q: v_raw_data 和 v_unified_trading_info 有什么区别？

**A**:
| 特性 | v_unified_trading_info | v_raw_data |
|------|------------------------|------------|
| 数据内容 | 标准化的核心字段 | 完整的原始字段 |
| 数量单位 | 统一为币本位 | 保持原始单位 |
| 字段数量 | 精选字段 | 所有字段 |
| 用途 | 业务查询、跨交易所比较 | 调试、查看未映射字段 |

---

## 相关文档

- [交易所数量单位说明](../../docs/exchange_quantity_units.md)
- [统一映射表说明](../../docs/unified_mappings.md)
- [OKX ctMult 修复](../../docs/okx_ctmult_fix.md)
- [原始数据视图指南](../../docs/raw_data_view_guide.md)
