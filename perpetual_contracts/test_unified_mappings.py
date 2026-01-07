"""
测试统一映射表的迁移和功能
执行迁移并验证数据完整性
"""
import asyncio
import asyncpg
from config import DB_CONFIG


async def execute_sql_file(conn, filename: str):
    """执行 SQL 文件"""
    print(f"📄 执行 SQL 文件: {filename}")
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            sql = f.read()
        await conn.execute(sql)
        print(f"   ✅ 成功")
    except Exception as e:
        print(f"   ❌ 失败: {e}")
        raise


async def print_statistics(conn):
    """打印统计信息"""
    print("\n" + "=" * 100)
    print("📊 数据统计")
    print("=" * 100)

    # 1. 总体统计
    print("\n1️⃣ 总体统计:")
    row = await conn.fetchrow("""
        SELECT
            (SELECT COUNT(*) FROM pair_mappings) as old_pair_mappings,
            (SELECT COUNT(*) FROM fuzzy_pair_mappings) as old_fuzzy_mappings,
            (SELECT COUNT(*) FROM unified_pair_mappings) as new_unified_total,
            (SELECT COUNT(*) FROM unified_pair_mappings WHERE match_type = 'exact') as new_exact,
            (SELECT COUNT(*) FROM unified_pair_mappings WHERE match_type = 'fuzzy') as new_fuzzy,
            (SELECT COUNT(DISTINCT xt_symbol) FROM unified_pair_mappings) as unique_xt_pairs
    """)

    print(f"   旧表 pair_mappings:        {row['old_pair_mappings']:>6} 行 (列式存储)")
    print(f"   旧表 fuzzy_pair_mappings:  {row['old_fuzzy_mappings']:>6} 行")
    print(f"   新表 unified_pair_mappings: {row['new_unified_total']:>6} 行 (精确: {row['new_exact']}, 模糊: {row['new_fuzzy']})")
    print(f"   唯一 XT 交易对数:          {row['unique_xt_pairs']:>6}")

    # 2. 各交易所分布
    print("\n2️⃣ 各交易所映射分布:")
    rows = await conn.fetch("""
        SELECT
            exchange,
            COUNT(*) as total,
            COUNT(*) FILTER (WHERE match_type = 'exact') as exact,
            COUNT(*) FILTER (WHERE match_type = 'fuzzy') as fuzzy,
            AVG(string_similarity) as avg_similarity
        FROM unified_pair_mappings
        GROUP BY exchange
        ORDER BY total DESC
    """)

    print(f"   {'交易所':<10} {'总数':>8} {'精确':>8} {'模糊':>8} {'平均相似度':>12}")
    print(f"   {'-' * 50}")
    for row in rows:
        print(f"   {row['exchange']:<10} {row['total']:>8} {row['exact']:>8} {row['fuzzy']:>8} {row['avg_similarity']:>12.4f}")

    # 3. 汇总视图测试
    print("\n3️⃣ 汇总视图 (v_unified_mappings_summary) 前 5 个:")
    rows = await conn.fetch("""
        SELECT
            xt_symbol,
            total_exchanges,
            exact_exchanges,
            fuzzy_exchanges,
            exchanges
        FROM v_unified_mappings_summary
        LIMIT 5
    """)

    print(f"   {'XT Symbol':<20} {'总交易所':>10} {'精确':>6} {'模糊':>6} {'交易所列表':<40}")
    print(f"   {'-' * 90}")
    for row in rows:
        exchanges = row['exchanges'][:40] if row['exchanges'] else ''
        print(f"   {row['xt_symbol']:<20} {row['total_exchanges']:>10} {row['exact_exchanges']:>6} {row['fuzzy_exchanges']:>6} {exchanges:<40}")


async def test_queries(conn):
    """测试常用查询"""
    print("\n" + "=" * 100)
    print("🔍 测试常用查询")
    print("=" * 100)

    # 1. 查询单个交易对的所有映射
    print("\n1️⃣ 查询 btc_usdt 的所有映射:")
    rows = await conn.fetch("""
        SELECT
            xt_symbol,
            exchange,
            exchange_symbol,
            match_type,
            string_similarity,
            price_diff
        FROM unified_pair_mappings
        WHERE xt_symbol = 'btc_usdt'
        ORDER BY match_type, exchange
    """)

    if rows:
        print(f"   找到 {len(rows)} 个映射:")
        for row in rows:
            match_type = row['match_type']
            similarity = f"{row['string_similarity']:.4f}" if row['string_similarity'] else 'N/A'
            price_diff = f"{row['price_diff']:.4f}" if row['price_diff'] else 'N/A'
            print(f"   - {row['exchange']:<10}: {row['exchange_symbol']:<20} ({match_type}, 相似度: {similarity}, 价差: {price_diff})")
    else:
        print("   未找到映射")

    # 2. 查询模糊匹配示例
    print("\n2️⃣ 查询前 5 个模糊匹配:")
    rows = await conn.fetch("""
        SELECT
            xt_symbol,
            exchange,
            exchange_symbol,
            string_similarity,
            price_diff
        FROM v_fuzzy_mappings
        ORDER BY string_similarity DESC
        LIMIT 5
    """)

    if rows:
        print(f"   {'XT Symbol':<20} {'交易所':<10} {'Exchange Symbol':<20} {'相似度':>10} {'价差':>10}")
        print(f"   {'-' * 80}")
        for row in rows:
            similarity = f"{row['string_similarity']:.4f}" if row['string_similarity'] else 'N/A'
            price_diff = f"{row['price_diff']:.4f}" if row['price_diff'] else 'N/A'
            print(f"   {row['xt_symbol']:<20} {row['exchange']:<10} {row['exchange_symbol']:<20} {similarity:>10} {price_diff:>10}")
    else:
        print("   未找到模糊匹配")

    # 3. 测试交易信息视图
    print("\n3️⃣ 测试交易信息视图 (v_unified_trading_info_wide):")
    row = await conn.fetchrow("""
        SELECT
            xt_symbol,
            xt_info->>'symbol' as xt_sym,
            binance_info->>'symbol' as bn_sym,
            binance_info->>'match_type' as bn_match,
            okx_info->>'symbol' as okx_sym,
            okx_info->>'match_type' as okx_match
        FROM v_unified_trading_info_wide
        WHERE xt_symbol = 'btc_usdt'
        LIMIT 1
    """)

    if row:
        print(f"   XT: {row['xt_sym']}")
        if row['bn_sym']:
            print(f"   Binance: {row['bn_sym']} ({row['bn_match']})")
        if row['okx_sym']:
            print(f"   OKX: {row['okx_sym']} ({row['okx_match']})")
    else:
        print("   未找到数据")


