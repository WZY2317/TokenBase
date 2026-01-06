"""
测试模糊匹配功能
"""
import asyncio
from database import DatabaseManager
from config import DB_CONFIG


async def main():
    db = DatabaseManager(DB_CONFIG)
    await db.connect()

    print('=' * 100)
    print('模糊匹配验证报告')
    print('=' * 100)
    print()

    # 1. 总体统计
    print('1. 总体统计')
    print('-' * 100)

    total = await db.pool.fetchval('SELECT COUNT(*) FROM fuzzy_pair_mappings')
    unique_xt = await db.pool.fetchval('SELECT COUNT(DISTINCT xt_symbol) FROM fuzzy_pair_mappings')

    print(f'总模糊匹配记录数: {total}')
    print(f'涉及 XT 交易对数: {unique_xt}')
    print()

    # 2. 各交易所统计
    print('2. 各交易所模糊匹配统计')
    print('-' * 100)

    result = await db.pool.fetch('''
        SELECT exchange, COUNT(*) as count
        FROM fuzzy_pair_mappings
        GROUP BY exchange
        ORDER BY count DESC
    ''')

    for row in result:
        print(f'  {row["exchange"]:10s}: {row["count"]:3d} 个模糊匹配')
    print()

    # 3. 相似度分布
    print('3. 相似度分布')
    print('-' * 100)

    result = await db.pool.fetch('''
        SELECT
            CASE
                WHEN string_similarity >= 0.95 THEN '95-99%'
                WHEN string_similarity >= 0.90 THEN '90-94%'
                WHEN string_similarity >= 0.80 THEN '80-89%'
                WHEN string_similarity >= 0.70 THEN '70-79%'
                ELSE '<70%'
            END as similarity_range,
            COUNT(*) as count
        FROM fuzzy_pair_mappings
        GROUP BY similarity_range
        ORDER BY similarity_range DESC
    ''')

    for row in result:
        print(f'  {row["similarity_range"]:10s}: {row["count"]:3d} 个')
    print()

    # 4. 所有模糊匹配详情
    print('4. 所有模糊匹配详情')
    print('-' * 100)

    result = await db.pool.fetch('''
        SELECT *
        FROM fuzzy_pair_mappings
        ORDER BY string_similarity DESC, xt_symbol, exchange
    ''')

    print(f'{"XT Symbol":<25} {"XT Base":<15} {"Exchange":<10} {"Exchange Symbol":<25} {"Exch Base":<15} {"Similarity":>10} {"Price Diff":>11}')
    print('-' * 120)

    for row in result:
        print(f'{row["xt_symbol"]:<25} {row["xt_base"]:<15} {row["exchange"]:<10} '
              f'{row["exchange_symbol"]:<25} {row["exchange_base"]:<15} '
              f'{row["string_similarity"]*100:>8.1f}%  {row["price_diff"]*100:>9.2f}%')

    print()

    # 5. 汇总视图
    print('5. 按 XT 交易对汇总')
    print('-' * 100)

    result = await db.pool.fetch('''
        SELECT *
        FROM v_fuzzy_mappings_summary
        ORDER BY exchange_count DESC, avg_similarity DESC
    ''')

    print(f'{"XT Symbol":<25} {"Exchanges":<30} {"Count":>5} {"Avg Sim":>9} {"Avg Diff":>10}')
    print('-' * 100)

    for row in result:
        print(f'{row["xt_symbol"]:<25} {row["exchanges"]:<30} {row["exchange_count"]:>5} '
              f'{row["avg_similarity"]*100:>7.1f}%  {row["avg_price_diff"]*100:>8.2f}%')

    print()
    print('=' * 100)
    print('说明:')
    print('  - 模糊匹配表只包含相似度 < 100% 的记录')
    print('  - 相似度 = 100% 的匹配应该在精确匹配表 (pair_mappings) 中')
    print('  - 这些模糊匹配需要人工确认是否应该使用')
    print('=' * 100)

    await db.close()


if __name__ == "__main__":
    asyncio.run(main())
