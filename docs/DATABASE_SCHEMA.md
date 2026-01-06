# 永续合约数据库结构文档

## 📊 数据库概览

**数据库名**: `perpetual_trading`  
**设计理念**: 每个交易所独立表 + 统一字段结构  
**核心功能**: 通过CoinGecko ID实现跨交易所币种映射

---

## 📁 表结构

### 1. 交易所合约表（7张）

所有交易所表都使用**完全相同的字段结构**：

```sql
binance_perpetual
xt_perpetual
okx_perpetual
bybit_perpetual
gate_perpetual
kucoin_perpetual
mexc_perpetual
```

#### 统一字段定义

```sql
CREATE TABLE {exchange}_perpetual (
    -- 主键
    id SERIAL PRIMARY KEY,
    
    -- 交易对标识
    symbol VARCHAR(50) UNIQUE NOT NULL,        -- 交易对符号（各交易所格式不同）
    base_asset VARCHAR(50) NOT NULL,           -- 基础资产 (BTC, ETH...)
    quote_asset VARCHAR(20) NOT NULL,          -- 计价资产 (USDT, USDC...)
    
    -- 精度配置
    price_precision INTEGER,                   -- 价格小数位数
    quantity_precision INTEGER,                -- 数量小数位数
    tick_size DECIMAL(30, 15),                -- 价格最小变动单位
    step_size DECIMAL(30, 15),                -- 数量最小变动单位
    
    -- 订单限制
    min_qty DECIMAL(30, 15),                  -- 最小下单数量
    max_qty DECIMAL(30, 15),                  -- 最大下单数量
    min_notional DECIMAL(30, 15),             -- 最小订单金额
    
    -- 合约规格
    contract_size DECIMAL(30, 15) DEFAULT 1,   -- 合约乘数/面值 ⭐
    max_leverage INTEGER,                      -- 最大杠杆倍数
    
    -- 费率
    maker_fee DECIMAL(10, 6),                 -- Maker手续费率
    taker_fee DECIMAL(10, 6),                 -- Taker手续费率
    
    -- 状态和映射
    status VARCHAR(20) DEFAULT 'TRADING',      -- 合约状态
    coingecko_id VARCHAR(100),                -- CoinGecko统一ID ⭐⭐⭐
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 索引配置

每个交易所表都有相同的索引：

```sql
CREATE INDEX idx_{exchange}_symbol ON {exchange}_perpetual(symbol);
CREATE INDEX idx_{exchange}_base ON {exchange}_perpetual(base_asset);
CREATE INDEX idx_{exchange}_coingecko ON {exchange}_perpetual(coingecko_id);
```

---

### 2. CoinGecko币种信息表

```sql
CREATE TABLE coingecko_coins (
    id SERIAL PRIMARY KEY,
    coingecko_id VARCHAR(100) UNIQUE NOT NULL,  -- CoinGecko唯一ID
    symbol VARCHAR(50) NOT NULL,                -- 币种符号 (BTC, ETH...)
    name VARCHAR(100) NOT NULL,                 -- 币种名称 (Bitcoin, Ethereum...)
    market_cap_rank INTEGER,                    -- 市值排名（保留字段）
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_coingecko_symbol ON coingecko_coins(symbol);
```

**当前数据**: 14,308个币种

---

### 3. 交易所信息表

```sql
CREATE TABLE exchanges (
    id SERIAL PRIMARY KEY,
    exchange_id VARCHAR(20) UNIQUE NOT NULL,    -- 交易所ID
    exchange_name VARCHAR(50) NOT NULL,         -- 交易所名称
    table_name VARCHAR(50) NOT NULL,            -- 对应的表名
    api_base_url VARCHAR(200),                  -- API基础URL
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**初始数据**:
```sql
INSERT INTO exchanges (exchange_id, exchange_name, table_name, api_base_url) VALUES
    ('binance', 'Binance', 'binance_perpetual', 'https://fapi.binance.com'),
    ('okx', 'OKX', 'okx_perpetual', 'https://www.okx.com'),
    ('bybit', 'Bybit', 'bybit_perpetual', 'https://api.bybit.com'),
    ('gate', 'Gate.io', 'gate_perpetual', 'https://api.gateio.ws'),
    ('kucoin', 'KuCoin', 'kucoin_perpetual', 'https://api-futures.kucoin.com'),
    ('mexc', 'MEXC', 'mexc_perpetual', 'https://contract.mexc.com'),
    ('xt', 'XT.COM', 'xt_perpetual', 'https://fapi.xt.com');
```

---

## 🔧 核心函数

### `get_all_exchanges_by_xt_symbol(xt_symbol)`

**功能**: 通过XT交易对查询该币种在所有交易所的配置

**参数**:
- `xt_symbol` - XT交易对符号（如：'btc_usdt'）

**返回字段**:
```sql
exchange        VARCHAR  -- 交易所名称
symbol          VARCHAR  -- 交易对符号
base_asset      VARCHAR  -- 基础资产
quote_asset     VARCHAR  -- 计价资产
tick_size       DECIMAL  -- 价格最小变动
step_size       DECIMAL  -- 数量最小变动
min_qty         DECIMAL  -- 最小下单量
max_qty         DECIMAL  -- 最大下单量
min_notional    DECIMAL  -- 最小订单金额
contract_size   DECIMAL  -- 合约乘数
max_leverage    INTEGER  -- 最大杠杆
```

**实现逻辑**:
1. 从 `xt_perpetual` 表获取该交易对的 `coingecko_id`
2. 使用该 `coingecko_id` 在所有交易所表中查询
3. 通过 UNION ALL 合并结果

**使用示例**:
```sql
-- 查询BTC在所有交易所的配置
SELECT * FROM get_all_exchanges_by_xt_symbol('btc_usdt');

-- 查询ETH并比较最小下单量
SELECT exchange, symbol, min_qty
FROM get_all_exchanges_by_xt_symbol('eth_usdt')
ORDER BY min_qty;
```

---

## 👁️ 视图

### `v_xt_cross_exchange_mapping`

**功能**: XT交易对到其他交易所的一对多映射视图

**设计**: 以XT为基准，左连接其他所有交易所

**字段结构**:
```
XT基础信息:
  - xt_symbol, base_asset, quote_asset
  - coingecko_id, coin_name

XT配置:
  - xt_tick_size, xt_step_size, xt_min_qty
  - xt_contract_size, xt_max_leverage

其他交易所（Binance, OKX, Bybit, Gate, KuCoin, MEXC）:
  每个交易所6个字段:
  - {exchange}_symbol
  - {exchange}_tick_size
  - {exchange}_step_size
  - {exchange}_min_qty
  - {exchange}_contract_size
  - {exchange}_max_leverage
```

**使用场景**: 快速查看一个XT交易对在其他所有交易所的对应配置

---

## 📈 数据统计

### 各交易所合约数量

```
总合约数: 3,488
CoinGecko映射: 3,301 (94.6%)

交易所分布:
├─ MEXC:    820 (匹配率 90.9%)
├─ XT:      799 (匹配率 93.2%)
├─ Binance: 577 (匹配率 96.7%)
├─ KuCoin:  539 (匹配率 98.0%)
├─ Bybit:   500 (匹配率 94.4%)
├─ OKX:     253 (匹配率 100.0%)
└─ Gate:    待填充（已修复）
```

### 视图覆盖率

```
v_xt_cross_exchange_mapping:
├─ XT交易对: 773 (已匹配CoinGecko ID)
├─ Binance: 518 (67.0%)
├─ OKX:     262 (33.9%)
├─ Bybit:   418 (54.1%)
├─ KuCoin:  491 (63.5%)
├─ MEXC:    582 (75.3%)
└─ Gate:    待填充
```

---

## 🔄 数据更新流程

### 1. 数据库创建
```bash
psql -U oliver -h 127.0.0.1 -p 5432 -d postgres -f create_separate_tables_db.sql
```

### 2. 数据填充
```bash
python3 fetch_separate_tables.py
```

**执行流程**:
1. 从CoinGecko获取所有币种列表（14,308个）
2. 从7个交易所API获取合约数据
3. 本地匹配CoinGecko ID
4. 批量插入到对应的交易所表
5. 更新 `coingecko_coins` 表

**执行时间**: ~10秒

---

## 🎯 设计优势

### 相比单表设计

| 项目 | 单表设计 | 分表设计 ✅ |
|------|---------|-----------|
| 查询单个交易所 | WHERE exchange='xt' | 直接查xt_perpetual ⚡ |
| 表结构维护 | 混在一起 | 独立清晰 ⚡ |
| 添加索引 | 影响所有数据 | 只影响单个交易所 ⚡ |
| 数据隔离 | 无 | 完全隔离 ⚡ |
| 字段统一性 | 统一 | 统一 ✅ |

### 相比不同字段设计

| 项目 | 不同字段 | 统一字段 ✅ |
|------|---------|-----------|
| 查询复杂度 | 高（需记住各表字段） | 低 ⚡ |
| 跨表查询 | 困难 | 简单 ⚡ |
| 维护成本 | 高 | 低 ⚡ |
| 代码复用 | 低 | 高 ⚡ |

---

## ⚠️ 已知问题

### 1. XT数据为0
- **现象**: XT表的 tick_size 和 min_qty 全为0
- **原因**: XT API返回数据可能有问题
- **影响**: 无法准确比较XT的交易规格
- **待办**: 检查XT API文档，修复数据解析

### 2. Bybit包含非永续合约
- **现象**: Bybit数据中包含带日期的合约（如 ETHUSDT-09JAN26）
- **原因**: Bybit API返回了定期合约，不仅是永续合约
- **影响**: 视图中会出现重复记录
- **建议**: 在视图或查询中过滤掉带日期的合约

### 3. Gate.io数据问题
- **现象**: Gate.io数据解析错误
- **状态**: 已修复（修改了price_round解析逻辑）
- **操作**: 重新运行 `python3 fetch_separate_tables.py`

---

## 📚 相关文档

- `SEPARATE_TABLES_GUIDE.md` - 分表设计说明
- `QUERY_EXAMPLES.md` - 查询示例
- `README.md` - 项目总览
- `AGENTS.md` - 架构设计
- `create_separate_tables_db.sql` - 数据库创建脚本
- `fetch_separate_tables.py` - 数据填充脚本

---

**最后更新**: 2026-01-05  
**PostgreSQL版本**: 14+  
**Python版本**: 3.8+
