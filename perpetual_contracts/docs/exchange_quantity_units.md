# 各交易所数量单位说明

## 概述

不同交易所的永续合约，**数量字段的单位不统一**：
- 有些是**币本位**（如 1 BTC）
- 有些是**张数**（需要乘以合约面值才能得到币数量）

## 各交易所单位详情

| 交易所 | 数量单位 | 换算公式 | 举例（BTC-USDT） |
|--------|---------|---------|------------------|
| **XT** | 张数 | `张数 × contract_size` | 1 张 × 0.0001 BTC/张 = 0.0001 BTC |
| **Binance** | **币本位** | 直接使用 | 0.001 BTC = 0.001 BTC |
| **OKX** | 张数 | `张数 × ctVal × ctMult` | 0.01 张 × 0.01 BTC/张 × 1 = 0.0001 BTC |
| **Bybit** | **币本位** | 直接使用 | 0.001 BTC = 0.001 BTC |
| **Gate** | 张数 | `张数 × contract_size` | 1 张 × 0.0001 BTC/张 = 0.0001 BTC |
| **KuCoin** | **币本位** | 直接使用 | 1 BTC = 1 BTC |
| **MEXC** | 张数 | `张数 × contract_size` | 1 张 × 0.0001 BTC/张 = 0.0001 BTC |

## 详细说明

### 1. XT

- **API 字段**：`minqty`, `contractsize`
- **单位**：张数
- **换算**：`币数量 = minqty × contractsize`
- **示例**：BTC-USDT
  - minqty = 1 张
  - contractsize = 0.0001 BTC/张
  - **最小下单量 = 0.0001 BTC**

### 2. Binance

- **API 字段**：`filters.LOT_SIZE.minQty`
- **单位**：**币本位（BTC）**
- **换算**：无需换算
- **示例**：BTC-USDT
  - minQty = 0.001 BTC
  - **最小下单量 = 0.001 BTC**

### 3. OKX ⚠️

- **API 字段**：`minSz`, `ctVal`, `ctMult`
- **单位**：张数
- **换算**：`币数量 = minSz × ctVal × ctMult`
- **示例**：BTC-USDT-SWAP
  - minSz = 0.01 张
  - ctVal = 0.01 BTC/张（合约面值）
  - ctMult = 1（合约乘数）
  - **最小下单量 = 0.01 × 0.01 × 1 = 0.0001 BTC**

**重要**：
- OKX 的数量单位容易被误解为币本位，但实际上是**张数**！
- 完整换算公式需要同时考虑 `ctVal`（合约面值）和 `ctMult`（合约乘数）
- 目前所有 USDT 永续合约的 `ctMult = 1`，但未来可能会有 `ctMult ≠ 1` 的情况

### 4. Bybit

- **API 字段**：`lotSizeFilter.minOrderQty`
- **单位**：**币本位（BTC）**
- **换算**：无需换算
- **示例**：BTC-USDT
  - minOrderQty = 0.001 BTC
  - **最小下单量 = 0.001 BTC**

### 5. Gate

- **API 字段**：`order_size_min`, `quanto_multiplier`
- **单位**：张数
- **换算**：`币数量 = order_size_min × quanto_multiplier`
- **示例**：BTC_USDT
  - order_size_min = 1 张
  - quanto_multiplier = 0.0001 BTC/张
  - **最小下单量 = 0.0001 BTC**

### 6. KuCoin

- **API 字段**：`lotSize`, `multiplier`
- **单位**：**币本位（BTC）**
- **换算**：无需换算
- **示例**：XBTUSDTM
  - lotSize = 1 BTC（步长）
  - multiplier = 0.001 BTC（面值，但数量已经是币本位）
  - **数量单位 = BTC**

### 7. MEXC

- **API 字段**：`minVol`, `contractSize`
- **单位**：张数
- **换算**：`币数量 = minVol × contractSize`
- **示例**：BTC_USDT
  - minVol = 1 张
  - contractSize = 0.0001 BTC/张
  - **最小下单量 = 0.0001 BTC**

