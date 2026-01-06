"""
填充分表数据库 - 每个交易所独立表
跨交易所映射基于 base_asset + quote_asset
"""
import asyncpg
import requests
import asyncio
from typing import List, Dict
from decimal import Decimal

DB_CONFIG = {
    'user': 'oliver',
    'password': '',
    'host': '127.0.0.1',
    'port': 5432,
    'database': 'perpetual_trading'
}


# 交易所API类
class BinanceAPI:
    BASE_URL = "https://fapi.binance.com"

    @classmethod
    def get_all_perpetuals(cls) -> List[Dict]:
        try:
            url = f"{cls.BASE_URL}/fapi/v1/exchangeInfo"
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()

            contracts = []
            for symbol_info in data.get('symbols', []):
                if symbol_info.get('contractType') == 'PERPETUAL' and symbol_info.get('status') == 'TRADING':
                    filters = {f['filterType']: f for f in symbol_info.get('filters', [])}
                    price_filter = filters.get('PRICE_FILTER', {})
                    lot_size_filter = filters.get('LOT_SIZE', {})
                    min_notional_filter = filters.get('MIN_NOTIONAL', {})

                    contracts.append({
                        'symbol': symbol_info['symbol'],
                        'base_asset': symbol_info['baseAsset'],
                        'quote_asset': symbol_info['quoteAsset'],
                        'price_precision': symbol_info.get('pricePrecision'),
                        'quantity_precision': symbol_info.get('quantityPrecision'),
                        'tick_size': Decimal(price_filter.get('tickSize', 0)),
                        'step_size': Decimal(lot_size_filter.get('stepSize', 0)),
                        'min_qty': Decimal(lot_size_filter.get('minQty', 0)),
                        'max_qty': Decimal(lot_size_filter.get('maxQty', 0)),
                        'min_notional': Decimal(min_notional_filter.get('notional', 0)),
                        'contract_size': Decimal(1),
                        'status': symbol_info.get('status')
                    })

            print(f"✅ Binance: {len(contracts)}")
            return contracts
        except Exception as e:
            print(f"❌ Binance: {e}")
            return []


class XTAPI:
    BASE_URL = "https://fapi.xt.com"

    @classmethod
    def get_all_perpetuals(cls) -> List[Dict]:
        try:
            url = f"{cls.BASE_URL}/future/market/v1/public/symbol/list"
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()

            contracts = []
            if data.get('returnCode') == 0:
                for item in data.get('result', []):
                    if item.get('contractType') != 'PERPETUAL':
                        continue

                    contracts.append({
                        'symbol': item['symbol'],
                        'base_asset': item.get('baseCoin', '').upper(),
                        'quote_asset': item.get('quoteCoin', 'USDT').upper(),
                        'price_precision': item.get('pricePrecision'),
                        'quantity_precision': item.get('quantityPrecision'),
                        'tick_size': Decimal(str(item.get('minStepPrice', 0))),
                        'step_size': Decimal(1),  # XT 的 step_size 默认为1
                        'min_qty': Decimal(str(item.get('minQty', 0))),
                        'max_qty': Decimal(0),  # XT API 没有直接提供
                        'min_notional': Decimal(str(item.get('minNotional', 0))),
                        'contract_size': Decimal(str(item.get('contractSize', 1))),
                        'maker_fee': Decimal(str(item.get('makerFee', 0))),
                        'taker_fee': Decimal(str(item.get('takerFee', 0))),
                        'status': 'TRADING' if item.get('state') == 0 else 'HALT'
                    })

            print(f"✅ XT: {len(contracts)}")
            return contracts
        except Exception as e:
            print(f"❌ XT: {e}")
            return []


class OKXAPI:
    BASE_URL = "https://www.okx.com"

    @classmethod
    def get_all_perpetuals(cls) -> List[Dict]:
        try:
            url = f"{cls.BASE_URL}/api/v5/public/instruments"
            params = {'instType': 'SWAP'}
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()

            contracts = []
            if data.get('code') == '0':
                for item in data.get('data', []):
                    if item.get('settleCcy') not in ['USDT', 'USDC']:
                        continue

                    inst_id = item.get('instId', '')
                    parts = inst_id.split('-')
                    base_asset = parts[0] if len(parts) > 0 else ''
                    quote_asset = parts[1] if len(parts) > 1 else 'USDT'

                    contracts.append({
                        'symbol': inst_id,
                        'base_asset': base_asset,
                        'quote_asset': quote_asset,
                        'tick_size': Decimal(item.get('tickSz', 0)),
                        'step_size': Decimal(item.get('lotSz', 0)),
                        'min_qty': Decimal(item.get('minSz', 0)),
                        'max_qty': Decimal(item.get('maxLmtSz', 0)),
                        'contract_size': Decimal(item.get('ctVal', 1)),
                        'max_leverage': int(item.get('lever', 0)) if item.get('lever') else 0,
                        'status': item.get('state', 'live')
                    })

            print(f"✅ OKX: {len(contracts)}")
            return contracts
        except Exception as e:
            print(f"❌ OKX: {e}")
            return []


