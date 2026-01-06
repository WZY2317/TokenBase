"""
Binance API 客户端
"""
from typing import List, Dict
from .base import BaseExchange


class BinanceAPI(BaseExchange):
    """Binance 永续合约API"""

    def get_perpetuals(self) -> List[Dict]:
        """
        获取Binance永续合约列表
        返回原始API数据
        """
        url = f"{self.api_base}/fapi/v1/exchangeInfo"
        data = self._get(url)

        if not data:
            return []

        contracts = []
        for symbol_info in data.get('symbols', []):
            # 只获取永续合约且状态为TRADING的
            if symbol_info.get('contractType') == 'PERPETUAL' and symbol_info.get('status') == 'TRADING':
                # 保存原始数据，只做最小处理：提取filters到顶层方便查询
                contract = symbol_info.copy()

                # 将filters数组转换为字典，方便存储
                filters = {f['filterType']: f for f in symbol_info.get('filters', [])}
                contract['filters_dict'] = filters

                contracts.append(contract)

        print(f"✅ Binance: {len(contracts)} 个合约")
        return contracts
