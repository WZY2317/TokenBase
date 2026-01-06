"""
KuCoin API 客户端
"""
from typing import List, Dict
from .base import BaseExchange


class KuCoinAPI(BaseExchange):
    """KuCoin 永续合约API"""

    def get_perpetuals(self) -> List[Dict]:
        """
        获取KuCoin永续合约列表
        返回原始API数据
        """
        url = f"{self.api_base}/api/v1/contracts/active"
        data = self._get(url)

        if not data or data.get('code') != '200000':
            return []

        contracts = []
        for item in data.get('data', []):
            # 只获取永续合约（symbol以M结尾）
            symbol = item.get('symbol', '')
            if symbol.endswith('M'):
                contracts.append(item)

        print(f"✅ KuCoin: {len(contracts)} 个合约")
        return contracts
