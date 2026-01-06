"""
交易对映射工具
基于 baseasset + quoteasset 建立XT与其他交易所的交易对映射
"""
import re
from typing import Dict, List, Tuple, Optional


def extract_multiplier_and_base(symbol: str) -> Tuple[int, str]:
    """
    提取交易对中的数字前缀/后缀倍数和真实base asset

    Examples:
        数字在前:
        '1000pepe' -> (1000, 'pepe')
        '1000000mog' -> (1000000, 'mog')
        '1mbabydoge' -> (1000000, 'babydoge')
        '1000shib' -> (1000, 'shib')

        数字在后:
        'shib1000' -> (1000, 'shib')
        'pepe1000' -> (1000, 'pepe')
        'mog1000000' -> (1000000, 'mog')

        无数字:
        'btc' -> (1, 'btc')

    Returns:
        (multiplier, base_asset)
    """
    symbol = symbol.lower().strip()

    # 匹配模式1：数字在前
    prefix_patterns = [
        (r'^1000000(\w+)$', 1000000),  # 1000000mog
        (r'^1m(\w+)$', 1000000),        # 1mbabydoge
        (r'^1000(\w+)$', 1000),         # 1000pepe, 1000shib
    ]

    for pattern, multiplier in prefix_patterns:
        match = re.match(pattern, symbol)
        if match:
            base = match.group(1)
            return (multiplier, base)

    # 匹配模式2：数字在后
    suffix_patterns = [
        (r'^(\w+)1000000$', 1000000),  # mog1000000
        (r'^(\w+)1000$', 1000),         # shib1000, pepe1000
    ]

    for pattern, multiplier in suffix_patterns:
        match = re.match(pattern, symbol)
        if match:
            base = match.group(1)
            return (multiplier, base)

    # 没有前缀/后缀，返回原值
    return (1, symbol)


def normalize_asset(asset: str) -> Tuple[int, str]:
    """
    标准化资产名称

    Returns:
        (multiplier, normalized_asset)
    """
    return extract_multiplier_and_base(asset)


def normalize_pair(base: str, quote: str) -> Tuple[int, str, str]:
    """
    标准化交易对

    Args:
        base: 基础资产
        quote: 报价资产

    Returns:
        (multiplier, normalized_base, normalized_quote)
    """
    multiplier, norm_base = normalize_asset(base)
    _, norm_quote = normalize_asset(quote)  # quote一般不会有前缀

    return (multiplier, norm_base.upper(), norm_quote.upper())


def create_mapping_key(base: str, quote: str) -> str:
    """
    创建映射key（标准化后的交易对）
    """
    _, norm_base, norm_quote = normalize_pair(base, quote)
    return f"{norm_base}_{norm_quote}"


def is_price_match(price1: float, price2: float, multiplier1: int, multiplier2: int,
                   threshold: float = 0.05) -> bool:
    """
    判断两个价格是否匹配（考虑倍数调整）

    Args:
        price1: 交易所1的价格
        price2: 交易所2的价格
        multiplier1: 交易所1的倍数（如1000pepe的1000）
        multiplier2: 交易所2的倍数
        threshold: 价格偏差阈值（默认5%）

    Returns:
        bool: 价格是否匹配
    """
    if price1 <= 0 or price2 <= 0:
        return False

    # 调整价格（考虑倍数）
    adjusted_price1 = price1 / multiplier1
    adjusted_price2 = price2 / multiplier2

    # 计算价格差异百分比
    diff = abs(adjusted_price1 - adjusted_price2) / adjusted_price2

    return diff <= threshold