class BybitAPI:
    BASE_URL = "https://api.bybit.com"

    @classmethod
    def get_all_perpetuals(cls) -> List[Dict]:
        try:
            url = f"{cls.BASE_URL}/v5/market/instruments-info"
            params = {'category': 'linear'}
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()

            contracts = []
            if data.get('retCode') == 0:
                for item in data.get('result', {}).get('list', []):
                    if item.get('quoteCoin') not in ['USDT', 'USDC']:
                        continue

                    symbol = item['symbol']

                    # 过滤掉日期合约（只保留永续合约）
                    month_names = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                                   'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']
                    if any(month in symbol for month in month_names):
                        continue

                    lot_size_filter = item.get('lotSizeFilter', {})
                    price_filter = item.get('priceFilter', {})
                    leverage_filter = item.get('leverageFilter', {})

                    # 提取 priceScale (如 "2" 表示2位小数)
                    price_scale = item.get('priceScale')
                    price_precision = int(price_scale) if price_scale else None

                    contracts.append({
                        'symbol': symbol,
                        'base_asset': item.get('baseCoin', ''),
                        'quote_asset': item.get('quoteCoin', 'USDT'),
                        'price_precision': price_precision,
                        'tick_size': Decimal(price_filter.get('tickSize', 0)),
                        'step_size': Decimal(lot_size_filter.get('qtyStep', 0)),
                        'min_qty': Decimal(lot_size_filter.get('minOrderQty', 0)),
                        'max_qty': Decimal(lot_size_filter.get('maxOrderQty', 0)),
                        'min_notional': Decimal(lot_size_filter.get('minNotionalValue', 0)),
                        'contract_size': Decimal(1),
                        'max_leverage': int(float(leverage_filter.get('maxLeverage', 0))),
                        'status': item.get('status', 'Trading')
                    })

            print(f"✅ Bybit: {len(contracts)} (仅永续合约)")
            return contracts
        except Exception as e:
            print(f"❌ Bybit: {e}")
            return []


class GateAPI:
    BASE_URL = "https://api.gateio.ws"

    @classmethod
    def get_all_perpetuals(cls) -> List[Dict]:
        try:
            url = f"{cls.BASE_URL}/api/v4/futures/usdt/contracts"
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()

            contracts = []
            for item in data:
                name = item.get('name', '')
                parts = name.split('_')
                base_asset = parts[0] if len(parts) > 0 else ''
                quote_asset = parts[1] if len(parts) > 1 else 'USDT'

                # Gate 的 order_price_round 是字符串形式的 tick_size (如 "0.1")
                tick_size = Decimal(str(item.get('order_price_round', '0.01')))

                # quanto_multiplier 是合约乘数
                contract_size = Decimal(str(item.get('quanto_multiplier', '0.0001')))

                # Gate 没有 step_size，使用 1 作为默认值
                step_size = Decimal(1)

                contracts.append({
                    'symbol': name,
                    'base_asset': base_asset,
                    'quote_asset': quote_asset,
                    'tick_size': tick_size,
                    'step_size': step_size,
                    'min_qty': Decimal(str(item.get('order_size_min', 0))),
                    'max_qty': Decimal(str(item.get('order_size_max', 0))),
                    'contract_size': contract_size,
                    'max_leverage': int(float(item.get('leverage_max', 0))) if item.get('leverage_max') else 0,
                    'maker_fee': Decimal(str(item.get('maker_fee_rate', 0))),
                    'taker_fee': Decimal(str(item.get('taker_fee_rate', 0))),
                    'status': 'DELISTING' if item.get('in_delisting') else 'TRADING'
                })

            print(f"✅ Gate: {len(contracts)}")
            return contracts
        except Exception as e:
            print(f"❌ Gate: {e}")
            return []


class KuCoinAPI:
    BASE_URL = "https://api-futures.kucoin.com"

    @classmethod
    def get_all_perpetuals(cls) -> List[Dict]:
        try:
            url = f"{cls.BASE_URL}/api/v1/contracts/active"
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()

            contracts = []
            if data.get('code') == '200000':
                for item in data.get('data', []):
                    symbol = item.get('symbol', '')
                    if not symbol.endswith('M'):
                        continue

                    contracts.append({
                        'symbol': symbol,
                        'base_asset': item.get('baseCurrency', ''),
                        'quote_asset': 'USDT' if 'USDT' in symbol else 'USDC',
                        'tick_size': Decimal(str(item.get('tickSize', 0))),
                        'step_size': Decimal(str(item.get('lotSize', 0))),
                        'min_qty': Decimal(1),  # KuCoin 默认最小数量为1
                        'max_qty': Decimal(str(item.get('maxOrderQty', 0))),
                        'contract_size': Decimal(str(item.get('multiplier', 1))),
                        'max_leverage': int(item.get('maxLeverage', 0)) if item.get('maxLeverage') else 0,
                        'maker_fee': Decimal(str(item.get('makerFeeRate', 0))),
                        'taker_fee': Decimal(str(item.get('takerFeeRate', 0))),
                        'status': item.get('status', 'Open')
                    })

            print(f"✅ KuCoin: {len(contracts)}")
            return contracts
        except Exception as e:
            print(f"❌ KuCoin: {e}")
            return []


