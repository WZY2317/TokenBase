#!/bin/bash
# ============================================================================
# 数据库结构导出脚本
# ============================================================================
#
# 用途: 导出当前数据库的表、视图、函数结构（不包含数据）
#       用于备份或版本控制
#
# 使用方法:
#   ./export_schema.sh
#
# ============================================================================

set -e  # 遇到错误立即退出

DB_NAME="perpetual_contracts_raw"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backup"

echo "=================================================="
echo "开始导出数据库结构: $DB_NAME"
echo "=================================================="

# 确保备份目录存在
mkdir -p "$BACKUP_DIR"

# 1. 导出表结构
echo ""
echo "步骤 1/3: 导出表结构..."
pg_dump -d $DB_NAME --schema-only --no-owner --no-privileges \
  -t binance_perpetual \
  -t bybit_perpetual \
  -t gate_perpetual \
  -t kucoin_perpetual \
  -t mexc_perpetual \
  -t okx_perpetual \
  -t xt_perpetual \
  -t pair_mappings \
  -t fuzzy_pair_mappings \
  -t unified_pair_mappings \
  > "$BACKUP_DIR/tables_schema_$(date +%Y%m%d).sql"
echo "✓ 表结构已导出到: $BACKUP_DIR/tables_schema_$(date +%Y%m%d).sql"

# 2. 导出视图结构
echo ""
echo "步骤 2/3: 导出视图结构..."
pg_dump -d $DB_NAME --schema-only --no-owner --no-privileges \
  -t v_raw_data \
  -t v_unified_trading_info \
  -t v_unified_trading_info_wide \
  > "$BACKUP_DIR/views_schema_$(date +%Y%m%d).sql"
echo "✓ 视图结构已导出到: $BACKUP_DIR/views_schema_$(date +%Y%m%d).sql"

# 3. 导出函数
echo ""
echo "步骤 3/3: 导出函数..."
psql -d $DB_NAME -c "\sf compare_exchange_params" \
  > "$BACKUP_DIR/functions_schema_$(date +%Y%m%d).sql"
echo "✓ 函数已导出到: $BACKUP_DIR/functions_schema_$(date +%Y%m%d).sql"

echo ""
echo "=================================================="
echo "✅ 数据库结构导出完成！"
echo "=================================================="
echo ""
echo "导出文件:"
ls -lh "$BACKUP_DIR"/*_$(date +%Y%m%d).sql
echo ""
