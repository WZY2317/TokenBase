"""
OKX API 客户端
"""
from typing import List, Dict
from .base import BaseExchange


class OKXAPI(BaseExchange):
    """OKX 永续合约API"""

    def get_perpetuals(self) -> List[Dict]:
        """
        获取OKX永续合约列表
        返回原始API数据
        """
        url = f"{self.api_base}/api/v5/public/instruments"
        params = {'instType': 'SWAP'}
        data = self._get(url, params)

        if not data or data.get('code') != '0':
            return []

        contracts = []
        for item in data.get('data', []):
            # 只获取USDT和USDC结算的合约，且状态为live
            if item.get('settleCcy') in ['USDT', 'USDC'] and item.get('state') == 'live':
                contracts.append(item)

        print(f"✅ OKX: {len(contracts)} 个合约 (已过滤非活跃合约)")
        return contracts
