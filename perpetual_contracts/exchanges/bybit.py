"""
Bybit API 客户端
"""
from typing import List, Dict
from .base import BaseExchange


class BybitAPI(BaseExchange):
    """Bybit 永续合约API"""

    def get_perpetuals(self) -> List[Dict]:
        """
        获取Bybit永续合约列表
        返回原始API数据
        """
        url = f"{self.api_base}/v5/market/instruments-info"
        params = {'category': 'linear'}
        data = self._get(url, params)

        if not data or data.get('retCode') != 0:
            return []

        contracts = []
        month_names = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                       'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']

        for item in data.get('result', {}).get('list', []):
            # 只获取USDT和USDC的合约
            if item.get('quoteCoin') not in ['USDT', 'USDC']:
                continue

            # 过滤掉日期合约（只保留永续合约）
            symbol = item.get('symbol', '')
            if any(month in symbol for month in month_names):
                continue

            # 只保留状态为Trading的合约
            if item.get('status') != 'Trading':
                continue

            contracts.append(item)

        print(f"✅ Bybit: {len(contracts)} 个合约 (已过滤非活跃合约)")
        return contracts
