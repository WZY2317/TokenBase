-- ============================================================================
-- 交易所交易信息扁平化视图
-- 将各交易所信息展开为独立列，方便直接查询和比较
-- ============================================================================

DROP VIEW IF EXISTS v_trading_info_flat CASCADE;

CREATE VIEW v_trading_info_flat AS
SELECT
    xt_symbol,
    normalized_pair,
    normalized_base,
    normalized_quote,

    -- ============================================================================
    -- XT 交易信息 (前缀: xt_)
    -- ============================================================================
    xt_info->>'symbol' AS xt_symbol_actual,
    xt_info->>'base_asset' AS xt_base_asset,
    xt_info->>'quote_asset' AS xt_quote_asset,
    (xt_info->>'multiplier')::int AS xt_multiplier,
    (xt_info->>'price_precision')::int AS xt_price_precision,
    (xt_info->>'quantity_precision')::int AS xt_quantity_precision,
    xt_info->>'tick_size' AS xt_tick_size,
    xt_info->>'min_price' AS xt_min_price,
    xt_info->>'max_price' AS xt_max_price,
    xt_info->>'step_size' AS xt_step_size,
    xt_info->>'min_qty' AS xt_min_qty,
    xt_info->>'max_qty' AS xt_max_qty,
    xt_info->>'max_market_qty' AS xt_max_market_qty,
    xt_info->>'min_notional' AS xt_min_notional,
    xt_info->>'max_notional' AS xt_max_notional,
    xt_info->>'contract_size' AS xt_contract_size,

    -- ============================================================================
    -- Binance 交易信息 (前缀: bn_)
    -- ============================================================================
    binance_info->>'symbol' AS bn_symbol,
    binance_info->>'base_asset' AS bn_base_asset,
    binance_info->>'quote_asset' AS bn_quote_asset,
    (binance_info->>'multiplier')::int AS bn_multiplier,
    (binance_info->>'price_precision')::int AS bn_price_precision,
    (binance_info->>'quantity_precision')::int AS bn_quantity_precision,
    binance_info->>'tick_size' AS bn_tick_size,
    binance_info->>'min_price' AS bn_min_price,
    binance_info->>'max_price' AS bn_max_price,
    binance_info->>'step_size' AS bn_step_size,
    binance_info->>'min_qty' AS bn_min_qty,
    binance_info->>'max_qty' AS bn_max_qty,
    binance_info->>'max_market_qty' AS bn_max_market_qty,
    binance_info->>'min_notional' AS bn_min_notional,

    -- ============================================================================
    -- OKX 交易信息 (前缀: okx_)
    -- ============================================================================
    okx_info->>'symbol' AS okx_symbol,
    okx_info->>'base_asset' AS okx_base_asset,
    okx_info->>'quote_asset' AS okx_quote_asset,
    (okx_info->>'multiplier')::int AS okx_multiplier,
    okx_info->>'tick_size' AS okx_tick_size,
    okx_info->>'step_size' AS okx_step_size,
    okx_info->>'min_qty' AS okx_min_qty,
    okx_info->>'max_qty' AS okx_max_qty,
    okx_info->>'max_market_qty' AS okx_max_market_qty,
    okx_info->>'max_notional' AS okx_max_notional,
    okx_info->>'contract_size' AS okx_contract_size,

    -- ============================================================================
    -- Bybit 交易信息 (前缀: bb_)
    -- ============================================================================
    bybit_info->>'symbol' AS bb_symbol,
    bybit_info->>'base_asset' AS bb_base_asset,
    bybit_info->>'quote_asset' AS bb_quote_asset,
    (bybit_info->>'multiplier')::int AS bb_multiplier,
    (bybit_info->>'price_precision')::int AS bb_price_precision,
    bybit_info->>'tick_size' AS bb_tick_size,
    bybit_info->>'min_price' AS bb_min_price,
    bybit_info->>'max_price' AS bb_max_price,
    bybit_info->>'step_size' AS bb_step_size,
    bybit_info->>'min_qty' AS bb_min_qty,
    bybit_info->>'max_qty' AS bb_max_qty,
    bybit_info->>'max_market_qty' AS bb_max_market_qty,
    bybit_info->>'min_notional' AS bb_min_notional,

    -- ============================================================================
    -- Gate 交易信息 (前缀: gt_)
    -- ============================================================================
    gate_info->>'symbol' AS gt_symbol,
    gate_info->>'base_asset' AS gt_base_asset,
    gate_info->>'quote_asset' AS gt_quote_asset,
    (gate_info->>'multiplier')::int AS gt_multiplier,
    gate_info->>'tick_size' AS gt_tick_size,
    gate_info->>'min_qty' AS gt_min_qty,
    gate_info->>'max_qty' AS gt_max_qty,
    gate_info->>'max_market_qty' AS gt_max_market_qty,
    gate_info->>'contract_size' AS gt_contract_size,

    -- ============================================================================
    -- KuCoin 交易信息 (前缀: kc_)
    -- ============================================================================
    kucoin_info->>'symbol' AS kc_symbol,
    kucoin_info->>'base_asset' AS kc_base_asset,
    kucoin_info->>'quote_asset' AS kc_quote_asset,
    (kucoin_info->>'multiplier')::int AS kc_multiplier,
    kucoin_info->>'tick_size' AS kc_tick_size,
    kucoin_info->>'max_price' AS kc_max_price,
    kucoin_info->>'step_size' AS kc_step_size,
    kucoin_info->>'max_qty' AS kc_max_qty,
    kucoin_info->>'max_market_qty' AS kc_max_market_qty,
    kucoin_info->>'contract_size' AS kc_contract_size,

    -- ============================================================================
    -- MEXC 交易信息 (前缀: mx_)
    -- ============================================================================
    mexc_info->>'symbol' AS mx_symbol,
    mexc_info->>'base_asset' AS mx_base_asset,
    mexc_info->>'quote_asset' AS mx_quote_asset,
    (mexc_info->>'multiplier')::int AS mx_multiplier,
    (mexc_info->>'price_precision')::int AS mx_price_precision,
    (mexc_info->>'quantity_precision')::int AS mx_quantity_precision,
    mexc_info->>'tick_size' AS mx_tick_size,
    mexc_info->>'step_size' AS mx_step_size,
    mexc_info->>'min_qty' AS mx_min_qty,
    mexc_info->>'max_qty' AS mx_max_qty,
    mexc_info->>'max_market_qty' AS mx_max_market_qty,
    mexc_info->>'contract_size' AS mx_contract_size

