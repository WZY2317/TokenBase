# OKX 数量单位完整说明

## 问题发现

在实现交易所数量单位标准化时，发现 OKX 的数量换算公式不完整。

## OKX 的三个关键字段

OKX 永续合约的数量计算涉及三个字段：

1. **minSz / maxLmtSz / maxMktSz**：张数（下单数量）
2. **ctVal**：合约面值（Contract Value，每张合约代表多少币）
3. **ctMult**：合约乘数（Contract Multiplier）

## 完整换算公式

```
币数量 = 张数 × ctVal × ctMult
```

### 示例：BTC-USDT-SWAP

```sql
SELECT instid, minsz, ctval, ctmult
FROM okx_perpetual
WHERE instid = 'BTC-USDT-SWAP';
```

结果：
- instId: `BTC-USDT-SWAP`
- minSz: `0.01` 张
- ctVal: `0.01` BTC/张
- ctMult: `1`

计算：
```
最小下单量 = 0.01 × 0.01 × 1 = 0.0001 BTC
```

## ctMult 的作用

`ctMult` 是合约乘数，用于调整合约面值：

```
实际面值 = ctVal × ctMult
```

### 当前状态

经过查询验证，**目前所有 OKX USDT 永续合约的 ctMult 都是 1**：

```sql
SELECT ctmult, COUNT(*) as count
FROM okx_perpetual
GROUP BY ctmult;
```

结果：
```
ctMult = 1: 253 个合约
```

### 为什么要包含 ctMult？

虽然当前所有合约的 `ctMult = 1`，但从代码完整性和未来兼容性考虑：

1. **OKX API 文档明确说明**需要使用 `ctVal × ctMult`
2. **未来可能会有** `ctMult ≠ 1` 的合约
3. **代码应该遵循 API 规范**，而不是依赖当前的巧合

## 修复内容

### 1. 更新 `v_trading_info` 视图

添加 `ctMult` 字段到 OKX 信息中：

```sql
jsonb_build_object(
    -- ... 其他字段 ...
    'contract_size', okx.ctval,
    'contract_multiplier', okx.ctmult,  -- ← 新增
    -- ... 其他字段 ...
)
```

### 2. 更新 `v_trading_info_flat_normalized` 视图

使用完整的换算公式：

```sql
-- 之前（不完整）
CASE
    WHEN okx_info->>'min_qty' IS NOT NULL
    THEN (okx_info->>'min_qty')::numeric
         * NULLIF((okx_info->>'contract_size')::numeric, 0)
END AS okx_min_qty

-- 之后（完整）
CASE
    WHEN okx_info->>'min_qty' IS NOT NULL
    THEN (okx_info->>'min_qty')::numeric
         * NULLIF((okx_info->>'contract_size')::numeric, 0)
         * NULLIF((okx_info->>'contract_multiplier')::numeric, 0)  -- ← 新增
END AS okx_min_qty
```

### 3. 更新文档

更新 `docs/exchange_quantity_units.md`，说明：
- OKX 的完整换算公式
- `ctVal` 和 `ctMult` 的作用
- 当前 `ctMult` 的实际值

## 验证结果

### BTC-USDT 各交易所对比

```sql
SELECT
    xt_symbol,
    xt_min_qty AS xt_min_btc,
    bn_min_qty AS bn_min_btc,
    okx_min_qty AS okx_min_btc,
    bb_min_qty AS bb_min_btc
FROM v_trading_info_flat_normalized
WHERE xt_symbol = 'btc_usdt';
```

结果：
```
XT:      0.0001 BTC
Binance: 0.001 BTC
OKX:     0.0001 BTC  ← 正确！(0.01 × 0.01 × 1)
Bybit:   0.001 BTC
```

### OKX 详细计算

```
张数:        0.01
ctVal:       0.01 BTC/张
ctMult:      1
───────────────────────────
币数量:      0.01 × 0.01 × 1 = 0.0001 BTC ✅
```

## OKX API 参考

根据 [OKX API 文档](https://www.okx.com/docs-v5/zh/#public-data-rest-api-get-instruments)：

- **ctVal**: Contract value
- **ctMult**: Contract multiplier
- **minSz**: Minimum order size

文档说明：实际合约面值 = ctVal × ctMult

## 总结

| 项目 | 说明 |
|------|------|
| **发现问题** | OKX 数量换算遗漏了 ctMult |
| **根本原因** | 当前所有合约 ctMult = 1，容易被忽略 |
| **正确公式** | 币数量 = 张数 × ctVal × ctMult |
| **当前影响** | 由于 ctMult = 1，结果碰巧正确 |
| **修复原因** | 代码完整性 + 未来兼容性 |
| **验证结果** | ✅ 修复后计算正确 |

## 其他交易所对比

| 交易所 | 数量单位 | 完整公式 |
|--------|---------|---------|
| XT | 张数 | `张数 × contract_size` |
| Binance | 币本位 | 直接使用 |
| **OKX** | **张数** | **`张数 × ctVal × ctMult`** |
| Bybit | 币本位 | 直接使用 |
| Gate | 张数 | `张数 × contract_size` |
| KuCoin | 币本位 | 直接使用 |
| MEXC | 张数 | `张数 × contract_size` |

## 感谢

感谢用户指出这个细节问题，确保了代码的严谨性和未来的兼容性！
