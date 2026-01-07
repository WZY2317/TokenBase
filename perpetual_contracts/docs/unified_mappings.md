# 统一映射表设计文档

## 概述

将原来的 `pair_mappings`（列式存储）和 `fuzzy_pair_mappings`（行式存储）合并为一个统一的 `unified_pair_mappings` 表。

## 为什么合并？

### 原有设计的问题

1. **两个表分离**
   - `pair_mappings`: 列式存储，每个交易所一列（binance_symbol, okx_symbol, ...）
   - `fuzzy_pair_mappings`: 行式存储，每个映射一行
   - 需要 UNION 查询才能获取完整的映射信息

2. **扩展性差**
   - `pair_mappings` 添加新交易所需要修改表结构（ADD COLUMN）
   - 维护两套视图和查询逻辑

3. **查询复杂**
   - 需要判断使用哪个表
   - 数据分散在两个地方

### 新设计的优势

1. ✅ **业务逻辑统一**: 精确匹配和模糊匹配都是"映射关系"，只是匹配方式不同
2. ✅ **查询简化**: 一个表、一套视图、一套查询逻辑
3. ✅ **扩展性好**: 添加新交易所只需插入新行，无需修改表结构
4. ✅ **灵活过滤**: 可以轻松按 `match_type` 过滤

## 表结构

### unified_pair_mappings

```sql
CREATE TABLE unified_pair_mappings (
    id SERIAL PRIMARY KEY,

    -- XT 交易对信息
    xt_symbol TEXT NOT NULL,
    xt_base TEXT NOT NULL,
    xt_quote TEXT NOT NULL,
    xt_price NUMERIC(20, 10),
    xt_multiplier INT DEFAULT 1,

    -- 标准化信息
    normalized_pair TEXT NOT NULL,
    normalized_base TEXT NOT NULL,
    normalized_quote TEXT NOT NULL,

    -- 匹配的交易所信息
    exchange TEXT NOT NULL,  -- binance, okx, bybit, gate, kucoin, mexc
    exchange_symbol TEXT NOT NULL,
    exchange_base TEXT,
    exchange_quote TEXT,
    exchange_price NUMERIC(20, 10),
    exchange_multiplier INT DEFAULT 1,

    -- 匹配类型和质量指标
    match_type TEXT NOT NULL CHECK (match_type IN ('exact', 'fuzzy')),
    string_similarity NUMERIC(5, 4),  -- 字符串相似度 (0.0 - 1.0)
    price_diff NUMERIC(10, 6),         -- 价格差异百分比

    -- 元数据
    verified BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 唯一约束
    CONSTRAINT unified_mappings_unique UNIQUE (xt_symbol, exchange)
);
```

### 关键字段说明

- **match_type**: `'exact'` (精确匹配) 或 `'fuzzy'` (模糊匹配)
- **string_similarity**:
  - 精确匹配: 1.0
  - 模糊匹配: 实际相似度值 (如 0.85)
- **price_diff**: 价格差异百分比（如 0.035 表示 3.5%）

## 视图

### 1. v_unified_mappings_summary

按 XT 交易对汇总所有映射:

```sql
SELECT * FROM v_unified_mappings_summary WHERE xt_symbol = 'btc_usdt';
```

返回:
- `total_exchanges`: 总交易所数量
- `exact_exchanges`: 精确匹配数量
- `fuzzy_exchanges`: 模糊匹配数量
- `exchanges`: 交易所列表
- `avg_similarity`: 平均相似度
- `avg_price_diff`: 平均价格差异

### 2. v_exact_mappings

只显示精确匹配:

```sql
SELECT * FROM v_exact_mappings WHERE xt_symbol = 'btc_usdt';
```

### 3. v_fuzzy_mappings

只显示模糊匹配:

```sql
SELECT * FROM v_fuzzy_mappings WHERE xt_symbol = 'aioz_usdt';
```

### 4. v_unified_trading_info

统一交易信息视图（行式，每个映射一行）:

```sql
SELECT
    xt_symbol,
    matched_exchange,
    match_type,
    string_similarity,
    xt_info,
    COALESCE(binance_info, okx_info, bybit_info, gate_info, kucoin_info, mexc_info) as exchange_info
FROM v_unified_trading_info
WHERE xt_symbol = 'btc_usdt';
```

### 5. v_unified_trading_info_wide

统一交易信息宽表视图（列式，每个 XT 交易对一行）:

```sql
SELECT * FROM v_unified_trading_info_wide WHERE xt_symbol = 'btc_usdt';
```

## 迁移步骤

### 1. 创建表

```bash
psql -U your_user -d your_db -f database/unified_mapping_schema.sql
```

### 2. 迁移数据

```bash
psql -U your_user -d your_db -f database/migrate_to_unified_mappings.sql
```

### 3. 创建视图

```bash
psql -U your_user -d your_db -f database/unified_trading_info_view.sql
```

### 4. 测试和验证

