"""
价格获取模块
从各交易所API获取最新价格，用于验证交易对映射
"""
import aiohttp
import asyncio
from typing import Dict, Optional
import time


class PriceFetcher:
    """价格获取器"""

    def __init__(self, timeout: int = 10):
        self.timeout = timeout
        self.session = None

    async def __aenter__(self):
        self.session = aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=self.timeout))
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()

    async def _get(self, url: str) -> Optional[dict]:
        """GET请求"""
        try:
            async with self.session.get(url) as response:
                if response.status == 200:
                    return await response.json()
        except Exception as e:
            print(f"❌ 请求失败 {url}: {e}")
        return None

    async def get_xt_price(self, symbol: str) -> Optional[float]:
        """
        获取XT价格
        API: https://fapi.xt.com/future/market/v1/public/q/ticker
        """
        url = f"https://fapi.xt.com/future/market/v1/public/q/ticker?symbol={symbol}"
        data = await self._get(url)

        if data and data.get('returnCode') == 0:
            result = data.get('result')
            if result and isinstance(result, dict):
                price = result.get('c')  # c是收盘价（最新价）
                return float(price) if price else None

        return None

    async def get_binance_price(self, symbol: str) -> Optional[float]:
        """
        获取Binance价格
        API: https://fapi.binance.com/fapi/v1/ticker/price
        """
        url = f"https://fapi.binance.com/fapi/v1/ticker/price?symbol={symbol}"
        data = await self._get(url)

        if data and 'price' in data:
            return float(data['price'])

        return None

    async def get_okx_price(self, instid: str) -> Optional[float]:
        """
        获取OKX价格
        API: https://www.okx.com/api/v5/market/ticker
        """
        url = f"https://www.okx.com/api/v5/market/ticker?instId={instid}"
        data = await self._get(url)

        if data and data.get('code') == '0':
            tickers = data.get('data', [])
            if tickers and len(tickers) > 0:
                last = tickers[0].get('last')
                return float(last) if last else None

        return None

    async def get_bybit_price(self, symbol: str) -> Optional[float]:
        """
        获取Bybit价格
        API: https://api.bybit.com/v5/market/tickers
        """
        url = f"https://api.bybit.com/v5/market/tickers?category=linear&symbol={symbol}"
        data = await self._get(url)

        if data and data.get('retCode') == 0:
            tickers = data.get('result', {}).get('list', [])
            if tickers and len(tickers) > 0:
                last = tickers[0].get('lastPrice')
                return float(last) if last else None

        return None

    async def get_gate_price(self, contract: str) -> Optional[float]:
        """
        获取Gate价格
        API: https://api.gateio.ws/api/v4/futures/usdt/tickers
        """
        url = f"https://api.gateio.ws/api/v4/futures/usdt/tickers?contract={contract}"
        data = await self._get(url)

        if data and isinstance(data, list) and len(data) > 0:
            last = data[0].get('last')
            return float(last) if last else None

        return None

    async def get_kucoin_price(self, symbol: str) -> Optional[float]:
        """
        获取KuCoin价格
        API: https://api-futures.kucoin.com/api/v1/ticker
        """
        url = f"https://api-futures.kucoin.com/api/v1/ticker?symbol={symbol}"
        data = await self._get(url)

        if data and data.get('code') == '200000':
            ticker = data.get('data')
            if ticker:
                price = ticker.get('price')
                return float(price) if price else None

        return None

    async def get_mexc_price(self, symbol: str) -> Optional[float]:
        """
        获取MEXC价格
        API: https://contract.mexc.com/api/v1/contract/ticker
        """
        url = f"https://contract.mexc.com/api/v1/contract/ticker?symbol={symbol}"
        data = await self._get(url)

        if data and data.get('success'):
            ticker = data.get('data')
            if ticker:
                last = ticker.get('lastPrice')
                return float(last) if last else None

        return None

    async def get_price(self, exchange: str, symbol: str) -> Optional[float]:
        """
        根据交易所获取价格
        """
        if exchange == 'xt':
            return await self.get_xt_price(symbol)
        elif exchange == 'binance':
            return await self.get_binance_price(symbol)
        elif exchange == 'okx':
            return await self.get_okx_price(symbol)
        elif exchange == 'bybit':
            return await self.get_bybit_price(symbol)
        elif exchange == 'gate':
            return await self.get_gate_price(symbol)
        elif exchange == 'kucoin':
            return await self.get_kucoin_price(symbol)
        elif exchange == 'mexc':
            return await self.get_mexc_price(symbol)

        return None

    async def get_prices_batch(self, requests: list) -> Dict[str, Optional[float]]:
        """
        批量获取价格
        Args:
            requests: [{'exchange': 'xt', 'symbol': 'btc_usdt', 'key': 'xt_btc_usdt'}, ...]
        Returns:
            {'xt_btc_usdt': 50000.0, ...}
        """
        tasks = []
        keys = []

        for req in requests:
            exchange = req['exchange']
            symbol = req['symbol']
            key = req.get('key', f"{exchange}_{symbol}")

            tasks.append(self.get_price(exchange, symbol))
            keys.append(key)

        results = await asyncio.gather(*tasks, return_exceptions=True)

        prices = {}
        for key, result in zip(keys, results):
            if isinstance(result, Exception):
                prices[key] = None
            else:
                prices[key] = result

        return prices
