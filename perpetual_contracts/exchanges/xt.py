"""
XT API 客户端
"""
from typing import List, Dict
from .base import BaseExchange


class XTAPI(BaseExchange):
    """XT 永续合约API"""

    def get_perpetuals(self) -> List[Dict]:
        """
        获取XT永续合约列表
        返回原始API数据
        """
        url = f"{self.api_base}/future/market/v1/public/symbol/list"
        data = self._get(url)

        if not data or data.get('returnCode') != 0:
            return []

        contracts = []
        for item in data.get('result', []):
            # 只获取永续合约且 API 可用的合约
            if item.get('contractType') == 'PERPETUAL' and item.get('isOpenApi') == True:
                contracts.append(item)

        print(f"✅ XT: {len(contracts)} 个合约 (已过滤禁用合约)")
        return contracts
