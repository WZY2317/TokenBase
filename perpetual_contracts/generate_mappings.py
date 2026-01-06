"""
生成XT交易对映射
基于baseasset/quoteasset + 价格验证
"""
import asyncio
import asyncpg
from typing import Dict, List
from config import DB_CONFIG
from utils.pair_mapping import (
    build_mapping_groups,
    filter_xt_mappings,
    format_mapping_summary,
    is_price_match
)
from utils.price_fetcher import PriceFetcher


async def load_contracts_from_db(pool) -> Dict[str, List[Dict]]:
    """
    从数据库加载所有交易所的合约数据
    """
    print("📥 从数据库加载合约数据...")

    contracts = {}

    async with pool.acquire() as conn:
        # XT
        rows = await conn.fetch("SELECT symbol, basecoin, quotecoin FROM xt_perpetual")
        contracts['xt'] = [dict(row) for row in rows]
        print(f"  ✅ XT: {len(contracts['xt'])} 个合约")

        # Binance
        rows = await conn.fetch("SELECT symbol, baseasset, quoteasset FROM binance_perpetual")
        contracts['binance'] = [dict(row) for row in rows]
        print(f"  ✅ Binance: {len(contracts['binance'])} 个合约")

        # OKX
        rows = await conn.fetch("SELECT instid FROM okx_perpetual")
        contracts['okx'] = [dict(row) for row in rows]
        print(f"  ✅ OKX: {len(contracts['okx'])} 个合约")

        # Bybit
        rows = await conn.fetch("SELECT symbol, basecoin, quotecoin FROM bybit_perpetual")
        contracts['bybit'] = [dict(row) for row in rows]
        print(f"  ✅ Bybit: {len(contracts['bybit'])} 个合约")

        # Gate
        rows = await conn.fetch("SELECT name FROM gate_perpetual")
        contracts['gate'] = [dict(row) for row in rows]
        print(f"  ✅ Gate: {len(contracts['gate'])} 个合约")

        # KuCoin
        rows = await conn.fetch("SELECT symbol, basecurrency, quotecurrency FROM kucoin_perpetual")
        contracts['kucoin'] = [dict(row) for row in rows]
        print(f"  ✅ KuCoin: {len(contracts['kucoin'])} 个合约")

        # MEXC
        rows = await conn.fetch("SELECT symbol, basecoin, quotecoin FROM mexc_perpetual")
        contracts['mexc'] = [dict(row) for row in rows]
        print(f"  ✅ MEXC: {len(contracts['mexc'])} 个合约")

    print()
    return contracts


async def fetch_prices_for_mappings(xt_mappings: Dict[str, Dict],
                                   price_threshold: float = 0.05) -> Dict[str, Dict]:
    """
    批量并发获取价格并验证映射（高速版本）

    Args:
        xt_mappings: 初步映射结果
        price_threshold: 价格偏差阈值（默认5%）

    Returns:
        验证后的映射（只包含价格匹配的）
    """
    print("💰 批量获取价格并验证映射...")
    print(f"   价格偏差阈值: {price_threshold * 100}%")
    print(f"   并发模式: 高速批处理")
    print()

    verified_mappings = {}

    async with PriceFetcher() as fetcher:
        # 准备所有价格请求
        price_requests = []
        mapping_index = {}  # 记录每个请求对应的mapping信息

        idx = 0
        for normalized_pair, mapping in xt_mappings.items():
            xt_info = mapping.get('xt')
            if not xt_info:
                continue

            # XT价格请求
            price_requests.append({
                'exchange': 'xt',
                'symbol': xt_info['symbol'],
                'key': f"{idx}_xt"
            })

            # 其他交易所价格请求
            for exchange, info in mapping.items():
                if exchange == 'xt':
                    continue
                price_requests.append({
                    'exchange': exchange,
                    'symbol': info['symbol'],
                    'key': f"{idx}_{exchange}"
                })

            mapping_index[idx] = {
                'normalized_pair': normalized_pair,
                'mapping': mapping
            }
            idx += 1

        print(f"   准备获取 {len(price_requests)} 个价格...")

        # 批量并发获取所有价格
        batch_size = 100
        all_prices = {}

        for i in range(0, len(price_requests), batch_size):
            batch = price_requests[i:i+batch_size]
            print(f"   批处理进度: {i}/{len(price_requests)}")

            prices = await fetcher.get_prices_batch(batch)
            all_prices.update(prices)

        print(f"\n✅ 价格获取完成，开始验证...")

        # 验证映射
        for idx, info in mapping_index.items():
            normalized_pair = info['normalized_pair']
            mapping = info['mapping']

            xt_info = mapping.get('xt')
            xt_key = f"{idx}_xt"
            xt_price = all_prices.get(xt_key)

            if not xt_price or xt_price <= 0:
                continue

            xt_info['price'] = xt_price
            xt_multiplier = xt_info['multiplier']

            verified_exchanges = {'xt': xt_info}

            # 验证其他交易所
            for exchange, exchange_info in mapping.items():
                if exchange == 'xt':
                    continue

                price_key = f"{idx}_{exchange}"
                price = all_prices.get(price_key)

                if price and price > 0:
                    exchange_info['price'] = price
                    multiplier = exchange_info['multiplier']

                    # 验证价格
                    if is_price_match(xt_price, price, xt_multiplier, multiplier, price_threshold):
                        verified_exchanges[exchange] = exchange_info

            # 保存通过验证的映射
            if len(verified_exchanges) > 1:
                verified_mappings[normalized_pair] = verified_exchanges

    total_pairs = len(xt_mappings)
    print(f"✅ 价格验证完成: {len(verified_mappings)}/{total_pairs} 个交易对通过验证")
    print()

    return verified_mappings


