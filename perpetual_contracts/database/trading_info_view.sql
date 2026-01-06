-- ============================================================================
-- 交易所交易信息视图
-- 从 XT symbol 出发，获取各交易所的完整交易信息
-- ============================================================================

DROP VIEW IF EXISTS v_trading_info CASCADE;

CREATE VIEW v_trading_info AS
WITH base_mapping AS (
    SELECT
        normalized_pair,
        normalized_base,
        normalized_quote,
        xt_symbol,
        xt_multiplier,
        binance_symbol,
        binance_multiplier,
        okx_symbol,
        okx_multiplier,
        bybit_symbol,
        bybit_multiplier,
        gate_symbol,
        gate_multiplier,
        kucoin_symbol,
        kucoin_multiplier,
        mexc_symbol,
        mexc_multiplier
    FROM pair_mappings
)
SELECT
    bm.xt_symbol,
    bm.normalized_pair,
    bm.normalized_base,
    bm.normalized_quote,

    -- ============================================================================
    -- XT 交易信息
    -- ============================================================================
    jsonb_build_object(
        'exchange', 'xt',
        'symbol', xt.symbol,
        'base_asset', xt.basecoin,
        'quote_asset', xt.quotecoin,
        'multiplier', bm.xt_multiplier,
        'price_precision', xt.priceprecision::int,
        'quantity_precision', xt.quantityprecision::int,
        'tick_size', xt.minstepprice,
        'min_price', xt.minprice,
        'max_price', xt.maxprice,
        'step_size', NULL,  -- XT doesn't have explicit stepSize
        'min_qty', xt.minqty,
        'max_qty', NULL,
        'max_market_qty', NULL,
        'min_notional', xt.minnotional,
        'max_notional', xt.maxnotional,
        'contract_size', xt.contractsize,
        'min_leverage', NULL,  -- XT initLeverage is initial leverage, not min
        'max_leverage', NULL   -- XT doesn't provide max leverage limit
    ) AS xt_info,

    -- ============================================================================
    -- Binance 交易信息
    -- ============================================================================
    CASE WHEN bm.binance_symbol IS NOT NULL THEN
        jsonb_build_object(
            'exchange', 'binance',
            'symbol', bn.symbol,
            'base_asset', bn.baseasset,
            'quote_asset', bn.quoteasset,
            'multiplier', bm.binance_multiplier,
            'price_precision', bn.priceprecision::int,
            'quantity_precision', bn.quantityprecision::int,
            'tick_size', (bn.filters_dict::jsonb -> 'PRICE_FILTER' ->> 'tickSize'),
            'min_price', (bn.filters_dict::jsonb -> 'PRICE_FILTER' ->> 'minPrice'),
            'max_price', (bn.filters_dict::jsonb -> 'PRICE_FILTER' ->> 'maxPrice'),
            'step_size', (bn.filters_dict::jsonb -> 'LOT_SIZE' ->> 'stepSize'),
            'min_qty', (bn.filters_dict::jsonb -> 'LOT_SIZE' ->> 'minQty'),
            'max_qty', (bn.filters_dict::jsonb -> 'LOT_SIZE' ->> 'maxQty'),
            'max_market_qty', (bn.filters_dict::jsonb -> 'MARKET_LOT_SIZE' ->> 'maxQty'),
            'min_notional', (bn.filters_dict::jsonb -> 'MIN_NOTIONAL' ->> 'notional'),
            'max_notional', NULL,
            'contract_size', NULL,
            'min_leverage', NULL,
            'max_leverage', NULL
        )
    ELSE NULL END AS binance_info,

    -- ============================================================================
    -- OKX 交易信息
    -- ============================================================================
    CASE WHEN bm.okx_symbol IS NOT NULL THEN
        jsonb_build_object(
            'exchange', 'okx',
            'symbol', okx.instid,
            'base_asset', okx.baseccy,
            'quote_asset', okx.quoteccy,
            'multiplier', bm.okx_multiplier,
            'price_precision', NULL,  -- OKX uses tickSz instead
            'quantity_precision', NULL,  -- OKX uses lotSz instead
            'tick_size', okx.ticksz,
            'min_price', NULL,
            'max_price', NULL,
            'step_size', okx.lotsz,
            'min_qty', okx.minsz,
            'max_qty', okx.maxlmtsz,
            'max_market_qty', okx.maxmktsz,
            'min_notional', NULL,
            'max_notional', okx.maxlmtamt,
            'contract_size', okx.ctval,
            'min_leverage', '1',
            'max_leverage', okx.lever
        )
    ELSE NULL END AS okx_info,

    -- ============================================================================
    -- Bybit 交易信息
    -- ============================================================================
    CASE WHEN bm.bybit_symbol IS NOT NULL THEN
        jsonb_build_object(
            'exchange', 'bybit',
            'symbol', bb.symbol,
            'base_asset', bb.basecoin,
            'quote_asset', bb.quotecoin,
            'multiplier', bm.bybit_multiplier,
            'price_precision', bb.pricescale::int,
            'quantity_precision', NULL,
            'tick_size', (bb.pricefilter::jsonb ->> 'tickSize'),
            'min_price', (bb.pricefilter::jsonb ->> 'minPrice'),
            'max_price', (bb.pricefilter::jsonb ->> 'maxPrice'),
            'step_size', (bb.lotsizefilter::jsonb ->> 'qtyStep'),
            'min_qty', (bb.lotsizefilter::jsonb ->> 'minOrderQty'),
            'max_qty', (bb.lotsizefilter::jsonb ->> 'maxOrderQty'),
            'max_market_qty', (bb.lotsizefilter::jsonb ->> 'maxMktOrderQty'),
            'min_notional', (bb.lotsizefilter::jsonb ->> 'minNotionalValue'),
            'max_notional', NULL,
            'contract_size', NULL,
            'min_leverage', (bb.leveragefilter::jsonb ->> 'minLeverage'),
            'max_leverage', (bb.leveragefilter::jsonb ->> 'maxLeverage')
        )
    ELSE NULL END AS bybit_info,

    -- ============================================================================
    -- Gate 交易信息
    -- ============================================================================
    CASE WHEN bm.gate_symbol IS NOT NULL THEN
        jsonb_build_object(
            'exchange', 'gate',
            'symbol', gt.name,
            'base_asset', split_part(gt.name, '_', 1),
            'quote_asset', split_part(gt.name, '_', 2),
            'multiplier', bm.gate_multiplier,
            'price_precision', NULL,
            'quantity_precision', NULL,
            'tick_size', gt.order_price_round,
            'min_price', NULL,
            'max_price', NULL,
            'step_size', NULL,
            'min_qty', gt.order_size_min,
            'max_qty', gt.order_size_max,
            'max_market_qty', gt.market_order_size_max,
            'min_notional', NULL,
            'max_notional', NULL,
            'contract_size', gt.quanto_multiplier,
            'min_leverage', gt.leverage_min,
            'max_leverage', gt.leverage_max
        )
    ELSE NULL END AS gate_info,

    -- ============================================================================
    -- KuCoin 交易信息
    -- ============================================================================
    CASE WHEN bm.kucoin_symbol IS NOT NULL THEN
        jsonb_build_object(
            'exchange', 'kucoin',
            'symbol', kc.symbol,
            'base_asset', kc.basecurrency,
            'quote_asset', kc.quotecurrency,
            'multiplier', bm.kucoin_multiplier,
            'price_precision', NULL,
            'quantity_precision', NULL,
            'tick_size', kc.ticksize,
            'min_price', NULL,
            'max_price', kc.maxprice,
            'step_size', kc.lotsize,
            'min_qty', NULL,
            'max_qty', kc.maxorderqty,
            'max_market_qty', kc.marketmaxorderqty,
            'min_notional', NULL,
            'max_notional', NULL,
            'contract_size', kc.multiplier,
            'min_leverage', '1',
            'max_leverage', kc.maxleverage
        )
    ELSE NULL END AS kucoin_info,

    -- ============================================================================
    -- MEXC 交易信息
    -- ============================================================================
    CASE WHEN bm.mexc_symbol IS NOT NULL THEN
        jsonb_build_object(
            'exchange', 'mexc',
            'symbol', mx.symbol,
            'base_asset', mx.basecoin,
            'quote_asset', mx.quotecoin,
            'multiplier', bm.mexc_multiplier,
            'price_precision', mx.pricescale::int,
            'quantity_precision', mx.volscale::int,
            'tick_size', mx.priceunit,
            'min_price', NULL,
            'max_price', NULL,
            'step_size', mx.volunit,
            'min_qty', mx.minvol,
            'max_qty', mx.maxvol,
            'max_market_qty', mx.limitmaxvol,
            'min_notional', NULL,
            'max_notional', NULL,
            'contract_size', mx.contractsize,
            'min_leverage', mx.minleverage,
            'max_leverage', mx.maxleverage
        )
    ELSE NULL END AS mexc_info

