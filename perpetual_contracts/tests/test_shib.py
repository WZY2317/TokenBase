"""
测试1000shib的价格获取和映射
"""
import asyncio
from utils.price_fetcher import PriceFetcher


async def test_shib_prices():
    """测试SHIB价格"""

    async with PriceFetcher() as fetcher:
        # XT的两个shib
        print("=== XT ===")
        price1 = await fetcher.get_xt_price('shib_usdt')
        print(f"shib_usdt: {price1}")

        price2 = await fetcher.get_xt_price('1000shib_usdt')
        print(f"1000shib_usdt: {price2}")

        # Binance
        print("\n=== Binance ===")
        price3 = await fetcher.get_binance_price('1000SHIBUSDT')
        print(f"1000SHIBUSDT: {price3}")

        # 对比价格
        if price2 and price3:
            print(f"\n=== 价格对比 ===")
            print(f"XT 1000shib_usdt: {price2}")
            print(f"Binance 1000SHIBUSDT: {price3}")
            diff = abs(price2 - price3) / price3 * 100
            print(f"价格差异: {diff:.2f}%")
            print(f"5%阈值内: {diff <= 5}")


if __name__ == "__main__":
    asyncio.run(test_shib_prices())