def build_mapping_groups(contracts_by_exchange: Dict[str, List[Dict]]) -> Dict[str, List[Dict]]:
    """
    根据标准化的交易对建立映射组

    Args:
        contracts_by_exchange: {
            'xt': [{'symbol': 'btc_usdt', 'basecoin': 'btc', 'quotecoin': 'usdt'}, ...],
            'binance': [{'symbol': 'BTCUSDT', 'baseasset': 'BTC', 'quoteasset': 'USDT'}, ...],
            ...
        }

    Returns:
        {
            'BTC_USDT': [
                {'exchange': 'xt', 'symbol': 'btc_usdt', 'base': 'btc', 'quote': 'usdt', 'multiplier': 1},
                {'exchange': 'binance', 'symbol': 'BTCUSDT', 'base': 'BTC', 'quote': 'USDT', 'multiplier': 1},
                ...
            ],
            'PEPE_USDT': [
                {'exchange': 'xt', 'symbol': 'pepe_usdt', 'base': 'pepe', 'quote': 'usdt', 'multiplier': 1},
                {'exchange': 'binance', 'symbol': '1000PEPEUSDT', 'base': '1000PEPE', 'quote': 'USDT', 'multiplier': 1000},
                ...
            ]
        }
    """
    mapping_groups = {}

    # XT
    if 'xt' in contracts_by_exchange:
        for contract in contracts_by_exchange['xt']:
            base = contract.get('basecoin', '')
            quote = contract.get('quotecoin', '')
            if not base or not quote:
                continue

            multiplier, norm_base, norm_quote = normalize_pair(base, quote)
            key = f"{norm_base}_{norm_quote}"

            if key not in mapping_groups:
                mapping_groups[key] = []

            mapping_groups[key].append({
                'exchange': 'xt',
                'symbol': contract.get('symbol'),
                'base': base,
                'quote': quote,
                'multiplier': multiplier,
                'normalized_base': norm_base,
                'normalized_quote': norm_quote
            })

    # Binance
    if 'binance' in contracts_by_exchange:
        for contract in contracts_by_exchange['binance']:
            base = contract.get('baseasset', '')
            quote = contract.get('quoteasset', '')
            if not base or not quote:
                continue

            multiplier, norm_base, norm_quote = normalize_pair(base, quote)
            key = f"{norm_base}_{norm_quote}"

            if key not in mapping_groups:
                mapping_groups[key] = []

            mapping_groups[key].append({
                'exchange': 'binance',
                'symbol': contract.get('symbol'),
                'base': base,
                'quote': quote,
                'multiplier': multiplier,
                'normalized_base': norm_base,
                'normalized_quote': norm_quote
            })

    # OKX
    if 'okx' in contracts_by_exchange:
        for contract in contracts_by_exchange['okx']:
            instid = contract.get('instid', '')
            if not instid:
                continue

            # OKX格式: BTC-USDT-SWAP
            parts = instid.split('-')
            if len(parts) < 2:
                continue

            base = parts[0]
            quote = parts[1]

            multiplier, norm_base, norm_quote = normalize_pair(base, quote)
            key = f"{norm_base}_{norm_quote}"

            if key not in mapping_groups:
                mapping_groups[key] = []

            mapping_groups[key].append({
                'exchange': 'okx',
                'symbol': instid,
                'base': base,
                'quote': quote,
                'multiplier': multiplier,
                'normalized_base': norm_base,
                'normalized_quote': norm_quote
            })

    # Bybit
    if 'bybit' in contracts_by_exchange:
        for contract in contracts_by_exchange['bybit']:
            base = contract.get('basecoin', '')
            quote = contract.get('quotecoin', '')
            if not base or not quote:
                continue

            multiplier, norm_base, norm_quote = normalize_pair(base, quote)
            key = f"{norm_base}_{norm_quote}"

            if key not in mapping_groups:
                mapping_groups[key] = []

            mapping_groups[key].append({
                'exchange': 'bybit',
                'symbol': contract.get('symbol'),
                'base': base,
                'quote': quote,
                'multiplier': multiplier,
                'normalized_base': norm_base,
                'normalized_quote': norm_quote
            })

    # Gate
    if 'gate' in contracts_by_exchange:
        for contract in contracts_by_exchange['gate']:
            name = contract.get('name', '')
            if not name:
                continue

            # Gate格式: BTC_USDT
            parts = name.split('_')
            if len(parts) < 2:
                continue

            base = parts[0]
            quote = parts[1]

            multiplier, norm_base, norm_quote = normalize_pair(base, quote)
            key = f"{norm_base}_{norm_quote}"

            if key not in mapping_groups:
                mapping_groups[key] = []

            mapping_groups[key].append({
                'exchange': 'gate',
                'symbol': name,
                'base': base,
                'quote': quote,
                'multiplier': multiplier,
                'normalized_base': norm_base,
                'normalized_quote': norm_quote
            })

    # KuCoin
    if 'kucoin' in contracts_by_exchange:
        for contract in contracts_by_exchange['kucoin']:
            base = contract.get('basecurrency', '')
            quote = contract.get('quotecurrency', '')
            if not base or not quote:
                continue

            multiplier, norm_base, norm_quote = normalize_pair(base, quote)
            key = f"{norm_base}_{norm_quote}"

            if key not in mapping_groups:
                mapping_groups[key] = []

            mapping_groups[key].append({
                'exchange': 'kucoin',
                'symbol': contract.get('symbol'),
                'base': base,
                'quote': quote,
                'multiplier': multiplier,
                'normalized_base': norm_base,
                'normalized_quote': norm_quote
            })

    # MEXC
    if 'mexc' in contracts_by_exchange:
        for contract in contracts_by_exchange['mexc']:
            base = contract.get('basecoin', '')
            quote = contract.get('quotecoin', '')
            if not base or not quote:
                continue

            multiplier, norm_base, norm_quote = normalize_pair(base, quote)
            key = f"{norm_base}_{norm_quote}"

            if key not in mapping_groups:
                mapping_groups[key] = []

            mapping_groups[key].append({
                'exchange': 'mexc',
                'symbol': contract.get('symbol'),
                'base': base,
                'quote': quote,
                'multiplier': multiplier,
                'normalized_base': norm_base,
                'normalized_quote': norm_quote
            })

    return mapping_groups