```bash
python test_unified_mappings.py
```

## 常用查询示例

### 1. 查看所有映射（精确 + 模糊）

```sql
SELECT * FROM unified_pair_mappings WHERE xt_symbol = 'btc_usdt';
```

### 2. 只查看精确匹配

```sql
SELECT * FROM v_exact_mappings WHERE xt_symbol = 'btc_usdt';
```

### 3. 只查看模糊匹配

```sql
SELECT * FROM v_fuzzy_mappings WHERE xt_symbol = 'aioz_usdt';
```

### 4. 查看某个交易对的覆盖率

```sql
SELECT * FROM v_unified_mappings_summary WHERE xt_symbol = 'btc_usdt';
```

### 5. 查看所有交易所覆盖率统计

```sql
SELECT
    exchange,
    COUNT(*) as total_mappings,
    COUNT(*) FILTER (WHERE match_type = 'exact') as exact_count,
    COUNT(*) FILTER (WHERE match_type = 'fuzzy') as fuzzy_count,
    AVG(string_similarity) as avg_similarity
FROM unified_pair_mappings
GROUP BY exchange
ORDER BY total_mappings DESC;
```

### 6. 查找高质量的模糊匹配

相似度 > 90%, 价格差异 < 1%:

```sql
SELECT * FROM v_fuzzy_mappings
WHERE string_similarity > 0.9 AND ABS(price_diff) < 0.01
ORDER BY string_similarity DESC;
```

### 7. 对比某个 XT 交易对的精确匹配和模糊匹配

```sql
SELECT
    match_type,
    exchange,
    exchange_symbol,
    string_similarity,
    price_diff
FROM unified_pair_mappings
WHERE xt_symbol = 'aioz_usdt'
ORDER BY match_type, exchange;
```

### 8. 查询特定交易所的所有映射

```sql
SELECT
    xt_symbol,
    match_type,
    string_similarity,
    xt_info->>'symbol' as xt_symbol,
    binance_info->>'symbol' as binance_symbol,
    binance_info->>'tick_size' as tick_size,
    binance_info->>'min_qty' as min_qty
FROM v_unified_trading_info
WHERE matched_exchange = 'binance'
ORDER BY xt_symbol;
```

### 9. 提取交易所的 min_qty（动态）

```sql
SELECT
    xt_symbol,
    matched_exchange,
    match_type,
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

## 对比：旧 vs 新

| 操作 | 旧方案 | 新方案 |
|------|--------|--------|
| 查询所有映射 | `SELECT ... FROM pair_mappings UNION SELECT ... FROM fuzzy_pair_mappings` | `SELECT * FROM unified_pair_mappings` |
| 过滤精确匹配 | `SELECT * FROM pair_mappings` | `SELECT * FROM unified_pair_mappings WHERE match_type = 'exact'` |
| 过滤模糊匹配 | `SELECT * FROM fuzzy_pair_mappings` | `SELECT * FROM unified_pair_mappings WHERE match_type = 'fuzzy'` |
| 添加新交易所 | 需要 `ALTER TABLE ADD COLUMN` | 只需 `INSERT` 新行 |
| 查询交易对覆盖率 | 需要复杂的 UNION 和聚合 | `SELECT * FROM v_unified_mappings_summary` |

## 数据完整性验证

运行测试程序会自动验证:

1. ✅ 没有重复的 (xt_symbol, exchange) 映射
2. ✅ 所有精确匹配的 string_similarity = 1.0
3. ✅ 所有映射都有 xt_symbol
4. ✅ 所有映射都有 exchange_symbol

## 后续步骤

确认数据正确后:

1. **（可选）删除旧表**
   ```sql
   DROP TABLE pair_mappings CASCADE;
   DROP TABLE fuzzy_pair_mappings CASCADE;
   ```

2. **更新应用代码**
   - 将所有引用 `pair_mappings` 或 `fuzzy_pair_mappings` 的代码改为 `unified_pair_mappings`
   - 使用新的视图 `v_unified_trading_info` 或 `v_unified_trading_info_wide`

3. **更新生成脚本**
   - 修改 `generate_mappings.py` 输出到 `unified_pair_mappings`
   - 修改 `fuzzy_match.py` 输出到 `unified_pair_mappings`

## 性能考虑

- **索引**: 已在 `xt_symbol`, `exchange`, `match_type`, `normalized_pair` 等关键字段创建索引
- **查询优化**: 使用 `WHERE match_type = 'exact'` 可以利用索引快速过滤
- **视图性能**: `v_unified_trading_info_wide` 使用子查询，对于大量数据可能较慢，建议按需查询

## 文件列表

- `database/unified_mapping_schema.sql` - 统一映射表 schema
- `database/migrate_to_unified_mappings.sql` - 数据迁移脚本
- `database/unified_trading_info_view.sql` - 统一交易信息视图
- `test_unified_mappings.py` - 测试和验证程序
- `docs/unified_mappings.md` - 本文档
