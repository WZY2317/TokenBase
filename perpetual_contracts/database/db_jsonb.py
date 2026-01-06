"""
数据库操作模块 - JSONB存储版本
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

    async def create_tables(self, exchanges_config: dict):
        """创建简化的JSONB表"""
        async with self.pool.acquire() as conn:
            for exchange_name, config in exchanges_config.items():
                table_name = config['table_name']

                # 确定主键字段
                pk_field = 'symbol'
                if exchange_name == 'okx':
                    pk_field = 'instId'
                elif exchange_name == 'gate':
                    pk_field = 'name'

                await conn.execute(f"""
                    CREATE TABLE IF NOT EXISTS {table_name} (
                        id SERIAL PRIMARY KEY,
                        {pk_field} TEXT UNIQUE NOT NULL,
                        data JSONB NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );

                    CREATE INDEX IF NOT EXISTS idx_{table_name}_{pk_field} ON {table_name}({pk_field});
                    CREATE INDEX IF NOT EXISTS idx_{table_name}_data ON {table_name} USING GIN(data);
                """)

        print("✅ 数据库表结构创建成功（JSONB模式）")

    async def insert_contracts(self, table_name: str, contracts: List[Dict], primary_key: str = 'symbol'):
        """
        插入合约数据（JSONB模式）

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
                    pk_value = contract.get(primary_key)
                    if not pk_value:
                        continue

                    await conn.execute(f"""
                        INSERT INTO {table_name} ({primary_key}, data)
                        VALUES ($1, $2)
                        ON CONFLICT ({primary_key}) DO UPDATE SET
                            data = EXCLUDED.data,
                            updated_at = CURRENT_TIMESTAMP
                    """, pk_value, json.dumps(contract))

                    success_count += 1

                except Exception as e:
                    print(f"❌ 插入失败 {contract.get(primary_key)}: {e}")
                    continue

            print(f"✅ {table_name}: {success_count}/{len(contracts)} 条数据插入成功")
            return success_count