async def save_mappings_to_db(pool, verified_mappings: Dict[str, Dict]):
    """
    保存映射到数据库（列式存储）
    """
    print("💾 保存映射到数据库...")

    async with pool.acquire() as conn:
        # 清空旧数据
        await conn.execute("TRUNCATE TABLE pair_mappings RESTART IDENTITY")

        success_count = 0

        for normalized_pair, exchanges in verified_mappings.items():
            xt_info = exchanges.get('xt')
            if not xt_info:
                continue

            # 提取标准化的base和quote
            normalized_base = xt_info['normalized_base']
            normalized_quote = xt_info['normalized_quote']

            # 准备插入数据
            data = {
                'normalized_pair': normalized_pair,
                'normalized_base': normalized_base,
                'normalized_quote': normalized_quote,
                'xt_symbol': xt_info['symbol'],
                'xt_base': xt_info['base'],
                'xt_quote': xt_info['quote'],
                'xt_multiplier': xt_info['multiplier'],
                'xt_price': float(xt_info.get('price', 0)),
                'exchange_count': len(exchanges),
            }

            # 添加各交易所的symbol、multiplier、price
            for exchange in ['binance', 'okx', 'bybit', 'gate', 'kucoin', 'mexc']:
                if exchange in exchanges:
                    info = exchanges[exchange]
                    data[f'{exchange}_symbol'] = info['symbol']
                    data[f'{exchange}_multiplier'] = info['multiplier']
                    data[f'{exchange}_price'] = float(info.get('price', 0))
                else:
                    data[f'{exchange}_symbol'] = None
                    data[f'{exchange}_multiplier'] = None
                    data[f'{exchange}_price'] = None

            # 插入数据
            try:
                await conn.execute("""
                    INSERT INTO pair_mappings (
                        normalized_pair, normalized_base, normalized_quote,
                        xt_symbol, xt_base, xt_quote, xt_multiplier, xt_price,
                        binance_symbol, binance_multiplier, binance_price,
                        okx_symbol, okx_multiplier, okx_price,
                        bybit_symbol, bybit_multiplier, bybit_price,
                        gate_symbol, gate_multiplier, gate_price,
                        kucoin_symbol, kucoin_multiplier, kucoin_price,
                        mexc_symbol, mexc_multiplier, mexc_price,
                        exchange_count
                    ) VALUES (
                        $1, $2, $3, $4, $5, $6, $7, $8,
                        $9, $10, $11, $12, $13, $14, $15, $16, $17,
                        $18, $19, $20, $21, $22, $23, $24, $25, $26, $27
                    )
                """,
                    data['normalized_pair'], data['normalized_base'], data['normalized_quote'],
                    data['xt_symbol'], data['xt_base'], data['xt_quote'],
                    data['xt_multiplier'], data['xt_price'],
                    data['binance_symbol'], data['binance_multiplier'], data['binance_price'],
                    data['okx_symbol'], data['okx_multiplier'], data['okx_price'],
                    data['bybit_symbol'], data['bybit_multiplier'], data['bybit_price'],
                    data['gate_symbol'], data['gate_multiplier'], data['gate_price'],
                    data['kucoin_symbol'], data['kucoin_multiplier'], data['kucoin_price'],
                    data['mexc_symbol'], data['mexc_multiplier'], data['mexc_price'],
                    data['exchange_count']
                )
                success_count += 1

            except Exception as e:
                print(f"❌ 保存失败 {normalized_pair}: {e}")

    print(f"✅ 成功保存 {success_count} 个映射")
    print()


