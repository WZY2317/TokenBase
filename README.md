# 永续合约跨交易所数据库系统

**版本**: 1.0  
**日期**: 2026-01-05

---

## 🎯 项目简介

这是一个**永续合约跨交易所查询系统**，解决了不同交易所对同一币种使用不同交易对名称的问题。

### 核心功能

✅ **统一币种识别** - 通过CoinGecko ID准确识别跨交易所的同一币种  
✅ **快速数据导入** - 10秒内完成3,488个合约的导入  
✅ **跨交易所查询** - 通过XT交易对查询所有交易所配置  
✅ **高匹配率** - 94.6%的合约成功匹配CoinGecko ID  

### 支持的交易所

- **Binance** (币安) - 577个合约
- **XT.COM** - 799个合约
- **OKX** - 253个合约
- **Bybit** - 500个合约
- **KuCoin** - 539个合约
- **MEXC** - 820个合约
- **Gate.io** - 待修复

---

## 🚀 快速开始

### 1. 环境要求

- PostgreSQL 14+
- Python 3.8+
- 依赖包：`asyncpg`, `requests`

```bash
pip install -r requirements.txt
```

### 2. 创建数据库

```bash
psql -U oliver -h 127.0.0.1 -p 5432 -d postgres -f create_separate_tables_db.sql
```

### 3. 导入数据

```bash
python3 fetch_separate_tables.py
```

**执行时间**: ~10秒  
**导入数据**: 3,488个合约 + 14,308个CoinGecko币种

### 4. 验证安装

```sql
-- 连接数据库
psql -U oliver -h 127.0.0.1 -p 5432 -d perpetual_trading

-- 查询BTC在所有交易所的配置
SELECT * FROM get_all_exchanges_by_xt_symbol('btc_usdt');

-- 查看视图数据
SELECT xt_symbol, coin_name, binance_symbol, okx_symbol, bybit_symbol
FROM v_xt_cross_exchange_mapping
WHERE base_asset = 'BTC'
LIMIT 5;
```

---

## 📊 核心设计

### 数据库架构

```
perpetual_trading 数据库
├── 7个交易所表（独立表，统一字段）
│   ├── binance_perpetual
│   ├── xt_perpetual
│   ├── okx_perpetual
│   ├── bybit_perpetual
│   ├── gate_perpetual
│   ├── kucoin_perpetual
│   └── mexc_perpetual
│
├── 辅助表
│   ├── coingecko_coins      (14,308个币种)
│   └── exchanges            (7个交易所信息)
│
├── 核心函数
│   └── get_all_exchanges_by_xt_symbol()
│
└── 核心视图
    └── v_xt_cross_exchange_mapping
```

### 统一字段结构

所有交易所表都使用**相同的字段**：

```sql
symbol              VARCHAR(50)      -- 交易对符号
base_asset          VARCHAR(50)      -- 基础资产 (BTC, ETH...)
quote_asset         VARCHAR(20)      -- 计价资产 (USDT, USDC...)

-- 精度
price_precision     INTEGER          -- 价格精度
quantity_precision  INTEGER          -- 数量精度
tick_size           DECIMAL(30,15)   -- 价格最小变动
step_size           DECIMAL(30,15)   -- 数量最小变动

-- 订单限制
min_qty             DECIMAL(30,15)   -- 最小下单量
max_qty             DECIMAL(30,15)   -- 最大下单量
min_notional        DECIMAL(30,15)   -- 最小订单金额

-- 合约规格
contract_size       DECIMAL(30,15)   -- 合约乘数 ⭐
max_leverage        INTEGER          -- 最大杠杆

-- 费率
maker_fee           DECIMAL(10,6)    -- Maker费率
taker_fee           DECIMAL(10,6)    -- Taker费率

-- 映射
coingecko_id        VARCHAR(100)     -- CoinGecko ID ⭐⭐⭐
```

---

## 💡 使用示例

### 示例1: 查询BTC在所有交易所的配置

```sql
SELECT * FROM get_all_exchanges_by_xt_symbol('btc_usdt');
```

**返回结果**:
```
exchange | symbol        | tick_size | min_qty | contract_size | max_leverage
---------|---------------|-----------|---------|---------------|-------------
binance  | BTCUSDT       | 0.1       | 0.001   | 1             | -
bybit    | BTCUSDT       | 0.1       | 0.001   | 1             | 100
mexc     | BTC_USDT      | 0.1       | 1       | 1             | -
okx      | BTC-USDT-SWAP | 0.1       | 0.01    | 0.01          | -
xt       | btc_usdt      | 0         | 0       | 0.0001        | -
```