FROM v_trading_info;

-- 添加注释
COMMENT ON VIEW v_trading_info_flat IS '交易所交易信息扁平化视图 - 所有交易所信息展开为独立列';

-- ============================================================================
-- 使用示例
-- ============================================================================
--
-- 1. 查询单个交易对的所有信息:
-- SELECT * FROM v_trading_info_flat WHERE xt_symbol = '1000shib_usdt';
--
-- 2. 比较不同交易所的价格精度:
-- SELECT
--     xt_symbol,
--     xt_price_precision,
--     bn_price_precision,
--     bb_price_precision
-- FROM v_trading_info_flat
-- WHERE bn_symbol IS NOT NULL AND bb_symbol IS NOT NULL;
--
-- 3. 查询有 Binance 映射的交易对及其最小下单量:
-- SELECT
--     xt_symbol,
--     normalized_pair,
--     bn_symbol,
--     bn_min_qty,
--     bn_min_notional
-- FROM v_trading_info_flat
-- WHERE bn_symbol IS NOT NULL
-- ORDER BY xt_symbol;
--
-- 4. 查询特定交易对在各交易所的 tick_size:
-- SELECT
--     xt_symbol,
--     xt_tick_size,
--     bn_tick_size,
--     okx_tick_size,
--     bb_tick_size
-- FROM v_trading_info_flat
-- WHERE xt_symbol = 'btc_usdt';
--
-- ============================================================================
