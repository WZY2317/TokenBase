# 项目架构总结

## 🎯 项目目标

解决**跨交易所币种识别问题**：不同交易所对同一币种使用不同的交易对名称。

例如：
- XT: `broccoli_usdt`
- Binance: `BROCCOLI714USDT`
- 同一个币种，但名称完全不同

## 💡 解决方案

使用 **CoinGecko ID** 作为统一标识符，将所有交易所的同一币种关联起来。

```
BTC (Bitcoin)
├─ CoinGecko ID: "bitcoin"
├─ XT:      btc_usdt
├─ Binance: BTCUSDT
├─ OKX:     BTC-USDT-SWAP
├─ Bybit:   BTCUSDT
├─ KuCoin:  BTCUSDTM
└─ MEXC:    BTC_USDT
```

## 🏗️ 系统架构

### 1. 数据层（PostgreSQL）

```
perpetual_trading 数据库
│
├── 7个交易所表（分表设计）
│   ├── binance_perpetual   (577个合约)
│   ├── xt_perpetual        (799个合约)
│   ├── okx_perpetual       (253个合约)
│   ├── bybit_perpetual     (500个合约)
│   ├── gate_perpetual      (待填充)
│   ├── kucoin_perpetual    (539个合约)
│   └── mexc_perpetual      (820个合约)
│
├── 辅助表
│   ├── coingecko_coins     (14,308个币种)
│   └── exchanges           (7个交易所)
│
└── 数据访问层
    ├── get_all_exchanges_by_xt_symbol() -- 函数
    └── v_xt_cross_exchange_mapping      -- 视图
```

**设计原则**:
- ✅ 每个交易所独立表（便于维护和查询优化）
- ✅ 所有表统一字段结构（便于跨表查询）
- ✅ 通过 `coingecko_id` 关联同一币种

### 2. 数据导入层（Python）

```python
fetch_separate_tables.py
│
├── CoinGecko API
│   └── 获取14,308个币种列表（一次性）
│
├── 7个交易所API类
│   ├── BinanceAPI.get_all_perpetuals()
│   ├── XTAPI.get_all_perpetuals()
│   ├── OKXAPI.get_all_perpetuals()
│   ├── BybitAPI.get_all_perpetuals()
│   ├── GateAPI.get_all_perpetuals()       # ✅ 已修复
│   ├── KuCoinAPI.get_all_perpetuals()
│   └── MEXCAPI.get_all_perpetuals()
│
└── 数据处理
    ├── 本地匹配CoinGecko ID（无需重复API调用）
    ├── 批量插入PostgreSQL
    └── 自动更新（ON CONFLICT DO UPDATE）
```

**性能优化**:
- ⚡ 预获取所有CoinGecko币种（1次API调用）
- ⚡ 本地匹配（无网络延迟）
- ⚡ 批量插入（asyncpg）
- ⚡ **总执行时间**: ~10秒

### 3. 查询层（SQL）

#### 核心函数: `get_all_exchanges_by_xt_symbol()`

```sql
输入: XT交易对符号 (如 'btc_usdt')
  ↓
1. 从xt_perpetual获取coingecko_id
  ↓
2. 使用coingecko_id在所有交易所表查询
  ↓
输出: 该币种在所有交易所的配置
```

#### 核心视图: `v_xt_cross_exchange_mapping`

```sql
XT交易对 (773个)
  ↓
LEFT JOIN 其他6个交易所
  ↓
显示: XT → 所有其他交易所的映射和配置
```

## 📊 数据流

```
1. 用户查询
   ↓
   SELECT * FROM get_all_exchanges_by_xt_symbol('btc_usdt');
   ↓
2. 数据库查询
   ↓
   xt_perpetual: btc_usdt → coingecko_id = "bitcoin"
   ↓
3. 跨表查询（通过coingecko_id）
   ↓
   binance_perpetual WHERE coingecko_id = "bitcoin"
   okx_perpetual     WHERE coingecko_id = "bitcoin"
   bybit_perpetual   WHERE coingecko_id = "bitcoin"
   ...
   ↓
4. 合并结果（UNION ALL）
   ↓
5. 返回所有交易所配置
```

## 🎯 核心数据结构

### 统一字段结构

所有交易所表都使用相同的字段：

```
交易对标识
├── symbol          -- 交易对符号（各交易所格式不同）
├── base_asset      -- 基础资产 (BTC, ETH...)
└── quote_asset     -- 计价资产 (USDT, USDC...)

精度配置
├── price_precision
├── quantity_precision
├── tick_size       -- 价格最小变动
└── step_size       -- 数量最小变动

订单限制
├── min_qty         -- 最小下单量
├── max_qty         -- 最大下单量
└── min_notional    -- 最小订单金额

合约规格
├── contract_size   -- 合约乘数 ⭐
└── max_leverage    -- 最大杠杆

费率
├── maker_fee
└── taker_fee

映射
└── coingecko_id    -- CoinGecko统一ID ⭐⭐⭐
```

