"""
测试价格获取功能
"""
import asyncio
from utils.price_fetcher import PriceFetcher


async def test_prices():
    """测试各交易所的价格获取"""

    async with PriceFetcher() as fetcher:
        # XT
        print("测试 XT...")
        price = await fetcher.get_xt_price('btc_usdt')
        print(f"  btc_usdt: {price}")

        # Binance
        print("\n测试 Binance...")
        price = await fetcher.get_binance_price('BTCUSDT')
        print(f"  BTCUSDT: {price}")

        price = await fetcher.get_binance_price('1000PEPEUSDT')
        print(f"  1000PEPEUSDT: {price}")

        # OKX
        print("\n测试 OKX...")
        price = await fetcher.get_okx_price('BTC-USDT-SWAP')
        print(f"  BTC-USDT-SWAP: {price}")

        # Bybit
        print("\n测试 Bybit...")
        price = await fetcher.get_bybit_price('BTCUSDT')
        print(f"  BTCUSDT: {price}")

        # Gate
        print("\n测试 Gate...")
        price = await fetcher.get_gate_price('BTC_USDT')
        print(f"  BTC_USDT: {price}")

        # KuCoin
        print("\n测试 KuCoin...")
        price = await fetcher.get_kucoin_price('XBTUSDT')
        print(f"  XBTUSDT: {price}")

        # MEXC
        print("\n测试 MEXC...")
        price = await fetcher.get_mexc_price('BTC_USDT')
        print(f"  BTC_USDT: {price}")


if __name__ == "__main__":
    asyncio.run(test_prices())