async def verify_data_integrity(conn):
    """验证数据完整性"""
    print("\n" + "=" * 100)
    print("✅ 数据完整性验证")
    print("=" * 100)

    # 1. 验证没有重复的 (xt_symbol, exchange)
    print("\n1️⃣ 检查重复的映射:")
    duplicates = await conn.fetchval("""
        SELECT COUNT(*)
        FROM (
            SELECT xt_symbol, exchange, COUNT(*) as cnt
            FROM unified_pair_mappings
            GROUP BY xt_symbol, exchange
            HAVING COUNT(*) > 1
        ) sub
    """)
    if duplicates == 0:
        print("   ✅ 没有重复映射")
    else:
        print(f"   ❌ 发现 {duplicates} 个重复映射!")

    # 2. 验证所有精确匹配的相似度都是 1.0
    print("\n2️⃣ 检查精确匹配的相似度:")
    invalid_exact = await conn.fetchval("""
        SELECT COUNT(*)
        FROM unified_pair_mappings
        WHERE match_type = 'exact' AND (string_similarity IS NULL OR string_similarity < 0.999)
    """)
    if invalid_exact == 0:
        print("   ✅ 所有精确匹配的相似度都正确")
    else:
        print(f"   ❌ 发现 {invalid_exact} 个精确匹配的相似度不正确!")

    # 3. 验证所有映射都有 xt_symbol
    print("\n3️⃣ 检查缺失的 xt_symbol:")
    missing_xt = await conn.fetchval("""
        SELECT COUNT(*)
        FROM unified_pair_mappings
        WHERE xt_symbol IS NULL OR xt_symbol = ''
    """)
    if missing_xt == 0:
        print("   ✅ 所有映射都有 xt_symbol")
    else:
        print(f"   ❌ 发现 {missing_xt} 个映射缺少 xt_symbol!")

    # 4. 验证所有映射都有 exchange_symbol
    print("\n4️⃣ 检查缺失的 exchange_symbol:")
    missing_exchange = await conn.fetchval("""
        SELECT COUNT(*)
        FROM unified_pair_mappings
        WHERE exchange_symbol IS NULL OR exchange_symbol = ''
    """)
    if missing_exchange == 0:
        print("   ✅ 所有映射都有 exchange_symbol")
    else:
        print(f"   ❌ 发现 {missing_exchange} 个映射缺少 exchange_symbol!")


async def main():
    """主函数"""
    print("=" * 100)
    print("统一映射表测试程序")
    print("=" * 100)
    print()

    # 连接数据库
    pool = await asyncpg.create_pool(**DB_CONFIG)
    print("✅ 数据库连接成功")
    print()

    try:
        async with pool.acquire() as conn:
            # 步骤 1: 创建统一映射表
            print("步骤 1: 创建统一映射表 schema...")
            await execute_sql_file(conn, 'database/unified_mapping_schema.sql')
            print()

            # 步骤 2: 迁移数据
            print("步骤 2: 迁移数据...")
            await execute_sql_file(conn, 'database/migrate_to_unified_mappings.sql')
            print()

            # 步骤 3: 创建交易信息视图
            print("步骤 3: 创建统一交易信息视图...")
            await execute_sql_file(conn, 'database/unified_trading_info_view.sql')
            print()

            # 步骤 4: 打印统计
            await print_statistics(conn)

            # 步骤 5: 测试查询
            await test_queries(conn)

            # 步骤 6: 验证数据完整性
            await verify_data_integrity(conn)

        print("\n" + "=" * 100)
        print("✅ 测试完成！")
        print("=" * 100)
        print()
        print("💡 后续步骤:")
        print("   1. 确认数据正确后，可以考虑删除旧表: pair_mappings 和 fuzzy_pair_mappings")
        print("   2. 更新应用代码，使用新的 unified_pair_mappings 表")
        print("   3. 更新文档，说明新的表结构和查询方式")
        print()

    finally:
        await pool.close()


if __name__ == "__main__":
    asyncio.run(main())