## 📈 数据覆盖

```
总合约数: 3,488
CoinGecko映射成功: 3,301 (94.6%)

各交易所:
├─ MEXC:    820 (匹配率 90.9%)
├─ XT:      799 (匹配率 93.2%)
├─ Binance: 577 (匹配率 96.7%)
├─ KuCoin:  539 (匹配率 98.0%)
├─ Bybit:   500 (匹配率 94.4%)
├─ OKX:     253 (匹配率 100.0%)
└─ Gate:    待填充（已修复API解析）

XT跨交易所映射:
├─ 总XT交易对: 773
├─ 有Binance映射: 518 (67.0%)
├─ 有OKX映射:     262 (33.9%)
├─ 有Bybit映射:   418 (54.1%)
├─ 有KuCoin映射:  491 (63.5%)
└─ 有MEXC映射:    582 (75.3%)
```

## 🛠️ 技术栈

### 数据库
- PostgreSQL 14+
- 分表设计
- 函数 + 视图

### 后端
- Python 3.8+
- asyncpg (异步PostgreSQL驱动)
- requests (HTTP客户端)

### 数据源
- CoinGecko API (免费版)
- 7个交易所公开API

## ⚡ 性能优化

### 查询性能
- ✅ 分表设计 → 单表查询不需要WHERE过滤
- ✅ 索引优化 → symbol, base_asset, coingecko_id
- ✅ 视图缓存 → 可创建物化视图进一步优化

### 导入性能
- ✅ 预获取CoinGecko → 1次API调用
- ✅ 本地匹配 → 无网络延迟
- ✅ 批量插入 → asyncpg异步操作
- ✅ **从20分钟优化到10秒**

## ⚠️ 已知限制

1. **CoinGecko匹配率**
   - 94.6%的合约成功匹配
   - 5.4%无法匹配（新币种、小众币种）

2. **交易所符号格式差异**
   - 已处理：通过coingecko_id统一
   - 示例：btc_usdt, BTCUSDT, BTC-USDT-SWAP 都映射到 "bitcoin"

3. **数据时效性**
   - 合约配置可能随时变化
   - 建议每天更新一次

4. **API限制**
   - CoinGecko免费版: 50次/分钟
   - 当前设计仅需1次调用 ✅

## 🎯 使用场景

### 场景1: 跨交易所套利
```sql
-- 查询BTC在所有交易所的配置，比较最小下单量
SELECT exchange, symbol, min_qty, tick_size
FROM get_all_exchanges_by_xt_symbol('btc_usdt')
ORDER BY min_qty;
```

### 场景2: 选择最佳交易所
```sql
-- 使用视图快速对比
SELECT xt_symbol, coin_name,
       binance_min_qty, okx_min_qty, bybit_min_qty
FROM v_xt_cross_exchange_mapping
WHERE xt_symbol = 'eth_usdt';
```

### 场景3: 币种覆盖率分析
```sql
-- 统计每个币种在几个交易所上市
SELECT base_asset,
       SUM(CASE WHEN binance_symbol IS NOT NULL THEN 1 ELSE 0 END) as on_binance,
       SUM(CASE WHEN okx_symbol IS NOT NULL THEN 1 ELSE 0 END) as on_okx
FROM v_xt_cross_exchange_mapping
GROUP BY base_asset;
```

## 📚 文档结构

```
TokenBase/
├── README.md                      -- 项目总览
├── AGENTS.md                      -- 架构总结（本文档）
├── DATABASE_SCHEMA.md             -- 数据库结构详解
├── QUERY_EXAMPLES.md              -- SQL查询示例
├── SEPARATE_TABLES_GUIDE.md       -- 分表设计说明
│
├── create_separate_tables_db.sql  -- 数据库创建脚本
├── fetch_separate_tables.py       -- 数据导入脚本 ⭐
│
└── requirements.txt               -- Python依赖
```

## 🔮 未来改进

### 短期
- [x] 修复Gate.io API解析
- [ ] 修复XT数据为0的问题
- [ ] 过滤Bybit非永续合约
- [ ] 添加数据验证

### 中期
- [ ] 添加实时价格数据
- [ ] 添加历史数据存储
- [ ] 支持更多交易所
- [ ] API接口封装

### 长期
- [ ] 自动套利机器人
- [ ] 实时价差监控
- [ ] WebSocket实时数据
- [ ] 图形化界面

---

**项目版本**: 1.0  
**创建日期**: 2026-01-05  
**最后更新**: 2026-01-05
