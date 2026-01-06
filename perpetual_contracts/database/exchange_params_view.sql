-- ============================================================================
-- 交易所参数视图 - 行式存储（每个交易所一行）
-- 便于灵活筛选和对比任意交易所
-- ============================================================================

DROP VIEW IF EXISTS v_exchange_params CASCADE;

CREATE VIEW v_exchange_params AS
WITH base_data AS (
    SELECT
        xt_symbol,
        normalized_pair,
        normalized_base,
        normalized_quote,
        xt_info,
        binance_info,
        okx_info,
        bybit_info,
        gate_info,
        kucoin_info,
        mexc_info
    FROM v_trading_info
)
-- XT
SELECT
    xt_symbol,
    normalized_pair,
    normalized_base,
    normalized_quote,
    'xt' as exchange,
    xt_info->>'symbol' as symbol,
    xt_info->>'base_asset' as base_asset,
    xt_info->>'quote_asset' as quote_asset,
    (xt_info->>'multiplier')::int as multiplier,
    (xt_info->>'price_precision')::int as price_precision,
    (xt_info->>'quantity_precision')::int as quantity_precision,
    xt_info->>'tick_size' as tick_size,
    xt_info->>'min_price' as min_price,
    xt_info->>'max_price' as max_price,
    xt_info->>'step_size' as step_size,
    xt_info->>'min_qty' as min_qty,
    xt_info->>'max_qty' as max_qty,
    xt_info->>'max_market_qty' as max_market_qty,
    xt_info->>'min_notional' as min_notional,
    xt_info->>'max_notional' as max_notional,
    xt_info->>'contract_size' as contract_size,
    xt_info->>'min_leverage' as min_leverage,
    xt_info->>'max_leverage' as max_leverage
FROM base_data

UNION ALL

-- Binance
SELECT
    xt_symbol,
    normalized_pair,
    normalized_base,
    normalized_quote,
    'binance' as exchange,
    binance_info->>'symbol',
    binance_info->>'base_asset',
    binance_info->>'quote_asset',
    (binance_info->>'multiplier')::int,
    (binance_info->>'price_precision')::int,
    (binance_info->>'quantity_precision')::int,
    binance_info->>'tick_size',
    binance_info->>'min_price',
    binance_info->>'max_price',
    binance_info->>'step_size',
    binance_info->>'min_qty',
    binance_info->>'max_qty',
    binance_info->>'max_market_qty',
    binance_info->>'min_notional',
    binance_info->>'max_notional',
    binance_info->>'contract_size',
    binance_info->>'min_leverage',
    binance_info->>'max_leverage'
FROM base_data
WHERE binance_info IS NOT NULL

UNION ALL

-- OKX
SELECT
    xt_symbol,
    normalized_pair,
    normalized_base,
    normalized_quote,
    'okx' as exchange,
    okx_info->>'symbol',
    okx_info->>'base_asset',
    okx_info->>'quote_asset',
    (okx_info->>'multiplier')::int,
    NULL::int,  -- OKX doesn't have price_precision
    NULL::int,  -- OKX doesn't have quantity_precision
    okx_info->>'tick_size',
    okx_info->>'min_price',
    okx_info->>'max_price',
    okx_info->>'step_size',
    okx_info->>'min_qty',
    okx_info->>'max_qty',
    okx_info->>'max_market_qty',
    okx_info->>'min_notional',
    okx_info->>'max_notional',
    okx_info->>'contract_size',
    okx_info->>'min_leverage',
    okx_info->>'max_leverage'
FROM base_data
WHERE okx_info IS NOT NULL

UNION ALL

-- Bybit
SELECT
    xt_symbol,
    normalized_pair,
    normalized_base,
    normalized_quote,
    'bybit' as exchange,
    bybit_info->>'symbol',
    bybit_info->>'base_asset',
    bybit_info->>'quote_asset',
    (bybit_info->>'multiplier')::int,
    (bybit_info->>'price_precision')::int,
    NULL::int,  -- Bybit doesn't have quantity_precision
    bybit_info->>'tick_size',
    bybit_info->>'min_price',
    bybit_info->>'max_price',
    bybit_info->>'step_size',
    bybit_info->>'min_qty',
    bybit_info->>'max_qty',
    bybit_info->>'max_market_qty',
    bybit_info->>'min_notional',
    bybit_info->>'max_notional',
    bybit_info->>'contract_size',
    bybit_info->>'min_leverage',
    bybit_info->>'max_leverage'