def filter_xt_mappings(mapping_groups: Dict[str, List[Dict]]) -> Dict[str, Dict]:
    """
    过滤出包含XT的映射组

    当同一个标准化key有多个XT交易对时，优先选择multiplier大的
    （如1000shib_usdt优先于shib_usdt，因为其他交易所通常用1000SHIB）

    Returns:
        {
            'BTC_USDT': {
                'xt': {'symbol': 'btc_usdt', 'base': 'btc', 'quote': 'usdt', 'multiplier': 1},
                'binance': {'symbol': 'BTCUSDT', 'base': 'BTC', 'quote': 'USDT', 'multiplier': 1},
                'okx': {...},
                ...
            }
        }
    """
    xt_mappings = {}

    for key, contracts in mapping_groups.items():
        # 检查是否包含XT
        has_xt = any(c['exchange'] == 'xt' for c in contracts)
        if not has_xt:
            continue

        # 为每个交易所选择最合适的交易对
        mapping = {}
        for contract in contracts:
            exchange = contract['exchange']

            if exchange not in mapping:
                mapping[exchange] = contract
            elif exchange == 'xt':
                # 如果已经有XT交易对，选择multiplier更大的
                # （如1000shib_usdt优先于shib_usdt）
                if contract['multiplier'] > mapping[exchange]['multiplier']:
                    mapping[exchange] = contract

        xt_mappings[key] = mapping

    return xt_mappings


def format_mapping_summary(xt_mappings: Dict[str, Dict]) -> str:
    """
    格式化映射摘要
    """
    lines = []
    lines.append("=" * 100)
    lines.append("XT交易对映射汇总")
    lines.append("=" * 100)
    lines.append("")

    # 统计
    total_xt_pairs = len(xt_mappings)
    exchange_counts = {}

    for key, mapping in xt_mappings.items():
        for exchange in mapping.keys():
            if exchange != 'xt':
                exchange_counts[exchange] = exchange_counts.get(exchange, 0) + 1

    lines.append(f"XT总交易对数: {total_xt_pairs}")
    lines.append("")
    lines.append("各交易所匹配数量:")
    for exchange, count in sorted(exchange_counts.items()):
        lines.append(f"  - {exchange}: {count}")
    lines.append("")

    # 示例
    lines.append("映射示例 (前10个):")
    lines.append("-" * 100)

    count = 0
    for key, mapping in sorted(xt_mappings.items()):
        if count >= 10:
            break

        xt_info = mapping.get('xt', {})
        lines.append(f"\n标准化交易对: {key}")
        lines.append(f"  XT: {xt_info.get('symbol')} (倍数: {xt_info.get('multiplier')})")

        for exchange, info in sorted(mapping.items()):
            if exchange != 'xt':
                lines.append(f"  {exchange}: {info.get('symbol')} (倍数: {info.get('multiplier')})")

        count += 1

    lines.append("")
    lines.append("=" * 100)

    return "\n".join(lines)
