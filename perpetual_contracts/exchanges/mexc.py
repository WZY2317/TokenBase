"""
MEXC API 客户端
"""
from typing import List, Dict
from .base import BaseExchange


class MEXCAPI(BaseExchange):
    """MEXC 永续合约API"""

    def get_perpetuals(self) -> List[Dict]:
        """
        获取MEXC永续合约列表
        返回原始API数据
        """
        url = f"{self.api_base}/api/v1/contract/detail"
        data = self._get(url)

        if not data or not data.get('success'):
            return []

        # 过滤掉非交易状态的合约 (state=0表示交易中)
        contracts = [
            item for item in data.get('data', [])
            if item.get('state') == 0
        ]
        print(f"✅ MEXC: {len(contracts)} 个合约 (已过滤非活跃合约)")
        return contracts
