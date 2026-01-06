"""
数据库表结构生成工具 - TEXT类型版本
所有字段统一使用TEXT类型，避免类型转换问题
"""
from typing import List, Dict, Set


def collect_all_fields(data_samples: List[Dict]) -> Set[str]:
    """收集所有字段名"""
    fields = set()
    for sample in data_samples:
        for key in sample.keys():
            # API字段名为id时，重命名为api_id避免冲突
            if key == 'id':
                fields.add('api_id')
            else:
                fields.add(key)
    return fields


def generate_table_schema(table_name: str, data_samples: List[Dict], primary_key: str = 'symbol') -> str:
    """
    根据数据样本生成PostgreSQL表结构
    所有字段使用TEXT类型

    Args:
        table_name: 表名
        data_samples: 数据样本列表
        primary_key: 主键字段名

    Returns:
        SQL CREATE TABLE语句
    """
    if not data_samples:
        return ""

    # 收集所有字段
    all_fields = collect_all_fields(data_samples)

    # 生成CREATE TABLE语句
    sql_parts = [f"CREATE TABLE IF NOT EXISTS {table_name} ("]
    sql_parts.append("    id SERIAL PRIMARY KEY,")

    # 添加所有字段（都是TEXT类型）
    for field_name in sorted(all_fields):
        # 主键字段设置唯一约束
        if field_name == primary_key:
            sql_parts.append(f"    {field_name} TEXT UNIQUE NOT NULL,")
        else:
            sql_parts.append(f"    {field_name} TEXT,")

    # 添加时间戳
    sql_parts.append("    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,")
    sql_parts.append("    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
    sql_parts.append(");")

    # 添加索引
    indexes = [
        f"\nCREATE INDEX IF NOT EXISTS idx_{table_name}_{primary_key} ON {table_name}({primary_key});"
    ]

    return "\n".join(sql_parts) + "\n" + "\n".join(indexes)


def generate_all_schemas(exchanges_data: Dict[str, List[Dict]]) -> str:
    """
    为所有交易所生成表结构

    Args:
        exchanges_data: {exchange_name: [contracts]}

    Returns:
        完整的SQL schema
    """
    schemas = []
    schemas.append("-- 自动生成的数据库表结构")
    schemas.append("-- 所有字段使用TEXT类型，保留API原始字段名\n")

    for exchange_name, contracts in exchanges_data.items():
        if not contracts:
            continue

        table_name = f"{exchange_name}_perpetual"

        # 确定主键字段
        primary_key = 'symbol'
        if exchange_name == 'okx':
            primary_key = 'instId'
        elif exchange_name == 'gate':
            primary_key = 'name'

        schema = generate_table_schema(table_name, contracts, primary_key)

        schemas.append(f"\n-- {exchange_name.upper()} 永续合约表")
        schemas.append(schema)

    return "\n".join(schemas)