### 示例2: 使用视图查询跨交易所信息

```sql
SELECT
    xt_symbol,
    coin_name,
    binance_symbol,
    binance_tick_size,
    binance_min_qty,
    okx_symbol,
    okx_min_qty
FROM v_xt_cross_exchange_mapping
WHERE xt_symbol = 'eth_usdt'
LIMIT 1;
```

### 示例3: 查找在最多交易所上市的币种

```sql
SELECT
    xt_symbol,
    coin_name,
    (CASE WHEN binance_symbol IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN okx_symbol IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN bybit_symbol IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN kucoin_symbol IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN mexc_symbol IS NOT NULL THEN 1 ELSE 0 END) as exchange_count,
    binance_symbol,
    okx_symbol,
    bybit_symbol
FROM v_xt_cross_exchange_mapping
ORDER BY exchange_count DESC
LIMIT 20;
```

更多示例请查看 `QUERY_EXAMPLES.md`

---

## 📁 项目文件

| 文件 | 说明 |
|------|------|
| `README.md` | 项目总览（本文档） |
| `DATABASE_SCHEMA.md` | 数据库结构详细文档 |
| `QUERY_EXAMPLES.md` | SQL查询示例集合 |
| `SEPARATE_TABLES_GUIDE.md` | 分表设计说明 |
| `AGENTS.md` | 架构设计总结 |
| `create_separate_tables_db.sql` | 数据库创建脚本 |
| `fetch_separate_tables.py` | 数据导入脚本 |
| `requirements.txt` | Python依赖 |

---

## 🎨 设计优势

### 相比单表设计

| 特性 | 单表设计 | 分表设计 ✅ |
|------|---------|-----------|
| 查询单交易所 | `WHERE exchange='xt'` | 直接查 `xt_perpetual` ⚡ |
| 查询性能 | 全表扫描 | 只扫描单表 ⚡ |
| 索引优化 | 影响所有数据 | 独立优化 ⚡ |
| 数据维护 | 混合管理 | 独立清晰 ⚡ |
| 数据隔离 | 无 | 完全隔离 ⚡ |

### 相比不统一字段设计

| 特性 | 不同字段 | 统一字段 ✅ |
|------|---------|-----------|
| 查询复杂度 | 高 | 低 ⚡ |
| 跨表JOIN | 困难 | 简单 ⚡ |
| 代码复用 | 低 | 高 ⚡ |
| 学习成本 | 高 | 低 ⚡ |

---

## 📈 数据统计

```
总合约数: 3,488
CoinGecko映射: 3,301 (94.6%)
唯一币种: ~860

交易所分布:
├─ MEXC:    820 (匹配率 90.9%)
├─ XT:      799 (匹配率 93.2%)
├─ Binance: 577 (匹配率 96.7%)
├─ KuCoin:  539 (匹配率 98.0%)
├─ Bybit:   500 (匹配率 94.4%)
├─ OKX:     253 (匹配率 100.0%)
└─ Gate:    0   (待修复)

视图覆盖:
v_xt_cross_exchange_mapping: 773个XT交易对
├─ 有Binance映射: 518 (67.0%)
├─ 有OKX映射:     262 (33.9%)
├─ 有Bybit映射:   418 (54.1%)
├─ 有KuCoin映射:  491 (63.5%)
└─ 有MEXC映射:    582 (75.3%)
```

---

## 🔄 数据更新

### 日常更新流程

```bash
# 重新导入所有数据（会更新现有记录）
python3 fetch_separate_tables.py
```

**建议频率**: 每天更新一次

---

## ⚠️ 已知问题

### 1. XT数据全为0

**现象**: XT表的 `tick_size` 和 `min_qty` 全为0  
**影响**: 无法准确比较XT的交易规格  
**状态**: 待修复  

### 2. Bybit包含非永续合约

**现象**: Bybit返回带日期的合约（如 `ETHUSDT-09JAN26`）  
**影响**: 视图中会出现重复记录  
**解决**: 在查询时过滤掉带日期的合约

### 3. Gate.io数据为空

**现象**: gate_perpetual表为空  
**原因**: API解析错误  
**状态**: 待修复  

---

**最后更新**: 2026-01-05  
**数据库版本**: PostgreSQL 14+  
**Python版本**: 3.8+  