FROM base_data
WHERE bybit_info IS NOT NULL

UNION ALL

-- Gate
SELECT
    xt_symbol,
    normalized_pair,
    normalized_base,
    normalized_quote,
    'gate' as exchange,
    gate_info->>'symbol',
    gate_info->>'base_asset',
    gate_info->>'quote_asset',
    (gate_info->>'multiplier')::int,
    NULL::int,
    NULL::int,
    gate_info->>'tick_size',
    gate_info->>'min_price',
    gate_info->>'max_price',
    gate_info->>'step_size',
    gate_info->>'min_qty',
    gate_info->>'max_qty',
    gate_info->>'max_market_qty',
    gate_info->>'min_notional',
    gate_info->>'max_notional',
    gate_info->>'contract_size',
    gate_info->>'min_leverage',
    gate_info->>'max_leverage'
FROM base_data
WHERE gate_info IS NOT NULL

UNION ALL

-- KuCoin
SELECT
    xt_symbol,
    normalized_pair,
    normalized_base,
    normalized_quote,
    'kucoin' as exchange,
    kucoin_info->>'symbol',
    kucoin_info->>'base_asset',
    kucoin_info->>'quote_asset',
    (kucoin_info->>'multiplier')::int,
    NULL::int,
    NULL::int,
    kucoin_info->>'tick_size',
    kucoin_info->>'min_price',
    kucoin_info->>'max_price',
    kucoin_info->>'step_size',
    kucoin_info->>'min_qty',
    kucoin_info->>'max_qty',
    kucoin_info->>'max_market_qty',
    kucoin_info->>'min_notional',
    kucoin_info->>'max_notional',
    kucoin_info->>'contract_size',
    kucoin_info->>'min_leverage',
    kucoin_info->>'max_leverage'
FROM base_data
WHERE kucoin_info IS NOT NULL

UNION ALL

-- MEXC
SELECT
    xt_symbol,
    normalized_pair,
    normalized_base,
    normalized_quote,
    'mexc' as exchange,
    mexc_info->>'symbol',
    mexc_info->>'base_asset',
    mexc_info->>'quote_asset',
    (mexc_info->>'multiplier')::int,
    (mexc_info->>'price_precision')::int,
    (mexc_info->>'quantity_precision')::int,
    mexc_info->>'tick_size',
    mexc_info->>'min_price',
    mexc_info->>'max_price',
    mexc_info->>'step_size',
    mexc_info->>'min_qty',
    mexc_info->>'max_qty',
    mexc_info->>'max_market_qty',
    mexc_info->>'min_notional',
    mexc_info->>'max_notional',
    mexc_info->>'contract_size',
    mexc_info->>'min_leverage',
    mexc_info->>'max_leverage'
FROM base_data
WHERE mexc_info IS NOT NULL;

-- 添加注释
COMMENT ON VIEW v_exchange_params IS '交易所参数视图（行式存储） - 每个交易所一行，便于灵活筛选和对比';

-- ============================================================================
-- 使用示例
-- ============================================================================
--
-- 1. 对比 XT 和 Binance 的 BTC 配置:
-- SELECT * FROM v_exchange_params
-- WHERE xt_symbol = 'btc_usdt'
-- AND exchange IN ('xt', 'binance')
-- ORDER BY exchange;
--
-- 2. 查看某个交易对在所有交易所的 tick_size:
-- SELECT exchange, symbol, tick_size, min_qty, min_notional
-- FROM v_exchange_params
-- WHERE xt_symbol = '1000shib_usdt'
-- ORDER BY exchange;
--
-- 3. 查找 Binance 的所有交易对:
-- SELECT xt_symbol, symbol, tick_size, min_qty, min_notional
-- FROM v_exchange_params
-- WHERE exchange = 'binance'
-- ORDER BY xt_symbol;
--
-- 4. 对比特定参数:
-- SELECT
--     exchange,
--     symbol,
--     tick_size,
--     step_size,
--     min_qty,
--     min_notional
-- FROM v_exchange_params
-- WHERE xt_symbol = 'eth_usdt'
-- ORDER BY exchange;
--
-- ============================================================================
