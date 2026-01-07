# 快速参考

## 数据库对象

### 表 (10)
- **交易所数据表** (7):
  - `xt_perpetual`, `binance_perpetual`, `okx_perpetual`
  - `bybit_perpetual`, `gate_perpetual`, `kucoin_perpetual`, `mexc_perpetual`
- **映射表** (3):
  - `pair_mappings` - 精确匹配（旧）
  - `fuzzy_pair_mappings` - 模糊匹配（旧）
  - `unified_pair_mappings` - 统一映射（新，推荐使用）✨

### 视图 (3)
- `v_unified_trading_info` - 统一交易信息（长格式）
- `v_unified_trading_info_wide` - 统一交易信息（宽格式）
- `v_raw_data` - 原始数据（所有 API 字段）

### 函数 (1)
- `compare_exchange_params()` - 对比两个交易所的参数

---

## 常用命令

### 查看数据库对象
```bash
psql -d perpetual_contracts_raw -c "\dt"  # 查看所有表
psql -d perpetual_contracts_raw -c "\dv"  # 查看所有视图
psql -d perpetual_contracts_raw -c "\df"  # 查看所有函数
```

### 查询示例
```sql
-- 查询 BTC_USDT 在所有交易所的最小下单量
SELECT
    xt_symbol,
    binance_info->>'min_qty' as bn,
    okx_info->>'min_qty' as okx,
    bybit_info->>'min_qty' as bb
FROM v_unified_trading_info_wide
WHERE xt_symbol = 'btc_usdt';
```

### 定时更新流程
1. **数据采集**: Python 脚本定时抓取各交易所数据，写入表
2. **视图自动更新**: 视图会自动基于表数据刷新
3. **视图定义变更**: 如果修改了视图 SQL 文件，运行 `./update_views.sh`

---

## 文件说明

| 文件 | 用途 | 是否需要手动修改 |
|------|------|------------------|
| `core/01_tables_schema.sql` | 表结构定义 | ❌ 自动导出 |
| `core/02_unified_trading_info_view.sql` | 统一交易信息视图 | ✅ 需要 |
| `core/03_raw_data_view.sql` | 原始数据视图 | ✅ 需要 |
| `core/04_compare_params_function.sql` | 对比函数 | ✅ 需要 |
| `init_database.sh` | 初始化脚本 | ❌ |
| `update_views.sh` | 更新视图脚本 | ❌ |
| `export_schema.sh` | 导出备份脚本 | ❌ |

---

## 注意事项

✅ **数量字段已标准化为币本位**
- OKX: `张数 × ctVal × ctMult = 币本位`
- Gate: `张数 × contract_size = 币本位`
- MEXC: `张数 × contract_size = 币本位`
- Binance/Bybit/KuCoin: 已是币本位，无需换算

✅ **所有视图返回的数量都可以直接比较**

⚠️ **定时更新时只需更新表数据，视图会自动刷新**
