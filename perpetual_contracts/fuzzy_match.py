"""
模糊匹配工具
用于匹配 base_asset 名称相似但不完全相同的交易对
"""
import asyncio
import asyncpg
from typing import Dict, List, Tuple, Optional
from config import DB_CONFIG
from utils.price_fetcher import PriceFetcher
from utils.pair_mapping import is_price_match


def string_similarity(s1: str, s2: str) -> float:
    """
    计算两个字符串的相似度（使用简单的包含关系）

    Returns:
        float: 相似度分数 (0.0 - 1.0)
    """
    s1_lower = s1.lower()
    s2_lower = s2.lower()

    # 完全相同
    if s1_lower == s2_lower:
        return 1.0

    # 其中一个包含另一个（去掉数字后缀）
    s1_clean = ''.join(c for c in s1_lower if not c.isdigit())
    s2_clean = ''.join(c for c in s2_lower if not c.isdigit())

    if s1_clean == s2_clean:
        return 0.95

    # 包含关系
    if s1_clean in s2_clean or s2_clean in s1_clean:
        shorter = min(len(s1_clean), len(s2_clean))
        longer = max(len(s1_clean), len(s2_clean))
        return shorter / longer * 0.9

    # 计算 Levenshtein distance
    # 使用动态规划计算编辑距离
    if len(s1_clean) == 0 or len(s2_clean) == 0:
        return 0.0

    m, n = len(s1_clean), len(s2_clean)
    dp = [[0] * (n + 1) for _ in range(m + 1)]

    for i in range(m + 1):
        dp[i][0] = i
    for j in range(n + 1):
        dp[0][j] = j

    for i in range(1, m + 1):
        for j in range(1, n + 1):
            cost = 0 if s1_clean[i-1] == s2_clean[j-1] else 1
            dp[i][j] = min(
                dp[i-1][j] + 1,      # deletion
                dp[i][j-1] + 1,      # insertion
                dp[i-1][j-1] + cost  # substitution
            )

    edit_distance = dp[m][n]
    max_len = max(m, n)
    similarity = 1 - (edit_distance / max_len)

    return max(0.0, similarity)


async def find_fuzzy_matches(pool, similarity_threshold: float = 0.7) -> List[Dict]:
    """
    查找所有需要模糊匹配的交易对

    Args:
        pool: 数据库连接池
        similarity_threshold: 字符串相似度阈值

    Returns:
        List of fuzzy match candidates
    """
    print("🔍 查找需要模糊匹配的交易对...")
    print(f"   相似度阈值: {similarity_threshold}")
    print()

    # 1. 获取所有未完全匹配的 XT 交易对
    async with pool.acquire() as conn:
        # 未映射的 XT 交易对
        unmapped_xt = await conn.fetch("""
            SELECT xt.symbol, xt.basecoin, xt.quotecoin
            FROM xt_perpetual xt
            LEFT JOIN pair_mappings pm ON xt.symbol = pm.xt_symbol
            WHERE pm.xt_symbol IS NULL
        """)

        # 部分映射的 XT 交易对（可能能找到更多匹配）
        partial_mapped = await conn.fetch("""
            SELECT xt.symbol, xt.basecoin, xt.quotecoin
            FROM xt_perpetual xt
            JOIN pair_mappings pm ON xt.symbol = pm.xt_symbol
            WHERE pm.exchange_count < 4  -- 映射到的交易所少于4个
        """)

    xt_pairs = list(unmapped_xt) + list(partial_mapped)
    print(f"   找到 {len(unmapped_xt)} 个未映射 + {len(partial_mapped)} 个部分映射的 XT 交易对")
    print()

    # 2. 获取各交易所的合约
    async with pool.acquire() as conn:
        binance_contracts = await conn.fetch("""
            SELECT symbol, baseasset, quoteasset
            FROM binance_perpetual
        """)

        okx_contracts = await conn.fetch("""
            SELECT instid as symbol
            FROM okx_perpetual
        """)

        bybit_contracts = await conn.fetch("""
            SELECT symbol, basecoin, quotecoin
            FROM bybit_perpetual
        """)

        gate_contracts = await conn.fetch("""
            SELECT name as symbol
            FROM gate_perpetual
        """)

        kucoin_contracts = await conn.fetch("""
            SELECT symbol, basecurrency, quotecurrency
            FROM kucoin_perpetual
        """)

        mexc_contracts = await conn.fetch("""
            SELECT symbol, basecoin, quotecoin
            FROM mexc_perpetual
        """)

    print(f"   加载了各交易所的合约数据")
    print()

    # 3. 对每个 XT 交易对，查找模糊匹配
    fuzzy_candidates = []

    for xt_pair in xt_pairs:
        xt_symbol = xt_pair['symbol']
        xt_base = xt_pair['basecoin']
        xt_quote = xt_pair['quotecoin']

        candidates = {
            'xt_symbol': xt_symbol,
            'xt_base': xt_base,
            'xt_quote': xt_quote,
            'matches': []
        }

        # 在 Binance 中查找
        for bn in binance_contracts:
            if bn['quoteasset'].upper() != xt_quote.upper():
                continue

            similarity = string_similarity(xt_base, bn['baseasset'])
            if similarity >= similarity_threshold:
                candidates['matches'].append({
                    'exchange': 'binance',
                    'symbol': bn['symbol'],
                    'base': bn['baseasset'],
                    'quote': bn['quoteasset'],
                    'similarity': similarity
                })

        # 在 Bybit 中查找
        for bb in bybit_contracts:
            if bb['quotecoin'].upper() != xt_quote.upper():
                continue

            similarity = string_similarity(xt_base, bb['basecoin'])
            if similarity >= similarity_threshold:
                candidates['matches'].append({
                    'exchange': 'bybit',
                    'symbol': bb['symbol'],
                    'base': bb['basecoin'],
                    'quote': bb['quotecoin'],
                    'similarity': similarity
                })

        # 在 MEXC 中查找
        for mx in mexc_contracts:
            if mx['quotecoin'].upper() != xt_quote.upper():
                continue

            similarity = string_similarity(xt_base, mx['basecoin'])
            if similarity >= similarity_threshold:
                candidates['matches'].append({
                    'exchange': 'mexc',
                    'symbol': mx['symbol'],
                    'base': mx['basecoin'],
                    'quote': mx['quotecoin'],
                    'similarity': similarity
                })

        # 只保留有匹配的候选
        if candidates['matches']:
            fuzzy_candidates.append(candidates)

    print(f"✅ 找到 {len(fuzzy_candidates)} 个有模糊匹配候选的 XT 交易对")
    print()

    return fuzzy_candidates


