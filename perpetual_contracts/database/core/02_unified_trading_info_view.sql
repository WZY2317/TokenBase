-- ============================================================================
-- 统一交易信息视图
-- 基于 unified_pair_mappings，展示所有映射（精确+模糊）的完整交易信息
-- 替代原来的 v_trading_info 和 v_fuzzy_match_trading_info
-- ============================================================================

DROP VIEW IF EXISTS v_unified_trading_info CASCADE;

CREATE VIEW v_unified_trading_info AS
WITH base_mapping AS (
    SELECT
        xt_symbol,
        normalized_pair,
        normalized_base,
        normalized_quote,
        xt_multiplier,
        exchange,
        exchange_symbol,
        exchange_multiplier,
        match_type,
        string_similarity,
        price_diff,
        verified
    FROM unified_pair_mappings
    WHERE verified = true
)
SELECT
    bm.xt_symbol,
    bm.normalized_pair,
    bm.normalized_base,
    bm.normalized_quote,
    bm.match_type,
    bm.string_similarity,
    bm.price_diff,

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
        'step_size', NULL,
        'min_qty', xt.minqty,
        'max_qty', NULL,
        'max_market_qty', NULL,
        'min_notional', xt.minnotional,
        'max_notional', xt.maxnotional,
        'contract_size', xt.contractsize,
        'min_leverage', NULL,
        'max_leverage', NULL
    ) AS xt_info,

    -- ============================================================================
    -- 匹配的交易所信息 (动态 - 基于 bm.exchange)
    -- ============================================================================
    bm.exchange AS matched_exchange,

    -- Binance 信息
    CASE WHEN bm.exchange = 'binance' THEN
        jsonb_build_object(
            'exchange', 'binance',
            'symbol', bn.symbol,
            'base_asset', bn.baseasset,
            'quote_asset', bn.quoteasset,
            'multiplier', bm.exchange_multiplier,
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
    END AS binance_info,

    -- OKX 信息
    -- OKX 数量单位是张数，需要换算：币数量 = 张数 × ctVal × ctMult
    CASE WHEN bm.exchange = 'okx' THEN
        jsonb_build_object(
            'exchange', 'okx',
            'symbol', okx.instid,
            'base_asset', okx.baseccy,
            'quote_asset', okx.quoteccy,
            'multiplier', bm.exchange_multiplier,
            'price_precision', NULL,
            'quantity_precision', NULL,
            'tick_size', okx.ticksz,
            'min_price', NULL,
            'max_price', NULL,
            'step_size', okx.lotsz,
            'min_qty', (okx.minsz::numeric * NULLIF(okx.ctval::numeric, 0) * NULLIF(okx.ctmult::numeric, 0))::text,
            'max_qty', (okx.maxlmtsz::numeric * NULLIF(okx.ctval::numeric, 0) * NULLIF(okx.ctmult::numeric, 0))::text,
            'max_market_qty', (okx.maxmktsz::numeric * NULLIF(okx.ctval::numeric, 0) * NULLIF(okx.ctmult::numeric, 0))::text,
            'min_notional', NULL,
            'max_notional', okx.maxlmtamt,
            'contract_size', okx.ctval,
            'contract_multiplier', okx.ctmult,
            'min_leverage', '1',
            'max_leverage', okx.lever
        )
    END AS okx_info,

    -- Bybit 信息
    CASE WHEN bm.exchange = 'bybit' THEN
        jsonb_build_object(
            'exchange', 'bybit',
            'symbol', bb.symbol,
            'base_asset', bb.basecoin,
            'quote_asset', bb.quotecoin,
            'multiplier', bm.exchange_multiplier,
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
    END AS bybit_info,

    -- Gate 信息
    -- Gate 数量单位是张数，需要换算：币数量 = 张数 × contract_size
    CASE WHEN bm.exchange = 'gate' THEN
        jsonb_build_object(
            'exchange', 'gate',
            'symbol', gt.name,
            'base_asset', split_part(gt.name, '_', 1),
            'quote_asset', split_part(gt.name, '_', 2),
            'multiplier', bm.exchange_multiplier,
            'price_precision', NULL,
            'quantity_precision', NULL,
            'tick_size', gt.order_price_round,
            'min_price', NULL,
            'max_price', NULL,
            'step_size', NULL,
            'min_qty', (gt.order_size_min::numeric * NULLIF(gt.quanto_multiplier::numeric, 0))::text,
            'max_qty', (gt.order_size_max::numeric * NULLIF(gt.quanto_multiplier::numeric, 0))::text,
            'max_market_qty', (gt.market_order_size_max::numeric * NULLIF(gt.quanto_multiplier::numeric, 0))::text,
            'min_notional', NULL,
            'max_notional', NULL,
            'contract_size', gt.quanto_multiplier,
            'min_leverage', gt.leverage_min,
            'max_leverage', gt.leverage_max
        )
    END AS gate_info,

    -- KuCoin 信息
    CASE WHEN bm.exchange = 'kucoin' THEN
        jsonb_build_object(
            'exchange', 'kucoin',
            'symbol', kc.symbol,
            'base_asset', kc.basecurrency,
            'quote_asset', kc.quotecurrency,
            'multiplier', bm.exchange_multiplier,
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
    END AS kucoin_info,

    -- MEXC 信息
    -- MEXC 数量单位是张数，需要换算：币数量 = 张数 × contract_size
    CASE WHEN bm.exchange = 'mexc' THEN
        jsonb_build_object(
            'exchange', 'mexc',
            'symbol', mx.symbol,
            'base_asset', mx.basecoin,
            'quote_asset', mx.quotecoin,
            'multiplier', bm.exchange_multiplier,
            'price_precision', mx.pricescale::int,
            'quantity_precision', mx.volscale::int,
            'tick_size', mx.priceunit,
            'min_price', NULL,
            'max_price', NULL,
            'step_size', mx.volunit,
            'min_qty', (mx.minvol::numeric * NULLIF(mx.contractsize::numeric, 0))::text,
            'max_qty', (mx.maxvol::numeric * NULLIF(mx.contractsize::numeric, 0))::text,
            'max_market_qty', (mx.limitmaxvol::numeric * NULLIF(mx.contractsize::numeric, 0))::text,
            'min_notional', NULL,
            'max_notional', NULL,
            'contract_size', mx.contractsize,
            'min_leverage', mx.minleverage,
            'max_leverage', mx.maxleverage
        )
    END AS mexc_info

FROM base_mapping bm
LEFT JOIN xt_perpetual xt ON bm.xt_symbol = xt.symbol
LEFT JOIN binance_perpetual bn ON bm.exchange = 'binance' AND bm.exchange_symbol = bn.symbol
LEFT JOIN okx_perpetual okx ON bm.exchange = 'okx' AND bm.exchange_symbol = okx.instid
LEFT JOIN bybit_perpetual bb ON bm.exchange = 'bybit' AND bm.exchange_symbol = bb.symbol
LEFT JOIN gate_perpetual gt ON bm.exchange = 'gate' AND bm.exchange_symbol = gt.name
LEFT JOIN kucoin_perpetual kc ON bm.exchange = 'kucoin' AND bm.exchange_symbol = kc.symbol
LEFT JOIN mexc_perpetual mx ON bm.exchange = 'mexc' AND bm.exchange_symbol = mx.symbol;

-- 添加注释
COMMENT ON VIEW v_unified_trading_info IS '统一交易信息视图 - 包含精确匹配和模糊匹配的所有交易对信息';

-- ============================================================================
-- 使用示例
-- ============================================================================
--
-- 1. 查询单个 XT 交易对在所有交易所的信息（精确 + 模糊）:
-- SELECT
--     xt_symbol,
--     matched_exchange,
--     match_type,
--     string_similarity,
--     price_diff,
--     xt_info,
--     COALESCE(binance_info, okx_info, bybit_info, gate_info, kucoin_info, mexc_info) as exchange_info
-- FROM v_unified_trading_info
-- WHERE xt_symbol = 'btc_usdt'
-- ORDER BY match_type, matched_exchange;
--
-- 2. 只查询精确匹配的交易对:
-- SELECT * FROM v_unified_trading_info
-- WHERE xt_symbol = 'btc_usdt' AND match_type = 'exact';
--
-- 3. 只查询模糊匹配的交易对:
-- SELECT * FROM v_unified_trading_info
-- WHERE xt_symbol = 'aioz_usdt' AND match_type = 'fuzzy';
--
-- 4. 查询特定交易所的所有映射:
-- SELECT
--     xt_symbol,
--     match_type,
--     string_similarity,
--     xt_info->>'symbol' as xt_symbol,
--     binance_info->>'symbol' as binance_symbol,
--     binance_info->>'tick_size' as tick_size,
--     binance_info->>'min_qty' as min_qty
-- FROM v_unified_trading_info
-- WHERE matched_exchange = 'binance'
-- ORDER BY xt_symbol;
--
-- 5. 提取交易所的 min_qty (动态):
-- SELECT
--     xt_symbol,
--     matched_exchange,
--     match_type,
--     xt_info->>'min_qty' as xt_min_qty,
--     CASE
--         WHEN matched_exchange = 'binance' THEN binance_info->>'min_qty'
--         WHEN matched_exchange = 'okx' THEN okx_info->>'min_qty'
--         WHEN matched_exchange = 'bybit' THEN bybit_info->>'min_qty'
--         WHEN matched_exchange = 'gate' THEN gate_info->>'min_qty'
--         WHEN matched_exchange = 'kucoin' THEN kucoin_info->>'min_qty'
--         WHEN matched_exchange = 'mexc' THEN mexc_info->>'min_qty'
--     END as exchange_min_qty
-- FROM v_unified_trading_info
-- WHERE xt_symbol = 'btc_usdt';
--
-- 6. 查找高质量的模糊匹配（相似度 > 90%, 价格差异 < 1%）:
-- SELECT
--     xt_symbol,
--     matched_exchange,
--     string_similarity,
--     price_diff,
--     xt_info->>'base_asset' as xt_base,
--     CASE
--         WHEN matched_exchange = 'binance' THEN binance_info->>'base_asset'
--         WHEN matched_exchange = 'okx' THEN okx_info->>'base_asset'
--         WHEN matched_exchange = 'bybit' THEN bybit_info->>'base_asset'
--         WHEN matched_exchange = 'gate' THEN gate_info->>'base_asset'
--         WHEN matched_exchange = 'kucoin' THEN kucoin_info->>'base_asset'
--         WHEN matched_exchange = 'mexc' THEN mexc_info->>'base_asset'
--     END as exchange_base
-- FROM v_unified_trading_info
-- WHERE match_type = 'fuzzy'
--   AND string_similarity > 0.9
--   AND ABS(price_diff) < 0.01
-- ORDER BY string_similarity DESC;
--
-- 7. 汇总某个 XT 交易对的所有交易所覆盖情况:
-- SELECT
--     xt_symbol,
--     COUNT(*) as total_exchanges,
--     COUNT(*) FILTER (WHERE match_type = 'exact') as exact_matches,
--     COUNT(*) FILTER (WHERE match_type = 'fuzzy') as fuzzy_matches,
--     STRING_AGG(matched_exchange, ', ' ORDER BY matched_exchange) as exchanges
-- FROM v_unified_trading_info
-- WHERE xt_symbol = 'btc_usdt'
-- GROUP BY xt_symbol;
--
-- ============================================================================

-- ============================================================================
-- 宽表视图 - 方便对比所有交易所（类似原来的 v_trading_info）
-- ============================================================================
DROP VIEW IF EXISTS v_unified_trading_info_wide CASCADE;

CREATE VIEW v_unified_trading_info_wide AS
WITH xt_mappings AS (
    SELECT DISTINCT
        xt_symbol,
        normalized_pair,
        normalized_base,
        normalized_quote,
        xt_multiplier
    FROM unified_pair_mappings
    WHERE verified = true
)
SELECT
    xm.xt_symbol,
    xm.normalized_pair,
    xm.normalized_base,
    xm.normalized_quote,

    -- XT 信息
    jsonb_build_object(
        'exchange', 'xt',
        'symbol', xt.symbol,
        'base_asset', xt.basecoin,
        'quote_asset', xt.quotecoin,
        'multiplier', xm.xt_multiplier,
        'price_precision', xt.priceprecision::int,
        'quantity_precision', xt.quantityprecision::int,
        'tick_size', xt.minstepprice,
        'min_price', xt.minprice,
        'max_price', xt.maxprice,
        'min_qty', xt.minqty,
        'min_notional', xt.minnotional,
        'max_notional', xt.maxnotional,
        'contract_size', xt.contractsize
    ) AS xt_info,

    -- Binance 信息
    (SELECT jsonb_build_object(
        'exchange', 'binance',
        'symbol', bn.symbol,
        'match_type', upm.match_type,
        'similarity', upm.string_similarity,
        'multiplier', upm.exchange_multiplier,
        'tick_size', bn.filters_dict::jsonb -> 'PRICE_FILTER' ->> 'tickSize',
        'min_qty', bn.filters_dict::jsonb -> 'LOT_SIZE' ->> 'minQty',
        'min_notional', bn.filters_dict::jsonb -> 'MIN_NOTIONAL' ->> 'notional'
    ) FROM unified_pair_mappings upm
    JOIN binance_perpetual bn ON upm.exchange_symbol = bn.symbol
    WHERE upm.xt_symbol = xm.xt_symbol AND upm.exchange = 'binance' AND upm.verified = true
    LIMIT 1) AS binance_info,

    -- OKX 信息
    (SELECT jsonb_build_object(
        'exchange', 'okx',
        'symbol', okx.instid,
        'match_type', upm.match_type,
        'similarity', upm.string_similarity,
        'multiplier', upm.exchange_multiplier,
        'tick_size', okx.ticksz,
        'min_qty', (okx.minsz::numeric * NULLIF(okx.ctval::numeric, 0) * NULLIF(okx.ctmult::numeric, 0))::text,
        'contract_size', okx.ctval,
        'contract_multiplier', okx.ctmult
    ) FROM unified_pair_mappings upm
    JOIN okx_perpetual okx ON upm.exchange_symbol = okx.instid
    WHERE upm.xt_symbol = xm.xt_symbol AND upm.exchange = 'okx' AND upm.verified = true
    LIMIT 1) AS okx_info,

    -- Bybit 信息
    (SELECT jsonb_build_object(
        'exchange', 'bybit',
        'symbol', bb.symbol,
        'match_type', upm.match_type,
        'similarity', upm.string_similarity,
        'multiplier', upm.exchange_multiplier,
        'tick_size', bb.pricefilter::jsonb ->> 'tickSize',
        'min_qty', bb.lotsizefilter::jsonb ->> 'minOrderQty',
        'min_notional', bb.lotsizefilter::jsonb ->> 'minNotionalValue'
    ) FROM unified_pair_mappings upm
    JOIN bybit_perpetual bb ON upm.exchange_symbol = bb.symbol
    WHERE upm.xt_symbol = xm.xt_symbol AND upm.exchange = 'bybit' AND upm.verified = true
    LIMIT 1) AS bybit_info,

    -- Gate 信息
    (SELECT jsonb_build_object(
        'exchange', 'gate',
        'symbol', gt.name,
        'match_type', upm.match_type,
        'similarity', upm.string_similarity,
        'multiplier', upm.exchange_multiplier,
        'tick_size', gt.order_price_round,
        'min_qty', (gt.order_size_min::numeric * NULLIF(gt.quanto_multiplier::numeric, 0))::text,
        'contract_size', gt.quanto_multiplier
    ) FROM unified_pair_mappings upm
    JOIN gate_perpetual gt ON upm.exchange_symbol = gt.name
    WHERE upm.xt_symbol = xm.xt_symbol AND upm.exchange = 'gate' AND upm.verified = true
    LIMIT 1) AS gate_info,

    -- KuCoin 信息
    (SELECT jsonb_build_object(
        'exchange', 'kucoin',
        'symbol', kc.symbol,
        'match_type', upm.match_type,
        'similarity', upm.string_similarity,
        'multiplier', upm.exchange_multiplier,
        'tick_size', kc.ticksize,
        'max_qty', kc.maxorderqty,
        'contract_size', kc.multiplier
    ) FROM unified_pair_mappings upm
    JOIN kucoin_perpetual kc ON upm.exchange_symbol = kc.symbol
    WHERE upm.xt_symbol = xm.xt_symbol AND upm.exchange = 'kucoin' AND upm.verified = true
    LIMIT 1) AS kucoin_info,

    -- MEXC 信息
    (SELECT jsonb_build_object(
        'exchange', 'mexc',
        'symbol', mx.symbol,
        'match_type', upm.match_type,
        'similarity', upm.string_similarity,
        'multiplier', upm.exchange_multiplier,
        'tick_size', mx.priceunit,
        'min_qty', (mx.minvol::numeric * NULLIF(mx.contractsize::numeric, 0))::text,
        'contract_size', mx.contractsize
    ) FROM unified_pair_mappings upm
    JOIN mexc_perpetual mx ON upm.exchange_symbol = mx.symbol
    WHERE upm.xt_symbol = xm.xt_symbol AND upm.exchange = 'mexc' AND upm.verified = true
    LIMIT 1) AS mexc_info

FROM xt_mappings xm
LEFT JOIN xt_perpetual xt ON xm.xt_symbol = xt.symbol;

COMMENT ON VIEW v_unified_trading_info_wide IS '统一交易信息宽表视图 - 一行展示一个XT交易对在所有交易所的信息';

-- ============================================================================
-- 使用示例 (宽表)
-- ============================================================================
--
-- 1. 查看某个交易对在所有交易所的情况:
-- SELECT * FROM v_unified_trading_info_wide WHERE xt_symbol = 'btc_usdt';
--
-- 2. 查看有 Binance 映射的所有交易对:
-- SELECT xt_symbol, xt_info, binance_info
-- FROM v_unified_trading_info_wide
-- WHERE binance_info IS NOT NULL;
--
-- 3. 查看同时有精确和模糊匹配的交易对:
-- SELECT
--     xt_symbol,
--     binance_info->>'match_type' as bn_match,
--     okx_info->>'match_type' as okx_match,
--     bybit_info->>'match_type' as bb_match
-- FROM v_unified_trading_info_wide
-- WHERE binance_info IS NOT NULL OR okx_info IS NOT NULL OR bybit_info IS NOT NULL;
--
-- ============================================================================
