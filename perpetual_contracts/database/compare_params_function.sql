-- ============================================================================
-- 交易所参数对比函数
-- 将两个交易所的参数并排显示，方便直接对比
-- ============================================================================

DROP FUNCTION IF EXISTS compare_exchange_params(text, text, text);

CREATE OR REPLACE FUNCTION compare_exchange_params(
    p_xt_symbol text,
    p_exchange1 text DEFAULT 'xt',
    p_exchange2 text DEFAULT 'binance'
)
RETURNS TABLE (
    parameter text,
    exchange1_name text,
    exchange1_value text,
    exchange2_name text,
    exchange2_value text,
    is_different boolean
) AS $$
BEGIN
    RETURN QUERY
    WITH params AS (
        SELECT
            exchange,
            symbol,
            base_asset,
            quote_asset,
            multiplier::text,
            price_precision::text,
            quantity_precision::text,
            tick_size,
            min_price,
            max_price,
            step_size,
            min_qty,
            max_qty,
            max_market_qty,
            min_notional,
            max_notional,
            contract_size,
            min_leverage,
            max_leverage
        FROM v_exchange_params
        WHERE xt_symbol = p_xt_symbol
        AND exchange IN (p_exchange1, p_exchange2)
    ),
    ex1 AS (SELECT * FROM params WHERE exchange = p_exchange1),
    ex2 AS (SELECT * FROM params WHERE exchange = p_exchange2),
    param_values AS (
        SELECT 'symbol' as param_name, ex1.symbol as ex1_val, ex2.symbol as ex2_val
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'base_asset', ex1.base_asset, ex2.base_asset
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'quote_asset', ex1.quote_asset, ex2.quote_asset
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'multiplier', ex1.multiplier, ex2.multiplier
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'price_precision', ex1.price_precision, ex2.price_precision
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'quantity_precision', ex1.quantity_precision, ex2.quantity_precision
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'tick_size', ex1.tick_size, ex2.tick_size
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'min_price', ex1.min_price, ex2.min_price
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'max_price', ex1.max_price, ex2.max_price
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'step_size', ex1.step_size, ex2.step_size
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'min_qty', ex1.min_qty, ex2.min_qty
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'max_qty', ex1.max_qty, ex2.max_qty
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'max_market_qty', ex1.max_market_qty, ex2.max_market_qty
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'min_notional', ex1.min_notional, ex2.min_notional
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'max_notional', ex1.max_notional, ex2.max_notional
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'contract_size', ex1.contract_size, ex2.contract_size
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'min_leverage', ex1.min_leverage, ex2.min_leverage
        FROM ex1 FULL OUTER JOIN ex2 ON true
        UNION ALL
        SELECT 'max_leverage', ex1.max_leverage, ex2.max_leverage
        FROM ex1 FULL OUTER JOIN ex2 ON true
    )
    SELECT
        param_name::text,
        p_exchange1::text,
        COALESCE(ex1_val, '-')::text,
        p_exchange2::text,
        COALESCE(ex2_val, '-')::text,
        (COALESCE(ex1_val, '') != COALESCE(ex2_val, ''))::boolean
    FROM param_values;
END;
$$ LANGUAGE plpgsql;

-- 添加注释
COMMENT ON FUNCTION compare_exchange_params IS '对比两个交易所的参数配置，默认对比 XT 和 Binance';

-- ============================================================================
-- 使用示例
-- ============================================================================
--
-- 1. 对比 XT 和 Binance 的 BTC 配置（默认）:
-- SELECT * FROM compare_exchange_params('btc_usdt');
--
-- 2. 对比 XT 和 Bybit:
-- SELECT * FROM compare_exchange_params('btc_usdt', 'xt', 'bybit');
--
-- 3. 对比 Binance 和 OKX:
-- SELECT * FROM compare_exchange_params('eth_usdt', 'binance', 'okx');
--
-- 4. 只查看有差异的参数:
-- SELECT * FROM compare_exchange_params('1000shib_usdt')
-- WHERE is_different = true;
--
-- 5. 批量对比多个交易对:
-- SELECT
--     xt_symbol,
--     parameter,
--     exchange1_value,
--     exchange2_value
-- FROM (
--     SELECT '1000shib_usdt' as xt_symbol
--     UNION ALL
--     SELECT 'btc_usdt'
--     UNION ALL
--     SELECT 'eth_usdt'
-- ) symbols
-- CROSS JOIN LATERAL compare_exchange_params(xt_symbol, 'xt', 'binance')
-- WHERE is_different = true;
--
-- ============================================================================
