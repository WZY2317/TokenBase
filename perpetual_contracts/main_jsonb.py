"""
主程序 - JSON存储版本
获取交易所永续合约数据并以JSONB格式存储到数据库
"""
import asyncio
from config import DB_CONFIG, EXCHANGES, API_TIMEOUT
from exchanges import BinanceAPI, XTAPI, OKXAPI, BybitAPI, GateAPI, KuCoinAPI, MEXCAPI
from database.db_jsonb import DatabaseManager


async def main():
    """主函数"""
    print("=" * 80)
    print("永续合约数据采集系统 - JSONB存储模式")
    print("=" * 80)
    print()

    # 步骤1: 获取所有交易所数据
    print("📡 步骤1: 获取各交易所数据...")
    print()

    exchanges_data = {}

    # Binance
    binance = BinanceAPI(EXCHANGES['binance']['api_base'], API_TIMEOUT)
    exchanges_data['binance'] = binance.get_perpetuals()

    # XT
    xt = XTAPI(EXCHANGES['xt']['api_base'], API_TIMEOUT)
    exchanges_data['xt'] = xt.get_perpetuals()

    # OKX
    okx = OKXAPI(EXCHANGES['okx']['api_base'], API_TIMEOUT)
    exchanges_data['okx'] = okx.get_perpetuals()

    # Bybit
    bybit = BybitAPI(EXCHANGES['bybit']['api_base'], API_TIMEOUT)
    exchanges_data['bybit'] = bybit.get_perpetuals()

    # Gate
    gate = GateAPI(EXCHANGES['gate']['api_base'], API_TIMEOUT)
    exchanges_data['gate'] = gate.get_perpetuals()

    # KuCoin
    kucoin = KuCoinAPI(EXCHANGES['kucoin']['api_base'], API_TIMEOUT)
    exchanges_data['kucoin'] = kucoin.get_perpetuals()

    # MEXC
    mexc = MEXCAPI(EXCHANGES['mexc']['api_base'], API_TIMEOUT)
    exchanges_data['mexc'] = mexc.get_perpetuals()

    total_contracts = sum(len(contracts) for contracts in exchanges_data.values())
    print()
    print(f"📊 共获取 {total_contracts} 个合约")
    print()

    # 步骤2: 创建数据库表
    print("💾 步骤2: 创建数据库表...")
    db = DatabaseManager(DB_CONFIG)

    try:
        await db.connect()
        await db.create_tables(EXCHANGES)
        print()

        # 步骤3: 插入数据
        print("📥 步骤3: 插入数据到数据库...")
        print()

        total_inserted = 0

        # Binance
        count = await db.insert_contracts(
            EXCHANGES['binance']['table_name'],
            exchanges_data['binance'],
            'symbol'
        )
        total_inserted += count

        # XT
        count = await db.insert_contracts(
            EXCHANGES['xt']['table_name'],
            exchanges_data['xt'],
            'symbol'
        )
        total_inserted += count

        # OKX
        count = await db.insert_contracts(
            EXCHANGES['okx']['table_name'],
            exchanges_data['okx'],
            'instId'
        )
        total_inserted += count

        # Bybit
        count = await db.insert_contracts(
            EXCHANGES['bybit']['table_name'],
            exchanges_data['bybit'],
            'symbol'
        )
        total_inserted += count

        # Gate
        count = await db.insert_contracts(
            EXCHANGES['gate']['table_name'],
            exchanges_data['gate'],
            'name'
        )
        total_inserted += count

        # KuCoin
        count = await db.insert_contracts(
            EXCHANGES['kucoin']['table_name'],
            exchanges_data['kucoin'],
            'symbol'
        )
        total_inserted += count

        # MEXC
        count = await db.insert_contracts(
            EXCHANGES['mexc']['table_name'],
            exchanges_data['mexc'],
            'symbol'
        )
        total_inserted += count

        print()
        print("=" * 80)
        print("✅ 完成！")
        print("=" * 80)
        print(f"\n📊 总计: {total_inserted}/{total_contracts} 条数据插入成功")
        print()
        print("💡 数据以JSONB格式存储，可使用PostgreSQL的JSON查询功能访问所有原始字段")
        print("   示例: SELECT data->>'symbol', data->>'pricePrecision' FROM xt_perpetual_raw LIMIT 10;")

    finally:
        await db.close()


if __name__ == "__main__":
    asyncio.run(main())
