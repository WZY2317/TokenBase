"""
交易所API基类
"""
import requests
from typing import List, Dict
from abc import ABC, abstractmethod


class BaseExchange(ABC):
    """交易所API基类"""

    def __init__(self, api_base: str, timeout: int = 10):
        self.api_base = api_base
        self.timeout = timeout

    @abstractmethod
    def get_perpetuals(self) -> List[Dict]:
        """获取永续合约列表 - 返回原始API数据"""
        pass

    def _get(self, url: str, params: dict = None) -> dict:
        """发送GET请求"""
        try:
            response = requests.get(url, params=params, timeout=self.timeout)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"❌ API请求失败 {url}: {e}")
            return {}
