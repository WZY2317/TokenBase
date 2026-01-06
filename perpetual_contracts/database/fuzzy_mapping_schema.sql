-- ============================================================================
-- 模糊匹配映射表
-- 存储通过模糊字符串匹配 + 价格验证找到的交易对映射
-- 与 pair_mappings 表分离，避免混淆
-- ============================================================================

DROP TABLE IF EXISTS fuzzy_pair_mappings CASCADE;

CREATE TABLE fuzzy_pair_mappings (
    id SERIAL PRIMARY KEY,

    -- XT 交易对信息
    xt_symbol TEXT NOT NULL,
    xt_base TEXT NOT NULL,
    xt_quote TEXT NOT NULL,
    xt_price NUMERIC(20, 10),

    -- 匹配的交易所
    exchange TEXT NOT NULL,  -- binance, okx, bybit, gate, kucoin, mexc

    -- 交易所交易对信息
    exchange_symbol TEXT NOT NULL,
    exchange_base TEXT NOT NULL,
    exchange_quote TEXT NOT NULL,
    exchange_price NUMERIC(20, 10),

    -- 匹配质量指标
    string_similarity NUMERIC(5, 4),  -- 字符串相似度 (0.0 - 1.0)
    price_diff NUMERIC(10, 6),         -- 价格差异百分比

    -- 元数据
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified BOOLEAN DEFAULT true,     -- 是否已验证
    notes TEXT,                         -- 备注

    -- 唯一约束：同一个 XT 交易对在同一个交易所只能有一个模糊匹配
    CONSTRAINT fuzzy_pair_mappings_unique UNIQUE (xt_symbol, exchange)
);

-- 创建索引
CREATE INDEX idx_fuzzy_xt_symbol ON fuzzy_pair_mappings(xt_symbol);
CREATE INDEX idx_fuzzy_exchange ON fuzzy_pair_mappings(exchange);
CREATE INDEX idx_fuzzy_similarity ON fuzzy_pair_mappings(string_similarity);
CREATE INDEX idx_fuzzy_price_diff ON fuzzy_pair_mappings(price_diff);

-- 添加注释
COMMENT ON TABLE fuzzy_pair_mappings IS '模糊匹配映射表 - 通过字符串相似度和价格验证找到的特殊映射';
COMMENT ON COLUMN fuzzy_pair_mappings.string_similarity IS '字符串相似度分数 (0.0 - 1.0)';
COMMENT ON COLUMN fuzzy_pair_mappings.price_diff IS '价格差异百分比 (如 0.035 表示 3.5%)';
COMMENT ON COLUMN fuzzy_pair_mappings.verified IS '是否已人工验证';

-- ============================================================================
-- 模糊匹配汇总视图
-- ============================================================================

DROP VIEW IF EXISTS v_fuzzy_mappings_summary CASCADE;

CREATE VIEW v_fuzzy_mappings_summary AS
SELECT
    xt_symbol,
    xt_base,
    xt_quote,
    xt_price,
    COUNT(DISTINCT exchange) as exchange_count,
    STRING_AGG(DISTINCT exchange, ', ' ORDER BY exchange) as exchanges,
    AVG(string_similarity) as avg_similarity,
    AVG(price_diff) as avg_price_diff,
    MIN(created_at) as first_found
FROM fuzzy_pair_mappings
WHERE verified = true
GROUP BY xt_symbol, xt_base, xt_quote, xt_price
ORDER BY exchange_count DESC, xt_symbol;

COMMENT ON VIEW v_fuzzy_mappings_summary IS '模糊匹配汇总视图 - 按 XT 交易对汇总';

-- ============================================================================
-- 使用示例
-- ============================================================================
--
-- 1. 查看所有模糊匹配:
-- SELECT * FROM fuzzy_pair_mappings ORDER BY xt_symbol, exchange;
--
-- 2. 查看特定 XT 交易对的所有模糊匹配:
-- SELECT * FROM fuzzy_pair_mappings WHERE xt_symbol = 'broccoli_usdt';
--
-- 3. 查看汇总信息:
-- SELECT * FROM v_fuzzy_mappings_summary;
--
-- 4. 查看高质量的模糊匹配 (相似度 > 90%, 价格差异 < 1%):
-- SELECT * FROM fuzzy_pair_mappings
-- WHERE string_similarity > 0.9 AND price_diff < 0.01
-- ORDER BY string_similarity DESC;
--
-- 5. 查看某个交易所的所有模糊匹配:
-- SELECT * FROM fuzzy_pair_mappings WHERE exchange = 'binance';
--
-- 6. 对比模糊匹配和精确匹配:
-- SELECT
--     fpm.xt_symbol,
--     fpm.exchange,
--     fpm.exchange_symbol as fuzzy_symbol,
--     pm.binance_symbol as exact_symbol,
--     fpm.string_similarity,
--     fpm.price_diff
-- FROM fuzzy_pair_mappings fpm
-- LEFT JOIN pair_mappings pm ON fpm.xt_symbol = pm.xt_symbol
-- WHERE fpm.exchange = 'binance'
-- ORDER BY fpm.xt_symbol;
--
-- ============================================================================
