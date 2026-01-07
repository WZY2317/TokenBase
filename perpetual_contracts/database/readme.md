# 数据库代码组织结构

## 核心文件（保留）

### 1. 表结构
- **tables_schema.sql** (31K) - 所有表的创建语句（自动导出）
  - xt_perpetual
  - binance_perpetual
  - okx_perpetual
  - bybit_perpetual
  - gate_perpetual
  - kucoin_perpetual
  - mexc_perpetual
  - pair_mappings
  - fuzzy_pair_mappings
  - unified_pair_mappings

### 2. 视图
- **unified_trading_info_view.sql** (19K) - 手动维护
  - v_unified_trading_info
  - v_unified_trading_info_wide
- **raw_data_view.sql** (7.6K) - 手动维护
  - v_raw_data
- **views_schema.sql** (17K) - 自动导出（备份用）

### 3. 函数
- **compare_params_function.sql** (5.1K) - 手动维护
  - compare_exchange_params()
- **functions_schema.sql** (3.6K) - 自动导出（备份用）

### 4. 文档
- **views_guide.md** (8.9K) - 视图使用指南

---

## 冗余文件（可删除）

- ❌ mapping_schema.sql (旧映射表，已被 unified_pair_mappings 替代)
- ❌ fuzzy_mapping_schema.sql (旧模糊匹配表，已被 unified_pair_mappings 替代)
- ❌ unified_mapping_schema.sql (已合并到 tables_schema.sql)
- ❌ schemas_raw.sql (旧的表结构，已被 tables_schema.sql 替代)
- ❌ migrate_to_unified_mappings.sql (迁移脚本，已完成，不再需要)
- ❌ init_db.sql (空数据库初始化，可以用 tables_schema.sql 替代)

---

## 推荐的文件结构

```
perpetual_contracts/database/
├── core/
│   ├── 01_tables_schema.sql           (31K) - 所有表结构（自动导出）
│   ├── 02_unified_trading_info_view.sql (19K) - 核心视图（手动维护）
│   ├── 03_raw_data_view.sql           (7.6K) - 原始数据视图（手动维护）
│   └── 04_compare_params_function.sql (5.1K) - 对比函数（手动维护）
├── backup/
│   ├── views_schema.sql               (17K) - 视图备份（自动导出）
│   └── functions_schema.sql           (3.6K) - 函数备份（自动导出）
└── docs/
    └── views_guide.md                 (8.9K) - 使用指南
```

---

## 初始化流程

### 全新数据库初始化：
```bash
# 1. 创建表
psql -d perpetual_contracts_raw < core/01_tables_schema.sql

# 2. 创建视图
psql -d perpetual_contracts_raw < core/02_unified_trading_info_view.sql
psql -d perpetual_contracts_raw < core/03_raw_data_view.sql

# 3. 创建函数
psql -d perpetual_contracts_raw < core/04_compare_params_function.sql
```

### 定时更新流程：
```bash
# 1. 更新表数据（Python脚本定时抓取）
# 2. 视图会自动更新（基于表数据）
# 3. 如果视图定义有变化，手动运行：
psql -d perpetual_contracts_raw < core/02_unified_trading_info_view.sql
psql -d perpetual_contracts_raw < core/03_raw_data_view.sql
```

---

## 快速开始脚本

### 1. 全新数据库初始化
```bash
./init_database.sh
```
自动创建所有表、视图和函数

### 2. 更新视图（当视图定义有变化时）
```bash
./update_views.sh
```
重新创建所有视图

### 3. 导出数据库结构备份
```bash
./export_schema.sh
```
导出当前数据库结构到 `backup/` 目录

---

## 手动操作（高级）

### 导出表结构
```bash
pg_dump -d perpetual_contracts_raw --schema-only --no-owner --no-privileges \
  -t binance_perpetual -t bybit_perpetual -t gate_perpetual \
  -t kucoin_perpetual -t mexc_perpetual -t okx_perpetual \
  -t xt_perpetual -t pair_mappings -t fuzzy_pair_mappings \
  -t unified_pair_mappings > backup/tables_schema.sql
```

### 导出视图结构
```bash
pg_dump -d perpetual_contracts_raw --schema-only --no-owner --no-privileges \
  -t v_raw_data -t v_unified_trading_info -t v_unified_trading_info_wide \
  > backup/views_schema.sql
```

### 导出函数
```bash
psql -d perpetual_contracts_raw -c "\sf compare_exchange_params" \
  > backup/functions_schema.sql
```
