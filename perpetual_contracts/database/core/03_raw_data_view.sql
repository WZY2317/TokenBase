-- ============================================================================
-- 原始数据视图 (v_raw_data)
-- ============================================================================
--
-- 【用途】
--   返回各交易所的完整原始数据（JSONB 格式），包含所有 API 原始字段
--   宽表格式：一行一个 XT 交易对，展示所有交易所的原始数据
--
-- 【数据来源】
--   - unified_pair_mappings: 映射关系表
--   - 各交易所的原始表: xt_perpetual, binance_perpetual, okx_perpetual 等
--
-- 【返回字段】
--   - xt_symbol: XT 交易对标识
--   - normalized_pair/base/quote: 标准化交易对信息
--   - xt_raw_data: XT 原始数据 (JSONB)
--   - binance_raw_data: Binance 原始数据 (JSONB)
--   - okx_raw_data: OKX 原始数据 (JSONB)
--   - bybit_raw_data: Bybit 原始数据 (JSONB)
--   - gate_raw_data: Gate 原始数据 (JSONB)
--   - kucoin_raw_data: KuCoin 原始数据 (JSONB)
--   - mexc_raw_data: MEXC 原始数据 (JSONB)
--
-- 【使用场景】
--   1. 查看 API 返回的完整原始字段
--   2. 调试数据映射问题
--   3. 查找标准化视图中未包含的字段
--   4. 对比原始数据和标准化数据的差异
--
-- 【查询示例】
--   见文件底部的使用示例部分
--
-- ============================================================================

DROP VIEW IF EXISTS v_raw_data CASCADE;

CREATE VIEW v_raw_data AS
WITH base_mapping AS (
    SELECT DISTINCT
        xt_symbol,
        normalized_pair,
        normalized_base,
        normalized_quote
    FROM unified_pair_mappings
    WHERE verified = true
)
SELECT
    bm.xt_symbol,
    bm.normalized_pair,
    bm.normalized_base,
    bm.normalized_quote,

    -- ============================================================================
    -- XT 原始数据（所有字段转为 JSONB）
    -- ============================================================================
    to_jsonb(xt.*) AS xt_raw_data,

    -- ============================================================================
    -- 所有交易所的原始数据
    -- ============================================================================
    (SELECT to_jsonb(bn.*)
     FROM unified_pair_mappings upm
     JOIN binance_perpetual bn ON upm.exchange = 'binance' AND upm.exchange_symbol = bn.symbol
     WHERE upm.xt_symbol = bm.xt_symbol AND upm.verified = true
     LIMIT 1) AS binance_raw_data,

    (SELECT to_jsonb(okx.*)
     FROM unified_pair_mappings upm
     JOIN okx_perpetual okx ON upm.exchange = 'okx' AND upm.exchange_symbol = okx.instid
     WHERE upm.xt_symbol = bm.xt_symbol AND upm.verified = true
     LIMIT 1) AS okx_raw_data,

    (SELECT to_jsonb(bb.*)
     FROM unified_pair_mappings upm
     JOIN bybit_perpetual bb ON upm.exchange = 'bybit' AND upm.exchange_symbol = bb.symbol
     WHERE upm.xt_symbol = bm.xt_symbol AND upm.verified = true
     LIMIT 1) AS bybit_raw_data,

    (SELECT to_jsonb(gt.*)
     FROM unified_pair_mappings upm
     JOIN gate_perpetual gt ON upm.exchange = 'gate' AND upm.exchange_symbol = gt.name
     WHERE upm.xt_symbol = bm.xt_symbol AND upm.verified = true
     LIMIT 1) AS gate_raw_data,

    (SELECT to_jsonb(kc.*)
     FROM unified_pair_mappings upm
     JOIN kucoin_perpetual kc ON upm.exchange = 'kucoin' AND upm.exchange_symbol = kc.symbol
     WHERE upm.xt_symbol = bm.xt_symbol AND upm.verified = true
     LIMIT 1) AS kucoin_raw_data,

    (SELECT to_jsonb(mx.*)
     FROM unified_pair_mappings upm
     JOIN mexc_perpetual mx ON upm.exchange = 'mexc' AND upm.exchange_symbol = mx.symbol
     WHERE upm.xt_symbol = bm.xt_symbol AND upm.verified = true
     LIMIT 1) AS mexc_raw_data

FROM base_mapping bm
LEFT JOIN xt_perpetual xt ON bm.xt_symbol = xt.symbol;

-- 添加注释
COMMENT ON VIEW v_raw_data IS '原始数据视图 - 返回所有交易所的完整原始数据（JSONB格式），宽表格式';