async def verify_fuzzy_matches(pool, fuzzy_candidates: List[Dict],
                               price_threshold: float = 0.05) -> List[Dict]:
    """
    通过价格验证模糊匹配

    Args:
        pool: 数据库连接池
        fuzzy_candidates: 模糊匹配候选列表
        price_threshold: 价格偏差阈值

    Returns:
        验证通过的模糊匹配列表
    """
    print("💰 验证模糊匹配（通过价格）...")
    print(f"   价格偏差阈值: {price_threshold * 100}%")
    print()

    verified_matches = []

    async with PriceFetcher() as fetcher:
        for idx, candidate in enumerate(fuzzy_candidates):
            if (idx + 1) % 10 == 0:
                print(f"   进度: {idx + 1}/{len(fuzzy_candidates)}")

            xt_symbol = candidate['xt_symbol']

            # 获取 XT 价格
            xt_price = await fetcher.get_price('xt', xt_symbol)
            if not xt_price or xt_price <= 0:
                continue

            verified_exchanges = []

            # 验证每个候选匹配
            for match in candidate['matches']:
                exchange = match['exchange']
                symbol = match['symbol']

                # 获取该交易所的价格
                price = await fetcher.get_price(exchange, symbol)
                if not price or price <= 0:
                    continue

                # 价格匹配验证（假设 multiplier 都是 1，因为这些是特殊情况）
                if is_price_match(xt_price, price, 1, 1, price_threshold):
                    verified_exchanges.append({
                        **match,
                        'xt_price': xt_price,
                        'exchange_price': price,
                        'price_diff': abs(xt_price - price) / price
                    })

            if verified_exchanges:
                verified_matches.append({
                    'xt_symbol': xt_symbol,
                    'xt_base': candidate['xt_base'],
                    'xt_quote': candidate['xt_quote'],
                    'xt_price': xt_price,
                    'matches': verified_exchanges
                })

    print(f"\n✅ 价格验证完成: {len(verified_matches)} 个模糊匹配通过验证")
    print()

    return verified_matches


async def print_fuzzy_match_report(verified_matches: List[Dict]):
    """
    打印模糊匹配报告
    """
    print("=" * 100)
    print("模糊匹配报告")
    print("=" * 100)
    print()

    if not verified_matches:
        print("未找到模糊匹配")
        return

    print(f"总计: {len(verified_matches)} 个 XT 交易对找到了模糊匹配")
    print()

    # 按匹配数量排序
    verified_matches.sort(key=lambda x: len(x['matches']), reverse=True)

    for match_info in verified_matches:
        xt_symbol = match_info['xt_symbol']
        xt_base = match_info['xt_base']
        xt_price = match_info['xt_price']
        matches = match_info['matches']

        print(f"\nXT: {xt_symbol} (base={xt_base}, price={xt_price})")
        print(f"   找到 {len(matches)} 个模糊匹配:")

        for m in matches:
            similarity_pct = m['similarity'] * 100
            price_diff_pct = m['price_diff'] * 100
            print(f"   - {m['exchange']:10s}: {m['symbol']:25s} "
                  f"(base={m['base']:15s}, similarity={similarity_pct:5.1f}%, "
                  f"price_diff={price_diff_pct:4.2f}%)")

    print()
    print("=" * 100)