FROM base_mapping bm
LEFT JOIN xt_perpetual xt ON bm.xt_symbol = xt.symbol
LEFT JOIN binance_perpetual bn ON bm.binance_symbol = bn.symbol
LEFT JOIN okx_perpetual okx ON bm.okx_symbol = okx.instid
LEFT JOIN bybit_perpetual bb ON bm.bybit_symbol = bb.symbol
LEFT JOIN gate_perpetual gt ON bm.gate_symbol = gt.name
LEFT JOIN kucoin_perpetual kc ON bm.kucoin_symbol = kc.symbol
LEFT JOIN mexc_perpetual mx ON bm.mexc_symbol = mx.symbol;

-- 添加注释
COMMENT ON VIEW v_trading_info IS '交易所交易信息视图 - 从XT symbol映射到各交易所的完整交易参数';

-- ============================================================================
-- 使用示例
-- ============================================================================
--
-- 1. 查询单个交易对的所有交易所信息:
-- SELECT * FROM v_trading_info WHERE xt_symbol = '1000shib_usdt';
--
-- 2. 查询特定交易所的信息:
-- SELECT xt_symbol, normalized_pair, binance_info
-- FROM v_trading_info
-- WHERE binance_info IS NOT NULL;
--
-- 3. 提取 Binance 的具体字段:
-- SELECT
--     xt_symbol,
--     binance_info->>'symbol' as binance_symbol,
--     binance_info->>'tick_size' as tick_size,
--     binance_info->>'min_qty' as min_qty
-- FROM v_trading_info
-- WHERE binance_info IS NOT NULL;
--
-- ============================================================================