async def print_mapping_statistics(pool):
    """
    打印映射统计信息
    """
    print("=" * 100)
    print("映射统计")
    print("=" * 100)
    print()

    async with pool.acquire() as conn:
        # 总数
        total = await conn.fetchval("SELECT COUNT(*) FROM pair_mappings")
        print(f"总映射数: {total}")
        print()

        # 各交易所覆盖率
        print("各交易所覆盖率:")

        exchanges = ['binance', 'okx', 'bybit', 'gate', 'kucoin', 'mexc']
        for exchange in exchanges:
            count = await conn.fetchval(f"""
                SELECT COUNT(*)
                FROM pair_mappings
                WHERE {exchange}_symbol IS NOT NULL
            """)
            percentage = (count / total * 100) if total > 0 else 0
            print(f"  {exchange}: {count} ({percentage:.1f}%)")

        print()

        # 交易所数量分布
        print("交易所数量分布:")
        rows = await conn.fetch("""
            SELECT exchange_count, COUNT(*) as pair_count
            FROM pair_mappings
            GROUP BY exchange_count
            ORDER BY exchange_count DESC
        """)

        for row in rows:
            print(f"  {row['exchange_count']} 个交易所: {row['pair_count']} 个交易对")

        print()

        # 示例数据
        print("映射示例（前10个）:")
        print("-" * 100)

        rows = await conn.fetch("""
            SELECT
                normalized_pair,
                xt_symbol,
                xt_multiplier,
                xt_price,
                binance_symbol,
                okx_symbol,
                bybit_symbol,
                gate_symbol,
                kucoin_symbol,
                mexc_symbol,
                exchange_count
            FROM pair_mappings
            ORDER BY exchange_count DESC, normalized_pair
            LIMIT 10
        """)

        for row in rows:
            print(f"\n{row['normalized_pair']} (支持 {row['exchange_count']} 个交易所)")
            print(f"  XT: {row['xt_symbol']} (倍数: {row['xt_multiplier']}, 价格: {row['xt_price']})")

            for exchange in exchanges:
                symbol = row[f'{exchange}_symbol']
                if symbol:
                    print(f"  {exchange}: {symbol}")

    print()
    print("=" * 100)


async def main():
    """主函数"""
    print("=" * 100)
    print("XT交易对映射生成器")
    print("基于 baseasset/quoteasset + 价格验证（5%阈值）")
    print("=" * 100)
    print()

    # 连接数据库
    pool = await asyncpg.create_pool(**DB_CONFIG)
    print("✅ 数据库连接成功")
    print()

    try:
        # 创建映射表
        async with pool.acquire() as conn:
            with open('database/mapping_schema.sql', 'r', encoding='utf-8') as f:
                schema_sql = f.read()
            await conn.execute(schema_sql)
        print("✅ 映射表已创建")
        print()

        # 步骤1: 加载合约数据
        contracts = await load_contracts_from_db(pool)

        # 步骤2: 建立初步映射
        print("🔗 建立初步映射（基于baseasset/quoteasset）...")
        mapping_groups = build_mapping_groups(contracts)
        xt_mappings = filter_xt_mappings(mapping_groups)
        print(f"✅ 找到 {len(xt_mappings)} 个XT交易对的初步映射")
        print()

        # 步骤3: 价格验证
        verified_mappings = await fetch_prices_for_mappings(xt_mappings, price_threshold=0.05)

        # 步骤4: 保存到数据库
        await save_mappings_to_db(pool, verified_mappings)

        # 步骤5: 打印统计
        await print_mapping_statistics(pool)

        print("✅ 完成！")

    finally:
        await pool.close()


if __name__ == "__main__":
    asyncio.run(main())