async def save_fuzzy_matches_to_db(pool, verified_matches: List[Dict]):
    """
    保存模糊匹配结果到数据库
    只保存相似度 < 100% 的记录（100% 的应该在精确匹配中）
    """
    print("💾 保存模糊匹配到数据库...")

    # 先创建表（如果不存在）
    async with pool.acquire() as conn:
        with open('database/fuzzy_mapping_schema.sql', 'r', encoding='utf-8') as f:
            schema_sql = f.read()
        await conn.execute(schema_sql)

    print("   ✅ 表已创建/更新")

    # 清空旧数据
    async with pool.acquire() as conn:
        await conn.execute("TRUNCATE TABLE fuzzy_pair_mappings RESTART IDENTITY")

    print("   ✅ 旧数据已清空")

    # 保存新数据（只保存相似度 < 100% 的）
    success_count = 0
    skipped_count = 0
    async with pool.acquire() as conn:
        for match_info in verified_matches:
            xt_symbol = match_info['xt_symbol']
            xt_base = match_info['xt_base']
            xt_quote = match_info['xt_quote']
            xt_price = match_info['xt_price']

            for m in match_info['matches']:
                # 跳过相似度 >= 0.999 (100%) 的记录
                if m['similarity'] >= 0.999:
                    skipped_count += 1
                    continue

                try:
                    await conn.execute("""
                        INSERT INTO fuzzy_pair_mappings (
                            xt_symbol, xt_base, xt_quote, xt_price,
                            exchange, exchange_symbol, exchange_base, exchange_quote, exchange_price,
                            string_similarity, price_diff
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
                        ON CONFLICT (xt_symbol, exchange) DO UPDATE SET
                            exchange_symbol = EXCLUDED.exchange_symbol,
                            exchange_base = EXCLUDED.exchange_base,
                            exchange_quote = EXCLUDED.exchange_quote,
                            exchange_price = EXCLUDED.exchange_price,
                            string_similarity = EXCLUDED.string_similarity,
                            price_diff = EXCLUDED.price_diff,
                            created_at = CURRENT_TIMESTAMP
                    """,
                        xt_symbol, xt_base, xt_quote, float(xt_price),
                        m['exchange'], m['symbol'], m['base'], m['quote'], float(m['exchange_price']),
                        float(m['similarity']), float(m['price_diff'])
                    )
                    success_count += 1
                except Exception as e:
                    print(f"   ❌ 保存失败 {xt_symbol} - {m['exchange']}: {e}")

    print(f"✅ 成功保存 {success_count} 条模糊匹配记录到数据库")
    print(f"   (跳过了 {skipped_count} 条相似度=100%的记录，这些应该在精确匹配中)")
    print()


async def save_fuzzy_matches_to_file(verified_matches: List[Dict], filename: str = "fuzzy_matches.txt"):
    """
    保存模糊匹配结果到文件
    """
    with open(filename, 'w', encoding='utf-8') as f:
        f.write("=" * 100 + "\n")
        f.write("模糊匹配结果\n")
        f.write("=" * 100 + "\n\n")

        for match_info in verified_matches:
            xt_symbol = match_info['xt_symbol']
            xt_base = match_info['xt_base']
            xt_price = match_info['xt_price']
            matches = match_info['matches']

            f.write(f"\nXT: {xt_symbol} (base={xt_base}, price={xt_price})\n")
            f.write(f"   找到 {len(matches)} 个模糊匹配:\n")

            for m in matches:
                similarity_pct = m['similarity'] * 100
                price_diff_pct = m['price_diff'] * 100
                f.write(f"   - {m['exchange']:10s}: {m['symbol']:25s} "
                       f"(base={m['base']:15s}, similarity={similarity_pct:5.1f}%, "
                       f"price_diff={price_diff_pct:4.2f}%)\n")

    print(f"✅ 模糊匹配结果已保存到: {filename}")


async def main():
    """主函数"""
    print("=" * 100)
    print("模糊匹配工具")
    print("用于查找 base_asset 名称相似但不完全相同的交易对")
    print("=" * 100)
    print()

    # 连接数据库
    pool = await asyncpg.create_pool(**DB_CONFIG)
    print("✅ 数据库连接成功")
    print()

    try:
        # 步骤1: 查找模糊匹配候选
        fuzzy_candidates = await find_fuzzy_matches(pool, similarity_threshold=0.7)

        # 步骤2: 价格验证
        verified_matches = await verify_fuzzy_matches(pool, fuzzy_candidates, price_threshold=0.05)

        # 步骤3: 打印报告
        await print_fuzzy_match_report(verified_matches)

        # 步骤4: 保存到数据库
        if verified_matches:
            await save_fuzzy_matches_to_db(pool, verified_matches)

        # 步骤5: 保存到文件
        if verified_matches:
            await save_fuzzy_matches_to_file(verified_matches)

        print("✅ 完成！")

    finally:
        await pool.close()


if __name__ == "__main__":
    asyncio.run(main())
