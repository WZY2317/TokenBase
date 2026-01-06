"""
测试新的对比功能
"""
import asyncio
from database import DatabaseManager
from config import DB_CONFIG


async def main():
    db = DatabaseManager(DB_CONFIG)
    await db.connect()

    # ========================================================================
    # 演示 1: 使用 v_exchange_params 直接对比
    # ========================================================================
    print('=' * 80)
    print('演示 1: 对比 XT 和 Binance 的 BTC 配置')
    print('=' * 80)
    print()

    result = await db.pool.fetch('''
        SELECT
            exchange,
            symbol,
            tick_size,
            step_size,
            min_qty,
            max_qty,
            min_notional,
            min_leverage,
            max_leverage
        FROM v_exchange_params
        WHERE xt_symbol = 'btc_usdt'
        AND exchange IN ('xt', 'binance')
        ORDER BY exchange
    ''')

    for row in result:
        print(f'{row["exchange"].upper()}:')
        print(f'  Symbol:        {row["symbol"]}')
        print(f'  Tick Size:     {row["tick_size"] or "-"}')
        print(f'  Step Size:     {row["step_size"] or "-"}')
        print(f'  Min Qty:       {row["min_qty"] or "-"}')
        print(f'  Max Qty:       {row["max_qty"] or "-"}')
        print(f'  Min Notional:  {row["min_notional"] or "-"}')
        print(f'  Min Leverage:  {row["min_leverage"] or "-"}')
        print(f'  Max Leverage:  {row["max_leverage"] or "-"}')
        print()

    # ========================================================================
    # 演示 2: 使用对比函数
    # ========================================================================
    print('=' * 80)
    print('演示 2: 使用函数对比 BTC (只显示关键参数)')
    print('=' * 80)
    print()

    result2 = await db.pool.fetch('''
        SELECT * FROM compare_exchange_params('btc_usdt')
        WHERE parameter IN ('symbol', 'tick_size', 'step_size', 'min_qty',
                           'max_qty', 'min_notional', 'price_precision',
                           'quantity_precision', 'min_leverage', 'max_leverage')
        ORDER BY parameter
    ''')

    print(f'{"参数":<20} {"XT":<20} {"Binance":<20} {"差异?":<10}')
    print('-' * 80)
    for row in result2:
        diff = '⚠️  是' if row['is_different'] else '✓  否'
        print(f'{row["parameter"]:<20} {row["exchange1_value"]:<20} {row["exchange2_value"]:<20} {diff:<10}')

    # ========================================================================
    # 演示 3: 对比其他交易所
    # ========================================================================
    print('\n\n' + '=' * 80)
    print('演示 3: 对比 ETH - Binance vs Bybit')
    print('=' * 80)
    print()

    result3 = await db.pool.fetch('''
        SELECT * FROM compare_exchange_params('eth_usdt', 'binance', 'bybit')
        WHERE parameter IN ('symbol', 'tick_size', 'step_size', 'min_qty',
                           'min_notional', 'min_leverage', 'max_leverage')
        ORDER BY parameter
    ''')

    print(f'{"参数":<20} {"Binance":<20} {"Bybit":<20} {"差异?":<10}')
    print('-' * 80)
    for row in result3:
        diff = '⚠️  是' if row['is_different'] else '✓  否'
        print(f'{row["parameter"]:<20} {row["exchange1_value"]:<20} {row["exchange2_value"]:<20} {diff:<10}')

    # ========================================================================
    # 演示 4: 查看所有交易所
    # ========================================================================
    print('\n\n' + '=' * 80)
    print('演示 4: 查看 1000shib_usdt 在所有交易所的配置')
    print('=' * 80)
    print()

    result4 = await db.pool.fetch('''
        SELECT
            exchange,
            symbol,
            tick_size,
            min_qty,
            min_notional,
            contract_size,
            min_leverage,
            max_leverage
        FROM v_exchange_params
        WHERE xt_symbol = '1000shib_usdt'
        ORDER BY exchange
    ''')

    print(f'{"交易所":<10} {"Symbol":<20} {"Tick Size":<15} {"Min Qty":<10} {"Min Notional":<15} {"Contract Size":<15} {"Min Lev":<10} {"Max Lev":<10}')
    print('-' * 110)
    for row in result4:
        print(f'{row["exchange"]:<10} {row["symbol"]:<20} {row["tick_size"] or "-":<15} '
              f'{row["min_qty"] or "-":<10} {row["min_notional"] or "-":<15} {row["contract_size"] or "-":<15} '
              f'{row["min_leverage"] or "-":<10} {row["max_leverage"] or "-":<10}')

    await db.close()


if __name__ == "__main__":
    asyncio.run(main())
