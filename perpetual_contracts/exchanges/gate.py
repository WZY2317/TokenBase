"""
Gate.io API 客户端
"""
from typing import List, Dict
from .base import BaseExchange


class GateAPI(BaseExchange):
    """Gate.io 永续合约API"""

    def get_perpetuals(self) -> List[Dict]:
        """
        获取Gate.io永续合约列表
        返回原始API数据
        """
        url = f"{self.api_base}/api/v4/futures/usdt/contracts"
        data = self._get(url)

        if not isinstance(data, list):
            return []

        # 过滤掉非交易状态或正在下架的合约
        contracts = [
            item for item in data
            if item.get('status') == 'trading' and not item.get('in_delisting', False)
        ]

        print(f"✅ Gate.io: {len(contracts)} 个合约 (已过滤非活跃合约)")
        return contracts
