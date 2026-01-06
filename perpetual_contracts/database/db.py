"""
数据库操作模块 - TEXT类型版本
所有字段统一转换为TEXT存储
"""
import asyncpg
from typing import List, Dict
import json


class DatabaseManager:
    """数据库管理器"""

    def __init__(self, db_config: dict):
        self.db_config = db_config
        self.pool = None

    async def connect(self):
        """创建数据库连接池"""
        self.pool = await asyncpg.create_pool(**self.db_config)
        print("✅ 数据库连接成功")

    async def close(self):
        """关闭数据库连接池"""
        if self.pool:
            await self.pool.close()
            print("✅ 数据库连接已关闭")

    async def execute_schema(self, schema_sql: str):
        """执行schema SQL"""
        async with self.pool.acquire() as conn:
            await conn.execute(schema_sql)
        print("✅ 数据库表结构创建成功")

    async def truncate_table(self, table_name: str):
        """清空表数据"""
        async with self.pool.acquire() as conn:
            await conn.execute(f"TRUNCATE TABLE {table_name} CASCADE")
        print(f"✅ {table_name}: 表数据已清空")

    def _convert_to_text(self, value) -> str:
        """将任意类型的值转换为TEXT"""
        if value is None:
            return None
        elif isinstance(value, (dict, list)):
            return json.dumps(value)
        elif isinstance(value, bool):
            return str(value).lower()  # true/false
        else:
            return str(value)

    async def insert_contracts(self, table_name: str, contracts: List[Dict], primary_key: str = 'symbol'):
        """
        插入合约数据（TEXT模式）

        Args:
            table_name: 表名
            contracts: 合约数据列表
            primary_key: 主键字段名
        """
        if not contracts:
            return 0

        async with self.pool.acquire() as conn:
            success_count = 0

            for contract in contracts:
                try:
                    # 准备字段和值
                    fields = []
                    values = []
                    placeholders = []

                    for i, (key, value) in enumerate(contract.items(), 1):
                        # 如果字段名为id，重命名为api_id避免与自增id冲突
                        if key == 'id':
                            key = 'api_id'
                        fields.append(key)

                        # 所有值都转换为TEXT
                        values.append(self._convert_to_text(value))
                        placeholders.append(f"${i}")

                    # 构建INSERT语句
                    insert_sql = f"""
                        INSERT INTO {table_name} ({', '.join(fields)})
                        VALUES ({', '.join(placeholders)})
                        ON CONFLICT ({primary_key}) DO UPDATE SET
                    """

                    # 添加更新字段
                    update_parts = [f"{field} = EXCLUDED.{field}" for field in fields if field != primary_key]
                    update_parts.append("updated_at = CURRENT_TIMESTAMP")
                    insert_sql += ", ".join(update_parts)

                    await conn.execute(insert_sql, *values)
                    success_count += 1

                except Exception as e:
                    print(f"❌ 插入失败 {contract.get(primary_key)}: {e}")
                    continue

            print(f"✅ {table_name}: {success_count}/{len(contracts)} 条数据插入成功")
            return success_count