-- ============================================================================
-- 使用示例
-- ============================================================================
--
-- 1. 查询单个 XT 交易对在所有交易所的原始数据:
-- SELECT * FROM v_raw_data WHERE xt_symbol = 'btc_usdt';
--
-- 2. 查询 XT 的原始数据（所有字段）:
-- SELECT
--     xt_symbol,
--     xt_raw_data
-- FROM v_raw_data
-- WHERE xt_symbol = 'btc_usdt';
--
-- 3. 查询 Binance 的特定原始字段:
-- SELECT
--     xt_symbol,
--     binance_raw_data->>'symbol' as symbol,
--     binance_raw_data->>'underlyingType' as underlying_type,
--     binance_raw_data->>'contractType' as contract_type,
--     binance_raw_data->>'filters' as filters
-- FROM v_raw_data
-- WHERE binance_raw_data IS NOT NULL
--   AND xt_symbol = 'btc_usdt';
--
-- 4. 查询 OKX 的所有原始字段（查看字段列表）:
-- SELECT DISTINCT jsonb_object_keys(okx_raw_data)
-- FROM v_raw_data
-- WHERE okx_raw_data IS NOT NULL
-- LIMIT 1;
--
-- 5. 对比标准化数据和原始数据:
-- SELECT
--     r.xt_symbol,
--     -- 标准化后的字段（从 unified_trading_info_wide 获取）
--     u.okx_info->>'min_qty' as standardized_min_qty,
--     -- 原始字段
--     r.okx_raw_data->>'minsz' as raw_min_qty,
--     r.okx_raw_data->>'ctval' as raw_ctval,
--     r.okx_raw_data->>'ctmult' as raw_ctmult
-- FROM v_raw_data r
-- JOIN v_unified_trading_info_wide u ON r.xt_symbol = u.xt_symbol
-- WHERE r.xt_symbol = 'btc_usdt' AND r.okx_raw_data IS NOT NULL;
--
-- 6. 查看 Binance 的完整 filters 原始数据:
-- SELECT
--     xt_symbol,
--     binance_raw_data->>'filters' as filters,
--     binance_raw_data->>'orderTypes' as order_types,
--     binance_raw_data->>'timeInForce' as time_in_force
-- FROM v_raw_data
-- WHERE xt_symbol = 'btc_usdt' AND binance_raw_data IS NOT NULL;
--
-- 7. 查找某个交易所特有的字段（不在标准化视图中）:
-- -- 例如 Binance 的 underlyingType
-- SELECT
--     xt_symbol,
--     binance_raw_data->>'underlyingType' as underlying_type,
--     binance_raw_data->>'contractType' as contract_type,
--     binance_raw_data->>'deliveryDate' as delivery_date
-- FROM v_raw_data
-- WHERE binance_raw_data IS NOT NULL
-- LIMIT 10;
--
-- 8. 统计每个交易所有多少原始字段:
-- SELECT
--     'binance' as exchange,
--     COUNT(DISTINCT jsonb_object_keys(binance_raw_data)) as field_count
-- FROM v_raw_data
-- WHERE binance_raw_data IS NOT NULL
-- UNION ALL
-- SELECT
--     'okx',
--     COUNT(DISTINCT jsonb_object_keys(okx_raw_data))
-- FROM v_raw_data
-- WHERE okx_raw_data IS NOT NULL
-- UNION ALL
-- SELECT
--     'bybit',
--     COUNT(DISTINCT jsonb_object_keys(bybit_raw_data))
-- FROM v_raw_data
-- WHERE bybit_raw_data IS NOT NULL;
--
-- 9. 查看所有 XT 的原始字段名:
-- SELECT DISTINCT jsonb_object_keys(xt_raw_data)
-- FROM v_raw_data
-- LIMIT 1;
--
-- 10. 提取嵌套的 JSONB 字段（如 Binance 的 filters）:
-- SELECT
--     xt_symbol,
--     binance_raw_data->'filters' as all_filters,
--     binance_raw_data->'filters'->0 as price_filter
-- FROM v_raw_data
-- WHERE binance_raw_data IS NOT NULL
--   AND xt_symbol = 'btc_usdt';
--
-- 11. 查看某个交易对在哪些交易所有映射:
-- SELECT
--     xt_symbol,
--     CASE WHEN binance_raw_data IS NOT NULL THEN 'Y' END as has_binance,
--     CASE WHEN okx_raw_data IS NOT NULL THEN 'Y' END as has_okx,
--     CASE WHEN bybit_raw_data IS NOT NULL THEN 'Y' END as has_bybit,
--     CASE WHEN gate_raw_data IS NOT NULL THEN 'Y' END as has_gate,
--     CASE WHEN kucoin_raw_data IS NOT NULL THEN 'Y' END as has_kucoin,
--     CASE WHEN mexc_raw_data IS NOT NULL THEN 'Y' END as has_mexc
-- FROM v_raw_data
-- WHERE xt_symbol = 'btc_usdt';
--
-- ============================================================================