## 在代码中的处理

### v_trading_info_flat_complete（原始数据）

保留各交易所的原始单位，**不做换算**：

```sql
SELECT
    xt_min_qty,      -- '1' (1张)
    bn_min_qty,      -- '0.001' (0.001 BTC)
    okx_min_qty,     -- '0.01' (0.01张)
    bb_min_qty       -- '0.001' (0.001 BTC)
FROM v_trading_info_flat_complete
WHERE xt_symbol = 'btc_usdt';
```

❌ **无法直接比较**！

### v_trading_info_flat_normalized（标准化数据）

所有数量字段统一换算为**币本位**：

```sql
SELECT
    xt_min_qty,      -- 0.0001 BTC (1张 × 0.0001 BTC/张)
    bn_min_qty,      -- 0.001 BTC
    okx_min_qty,     -- 0.0001 BTC (0.01张 × 0.01 BTC/张)
    bb_min_qty       -- 0.001 BTC
FROM v_trading_info_flat_normalized
WHERE xt_symbol = 'btc_usdt';
```

✅ **可以直接比较**！

## 实现细节

### XT / Gate / MEXC（张数 → 币本位）

```sql
CASE
    WHEN info->>'min_qty' IS NOT NULL
    THEN (info->>'min_qty')::numeric * NULLIF((info->>'contract_size')::numeric, 0)
END AS min_qty
```

### OKX（张数 → 币本位）

```sql
CASE
    WHEN okx_info->>'min_qty' IS NOT NULL
    THEN (okx_info->>'min_qty')::numeric
         * NULLIF((okx_info->>'contract_size')::numeric, 0)
         * NULLIF((okx_info->>'contract_multiplier')::numeric, 0)
END AS okx_min_qty
```

### Binance / Bybit / KuCoin（已经是币本位）

```sql
binance_info->>'min_qty' AS bn_min_qty
```

## 验证示例

查询 BTC-USDT 各交易所的最小下单量：

```sql
SELECT
    xt_symbol,
    xt_min_qty AS xt_min_btc,
    bn_min_qty AS bn_min_btc,
    okx_min_qty AS okx_min_btc,
    bb_min_qty AS bb_min_btc,
    gt_min_qty AS gt_min_btc,
    mx_min_qty AS mx_min_btc
FROM v_trading_info_flat_normalized
WHERE xt_symbol = 'btc_usdt';
```

期望结果：

| 交易所 | 最小下单量（BTC） |
|--------|------------------|
| XT | 0.0001 |
| Binance | 0.001 |
| OKX | 0.0001 |
| Bybit | 0.001 |
| Gate | 0.0001 |
| MEXC | 0.0001 |

## 常见错误

### ❌ 错误 1: 假设 OKX 是币本位

```sql
-- 错误：直接使用 minsz
okx_info->>'min_qty' AS okx_min_qty  -- 0.01 (单位是张！)
```

### ✅ 正确：换算为币本位

```sql
-- 正确：张数 × ctval
(okx_info->>'min_qty')::numeric * NULLIF((okx_info->>'contract_size')::numeric, 0)
-- 结果: 0.0001 BTC
```

### ❌ 错误 2: 对 Binance 做换算

```sql
-- 错误：Binance 已经是币本位，不需要换算
(bn_info->>'min_qty')::numeric * contract_size  -- 错误！
```

### ✅ 正确：直接使用

```sql
-- 正确：Binance 已经是币本位
binance_info->>'min_qty' AS bn_min_qty  -- 0.001 BTC
```

## 总结

| 需要换算的交易所 | 直接使用的交易所 |
|-----------------|-----------------|
| XT<br>OKX ⚠️<br>Gate<br>MEXC | Binance<br>Bybit<br>KuCoin |

**记住**：
- 使用 `v_trading_info_flat_complete` 查看原始数据
- **优先使用 `v_trading_info_flat_normalized` 进行跨交易所比较**
- OKX 虽然看起来像币本位，但实际上是张数！