class MEXCAPI:
    BASE_URL = "https://contract.mexc.com"

    @classmethod
    def get_all_perpetuals(cls) -> List[Dict]:
        try:
            url = f"{cls.BASE_URL}/api/v1/contract/detail"
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()

            contracts = []
            if data.get('success'):
                for item in data.get('data', []):
                    symbol = item.get('symbol', '')
                    parts = symbol.split('_')
                    base_asset = parts[0] if len(parts) > 0 else ''
                    quote_asset = parts[1] if len(parts) > 1 else 'USDT'

                    price_scale = item.get('priceScale', 0)
                    vol_scale = item.get('volScale', 0)

                    contracts.append({
                        'symbol': symbol,
                        'base_asset': base_asset,
                        'quote_asset': quote_asset,
                        'price_precision': price_scale,
                        'quantity_precision': vol_scale,
                        'tick_size': Decimal(10) ** (-price_scale) if price_scale > 0 else Decimal(1),
                        'step_size': Decimal(10) ** (-vol_scale) if vol_scale > 0 else Decimal(1),
                        'min_qty': Decimal(str(item.get('minVol', 0))),
                        'max_qty': Decimal(str(item.get('maxVol', 0))),
                        'contract_size': Decimal(1),
                        'status': 'TRADING' if item.get('state') == 1 else 'HALT'
                    })

            print(f"✅ MEXC: {len(contracts)}")
            return contracts
        except Exception as e:
            print(f"❌ MEXC: {e}")
            return []


async def insert_to_table(pool, table_name: str, contracts: List[Dict]):
    """插入到指定交易所表"""
    async with pool.acquire() as conn:
        success = 0

        for contract in contracts:
            try:
                await conn.execute(f'''
                    INSERT INTO {table_name}
                    (symbol, base_asset, quote_asset, price_precision, quantity_precision,
                     tick_size, step_size, min_qty, max_qty, min_notional,
                     contract_size, max_leverage, maker_fee, taker_fee, status)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
                    ON CONFLICT (symbol) DO UPDATE SET
                        price_precision = EXCLUDED.price_precision,
                        quantity_precision = EXCLUDED.quantity_precision,
                        tick_size = EXCLUDED.tick_size,
                        step_size = EXCLUDED.step_size,
                        min_qty = EXCLUDED.min_qty,
                        max_qty = EXCLUDED.max_qty,
                        min_notional = EXCLUDED.min_notional,
                        contract_size = EXCLUDED.contract_size,
                        max_leverage = EXCLUDED.max_leverage,
                        maker_fee = EXCLUDED.maker_fee,
                        taker_fee = EXCLUDED.taker_fee,
                        status = EXCLUDED.status,
                        updated_at = CURRENT_TIMESTAMP
                ''',
                    contract['symbol'], contract['base_asset'], contract['quote_asset'],
                    contract.get('price_precision'), contract.get('quantity_precision'),
                    contract.get('tick_size'), contract.get('step_size'),
                    contract.get('min_qty'), contract.get('max_qty'), contract.get('min_notional'),
                    contract.get('contract_size'), contract.get('max_leverage'),
                    contract.get('maker_fee'), contract.get('taker_fee'),
                    contract.get('status')
                )
                success += 1
            except Exception as e:
                print(f"插入失败 {table_name}/{contract['symbol']}: {e}")

        print(f"✅ {table_name}: {success}/{len(contracts)}")
        return success


async def main():
    print("="*80)
    print("永续合约分表数据库 - 快速填充")
    print("映射方式: base_asset + quote_asset")
    print("="*80)
    print()

    print("📡 获取各交易所数据...")
    print()

    all_data = {
        'binance_perpetual': BinanceAPI.get_all_perpetuals(),
        'xt_perpetual': XTAPI.get_all_perpetuals(),
        'okx_perpetual': OKXAPI.get_all_perpetuals(),
        'bybit_perpetual': BybitAPI.get_all_perpetuals(),
        'gate_perpetual': GateAPI.get_all_perpetuals(),
        'kucoin_perpetual': KuCoinAPI.get_all_perpetuals(),
        'mexc_perpetual': MEXCAPI.get_all_perpetuals(),
    }

    print()
    print("💾 插入数据库...")
    print()

    pool = await asyncpg.create_pool(**DB_CONFIG)

    try:
        total_success = 0

        for table_name, contracts in all_data.items():
            if contracts:
                success = await insert_to_table(pool, table_name, contracts)
                total_success += success

        print()
        print("="*80)
        print("✅ 完成！")
        print("="*80)
        print(f"\n📊 总计: {total_success} 个合约")

    finally:
        await pool.close()


if __name__ == "__main__":
    asyncio.run(main())
