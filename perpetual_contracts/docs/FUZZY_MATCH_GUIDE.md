# 模糊匹配系统使用指南

## 概述

模糊匹配系统用于查找 base_asset 名称相似但不完全相同的交易对，例如：
- XT: `broccoli_usdt` (base=broccoli)
- Binance: `BROCCOLI714USDT` (base=BROCCOLI714)

这些交易对无法通过精确匹配找到，但通过字符串相似度 + 价格验证可以确认它们是同一个币种。

## 设计原则

1. **与精确匹配分离**: 模糊匹配结果存储在单独的 `fuzzy_pair_mappings` 表中，不与 `pair_mappings` 混合
2. **只保留真正的模糊匹配**: 相似度 = 100% 的记录会被自动过滤，因为它们应该在精确匹配中
3. **双重验证**: 使用字符串相似度（阈值 70%）+ 价格匹配（阈值 5%）确保准确性

## 数据库表结构

### fuzzy_pair_mappings

存储所有模糊匹配记录（一对一关系：一个 XT 交易对在一个交易所只有一条记录）

主要字段：
- `xt_symbol`, `xt_base`, `xt_quote`, `xt_price`: XT 交易对信息
- `exchange`: 匹配到的交易所（binance, okx, bybit, gate, kucoin, mexc）
- `exchange_symbol`, `exchange_base`, `exchange_quote`, `exchange_price`: 交易所交易对信息
- `string_similarity`: 字符串相似度分数 (0.0 - 1.0)
- `price_diff`: 价格差异百分比
- `verified`: 是否已人工验证

### v_fuzzy_mappings_summary

汇总视图，按 XT 交易对汇总：
- 显示每个 XT 交易对匹配到了哪些交易所
- 平均相似度和平均价格差异
- 匹配到的交易所数量

## 使用方法

### 1. 运行模糊匹配

```bash
python3 fuzzy_match.py
```

这会：
1. 查找所有未映射或部分映射的 XT 交易对
2. 在各交易所中查找相似的交易对（相似度 >= 70%）
3. 通过价格验证确认匹配（价格差异 <= 5%）
4. 保存结果到数据库和文件（`fuzzy_matches.txt`）
5. 自动过滤相似度 = 100% 的记录

### 2. 查询模糊匹配

#### 查看所有模糊匹配
```sql
SELECT * FROM fuzzy_pair_mappings ORDER BY xt_symbol, exchange;
```

#### 查看特定 XT 交易对的模糊匹配
```sql
SELECT * FROM fuzzy_pair_mappings WHERE xt_symbol = 'broccoli_usdt';
```

#### 查看汇总信息
```sql
SELECT * FROM v_fuzzy_mappings_summary;
```

#### 查看高质量模糊匹配（相似度 > 90%，价格差异 < 1%）
```sql
SELECT * FROM fuzzy_pair_mappings
WHERE string_similarity > 0.9 AND price_diff < 0.01
ORDER BY string_similarity DESC;
```

#### 查看某个交易所的所有模糊匹配
```sql
SELECT * FROM fuzzy_pair_mappings WHERE exchange = 'binance';
```

### 3. 验证模糊匹配结果

```bash
python3 test_fuzzy_match.py
```

这会生成详细的验证报告，包括：
- 总体统计
- 各交易所统计
- 相似度分布
- 所有模糊匹配详情
- 按 XT 交易对汇总

## 当前结果

**总计**: 9 个模糊匹配记录，涉及 6 个 XT 交易对

### 相似度分布
- 95-99%: 1 个（broccoli）
- 80-89%: 2 个（1mbabydoge）
- 70-79%: 6 个（aioz, usde, beamx, dodo）

### 各交易所统计
- Binance: 4 个模糊匹配
- MEXC: 3 个模糊匹配
- Bybit: 2 个模糊匹配

### 典型案例

#### 1. broccoli_usdt -> BROCCOLI714USDT (Binance)
- **相似度**: 95.0%
- **价格差异**: 0.19%
- **说明**: Binance 在币种名称后添加了 "714" 后缀

#### 2. 1mbabydoge_usdt -> 1000000BABYDOGEUSDT (Bybit/MEXC)
- **相似度**: 80.0%
- **价格差异**: 0.05-0.10%
- **说明**: XT 使用 "1m" 表示 1000000，其他交易所写全称

#### 3. aioz_usdt -> AIOTUSDT (Binance/MEXC)
- **相似度**: 75.0%
- **价格差异**: 2.20%
- **说明**: 可能是同一个项目的不同代币，需要人工确认

## 注意事项

1. **人工验证**: 模糊匹配结果需要人工确认，特别是相似度 < 90% 的记录
2. **价格差异**: 虽然通过了 5% 阈值，但仍需关注价格差异较大的匹配（如 aioz_usdt）
3. **定期更新**: 交易所可能上线新币种，建议定期运行模糊匹配
4. **与精确匹配的关系**: 模糊匹配是精确匹配的补充，用于特殊情况

## 常见问题

### Q: 为什么某些交易对没有在模糊匹配中出现？
A: 可能原因：
1. 相似度 < 70%（阈值过滤）
2. 价格差异 > 5%（价格验证失败）
3. 相似度 = 100%（应该在精确匹配中）
4. 该交易对在 XT 已完全映射到所有可能的交易所

### Q: 如何调整相似度阈值？
A: 修改 `fuzzy_match.py` 中的 `similarity_threshold` 参数（默认 0.7）

### Q: 如何调整价格差异阈值？
A: 修改 `fuzzy_match.py` 中的 `price_threshold` 参数（默认 0.05 即 5%）

## 工具文件

- `fuzzy_match.py`: 主要的模糊匹配工具
- `test_fuzzy_match.py`: 验证报告生成工具
- `database/fuzzy_mapping_schema.sql`: 数据库表结构
- `fuzzy_matches.txt`: 模糊匹配结果文本文件
