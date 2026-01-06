-- ============================================================================
-- 永续合约数据库 - 分表设计，统一字段
-- 每个交易所独立表，便于管理和查询优化
-- 跨交易所映射基于 base_asset + quote_asset
-- ============================================================================

DROP DATABASE IF EXISTS perpetual_trading;
CREATE DATABASE perpetual_trading;

\c perpetual_trading

-- ============================================================================
-- 1. Binance 永续合约表
-- ============================================================================
CREATE TABLE binance_perpetual (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(50) UNIQUE NOT NULL,
    base_asset VARCHAR(50) NOT NULL,
    quote_asset VARCHAR(20) NOT NULL,

    -- 精度
    price_precision INTEGER,
    quantity_precision INTEGER,
    tick_size DECIMAL(30, 15),
    step_size DECIMAL(30, 15),

    -- 订单限制
    min_qty DECIMAL(30, 15),
    max_qty DECIMAL(30, 15),
    min_notional DECIMAL(30, 15),

    -- 合约规格
    contract_size DECIMAL(30, 15) DEFAULT 1,
    max_leverage INTEGER,

    -- 费率
    maker_fee DECIMAL(10, 6),
    taker_fee DECIMAL(10, 6),

    -- 状态
    status VARCHAR(20) DEFAULT 'TRADING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_binance_symbol ON binance_perpetual(symbol);
CREATE INDEX idx_binance_base ON binance_perpetual(base_asset);
CREATE INDEX idx_binance_quote ON binance_perpetual(quote_asset);
CREATE INDEX idx_binance_base_quote ON binance_perpetual(base_asset, quote_asset);

-- ============================================================================
-- 2. XT 永续合约表
-- ============================================================================
CREATE TABLE xt_perpetual (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(50) UNIQUE NOT NULL,
    base_asset VARCHAR(50) NOT NULL,
    quote_asset VARCHAR(20) NOT NULL,

    price_precision INTEGER,
    quantity_precision INTEGER,
    tick_size DECIMAL(30, 15),
    step_size DECIMAL(30, 15),

    min_qty DECIMAL(30, 15),
    max_qty DECIMAL(30, 15),
    min_notional DECIMAL(30, 15),

    contract_size DECIMAL(30, 15) DEFAULT 1,
    max_leverage INTEGER,

    maker_fee DECIMAL(10, 6),
    taker_fee DECIMAL(10, 6),

    status VARCHAR(20) DEFAULT 'TRADING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_xt_symbol ON xt_perpetual(symbol);
CREATE INDEX idx_xt_base ON xt_perpetual(base_asset);
CREATE INDEX idx_xt_quote ON xt_perpetual(quote_asset);
CREATE INDEX idx_xt_base_quote ON xt_perpetual(base_asset, quote_asset);

-- ============================================================================
-- 3. OKX 永续合约表
-- ============================================================================
CREATE TABLE okx_perpetual (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(50) UNIQUE NOT NULL,
    base_asset VARCHAR(50) NOT NULL,
    quote_asset VARCHAR(20) NOT NULL,

    price_precision INTEGER,
    quantity_precision INTEGER,
    tick_size DECIMAL(30, 15),
    step_size DECIMAL(30, 15),

    min_qty DECIMAL(30, 15),
    max_qty DECIMAL(30, 15),
    min_notional DECIMAL(30, 15),

    contract_size DECIMAL(30, 15) DEFAULT 1,
    max_leverage INTEGER,

    maker_fee DECIMAL(10, 6),
    taker_fee DECIMAL(10, 6),

    status VARCHAR(20) DEFAULT 'TRADING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_okx_symbol ON okx_perpetual(symbol);
CREATE INDEX idx_okx_base ON okx_perpetual(base_asset);
CREATE INDEX idx_okx_quote ON okx_perpetual(quote_asset);
CREATE INDEX idx_okx_base_quote ON okx_perpetual(base_asset, quote_asset);

-- ============================================================================
-- 4. Bybit 永续合约表
-- ============================================================================
CREATE TABLE bybit_perpetual (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(50) UNIQUE NOT NULL,
    base_asset VARCHAR(50) NOT NULL,
    quote_asset VARCHAR(20) NOT NULL,

    price_precision INTEGER,
    quantity_precision INTEGER,
    tick_size DECIMAL(30, 15),
    step_size DECIMAL(30, 15),

    min_qty DECIMAL(30, 15),
    max_qty DECIMAL(30, 15),
    min_notional DECIMAL(30, 15),

    contract_size DECIMAL(30, 15) DEFAULT 1,
    max_leverage INTEGER,

    maker_fee DECIMAL(10, 6),
    taker_fee DECIMAL(10, 6),

    status VARCHAR(20) DEFAULT 'TRADING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bybit_symbol ON bybit_perpetual(symbol);
CREATE INDEX idx_bybit_base ON bybit_perpetual(base_asset);
CREATE INDEX idx_bybit_quote ON bybit_perpetual(quote_asset);
CREATE INDEX idx_bybit_base_quote ON bybit_perpetual(base_asset, quote_asset);

-- ============================================================================
-- 5. Gate 永续合约表
-- ============================================================================
CREATE TABLE gate_perpetual (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(50) UNIQUE NOT NULL,
    base_asset VARCHAR(50) NOT NULL,
    quote_asset VARCHAR(20) NOT NULL,

    price_precision INTEGER,
    quantity_precision INTEGER,
    tick_size DECIMAL(30, 15),
    step_size DECIMAL(30, 15),

    min_qty DECIMAL(30, 15),
    max_qty DECIMAL(30, 15),
    min_notional DECIMAL(30, 15),

    contract_size DECIMAL(30, 15) DEFAULT 1,
    max_leverage INTEGER,

    maker_fee DECIMAL(10, 6),
    taker_fee DECIMAL(10, 6),

    status VARCHAR(20) DEFAULT 'TRADING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gate_symbol ON gate_perpetual(symbol);
CREATE INDEX idx_gate_base ON gate_perpetual(base_asset);
CREATE INDEX idx_gate_quote ON gate_perpetual(quote_asset);
CREATE INDEX idx_gate_base_quote ON gate_perpetual(base_asset, quote_asset);

-- ============================================================================
-- 6. KuCoin 永续合约表
-- ============================================================================
CREATE TABLE kucoin_perpetual (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(50) UNIQUE NOT NULL,
    base_asset VARCHAR(50) NOT NULL,
    quote_asset VARCHAR(20) NOT NULL,

    price_precision INTEGER,
    quantity_precision INTEGER,
    tick_size DECIMAL(30, 15),
    step_size DECIMAL(30, 15),

    min_qty DECIMAL(30, 15),
    max_qty DECIMAL(30, 15),
    min_notional DECIMAL(30, 15),

    contract_size DECIMAL(30, 15) DEFAULT 1,
    max_leverage INTEGER,

    maker_fee DECIMAL(10, 6),
    taker_fee DECIMAL(10, 6),

    status VARCHAR(20) DEFAULT 'TRADING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_kucoin_symbol ON kucoin_perpetual(symbol);
CREATE INDEX idx_kucoin_base ON kucoin_perpetual(base_asset);
CREATE INDEX idx_kucoin_quote ON kucoin_perpetual(quote_asset);
CREATE INDEX idx_kucoin_base_quote ON kucoin_perpetual(base_asset, quote_asset);

-- ============================================================================
-- 7. MEXC 永续合约表
-- ============================================================================
CREATE TABLE mexc_perpetual (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(50) UNIQUE NOT NULL,
    base_asset VARCHAR(50) NOT NULL,
    quote_asset VARCHAR(20) NOT NULL,

    price_precision INTEGER,
    quantity_precision INTEGER,
    tick_size DECIMAL(30, 15),
    step_size DECIMAL(30, 15),

    min_qty DECIMAL(30, 15),
    max_qty DECIMAL(30, 15),
    min_notional DECIMAL(30, 15),

    contract_size DECIMAL(30, 15) DEFAULT 1,
    max_leverage INTEGER,

    maker_fee DECIMAL(10, 6),
    taker_fee DECIMAL(10, 6),

    status VARCHAR(20) DEFAULT 'TRADING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_mexc_symbol ON mexc_perpetual(symbol);
CREATE INDEX idx_mexc_base ON mexc_perpetual(base_asset);
CREATE INDEX idx_mexc_quote ON mexc_perpetual(quote_asset);
CREATE INDEX idx_mexc_base_quote ON mexc_perpetual(base_asset, quote_asset);

-- ============================================================================
-- 8. 交易所信息表
-- ============================================================================
CREATE TABLE exchanges (
    id SERIAL PRIMARY KEY,
    exchange_id VARCHAR(20) UNIQUE NOT NULL,
    exchange_name VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    api_base_url VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO exchanges (exchange_id, exchange_name, table_name, api_base_url) VALUES
    ('binance', 'Binance', 'binance_perpetual', 'https://fapi.binance.com'),
    ('okx', 'OKX', 'okx_perpetual', 'https://www.okx.com'),
    ('bybit', 'Bybit', 'bybit_perpetual', 'https://api.bybit.com'),
    ('gate', 'Gate.io', 'gate_perpetual', 'https://api.gateio.ws'),
    ('kucoin', 'KuCoin', 'kucoin_perpetual', 'https://api-futures.kucoin.com'),
    ('mexc', 'MEXC', 'mexc_perpetual', 'https://contract.mexc.com'),
    ('xt', 'XT.COM', 'xt_perpetual', 'https://fapi.xt.com');

-- ============================================================================
-- 9. 跨交易所映射工具函数
-- ============================================================================

-- 标准化符号函数（处理 1000X 等前缀）
CREATE OR REPLACE FUNCTION normalize_symbol(symbol TEXT) RETURNS TEXT AS $$
BEGIN
    -- 处理 1000000X 前缀（至少2个字母）
    IF symbol ~ '^1000000[A-Z]{2,}$' THEN
        RETURN substring(symbol from 8);
    END IF;

    -- 处理 10000X 前缀
    IF symbol ~ '^10000[A-Z]{2,}$' THEN
        RETURN substring(symbol from 6);
    END IF;

    -- 处理 1000X 前缀
    IF symbol ~ '^1000[A-Z]{2,}$' THEN
        RETURN substring(symbol from 5);
    END IF;

    -- 处理数字后缀（如 LUNA2 -> LUNA），但保留短符号如 A8, B2
    IF symbol ~ '^[A-Z]{3,}[0-9]$' THEN
        RETURN regexp_replace(symbol, '([A-Z]+)[0-9]+$', '\1');
    END IF;

    RETURN symbol;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 跨交易所匹配函数
CREATE OR REPLACE FUNCTION find_cross_exchange_match(
    xt_base_asset VARCHAR,
    xt_quote_asset VARCHAR,
    target_exchange VARCHAR
) RETURNS TABLE (
    symbol VARCHAR,
    base_asset VARCHAR,
    quote_asset VARCHAR,
    match_method VARCHAR,
    confidence VARCHAR
) AS $$
DECLARE
    normalized VARCHAR;
    table_name VARCHAR;
BEGIN
    normalized := normalize_symbol(xt_base_asset);

    -- 确定目标表名
    table_name := CASE target_exchange
        WHEN 'binance' THEN 'binance_perpetual'
        WHEN 'okx' THEN 'okx_perpetual'
        WHEN 'bybit' THEN 'bybit_perpetual'
        WHEN 'gate' THEN 'gate_perpetual'
        WHEN 'kucoin' THEN 'kucoin_perpetual'
        WHEN 'mexc' THEN 'mexc_perpetual'
        ELSE NULL
    END;

    IF table_name IS NULL THEN
        RETURN;
    END IF;

    -- 1. 精确匹配（最高置信度）
    RETURN QUERY EXECUTE format(
        'SELECT symbol, base_asset, quote_asset,
                ''EXACT''::VARCHAR as match_method,
                ''HIGH''::VARCHAR as confidence
         FROM %I
         WHERE base_asset = $1 AND quote_asset = $2
         LIMIT 1',
        table_name
    ) USING xt_base_asset, xt_quote_asset;

    IF FOUND THEN RETURN; END IF;

    -- 2. 标准化匹配（中等置信度）
    IF normalized <> xt_base_asset THEN
        RETURN QUERY EXECUTE format(
            'SELECT symbol, base_asset, quote_asset,
                    ''NORMALIZED''::VARCHAR as match_method,
                    ''MEDIUM''::VARCHAR as confidence
             FROM %I
             WHERE base_asset = $1 AND quote_asset = $2
             LIMIT 1',
            table_name
        ) USING normalized, xt_quote_asset;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 通过 XT 交易对查询所有交易所配置（基于 base_asset 匹配）
CREATE OR REPLACE FUNCTION get_all_exchanges_by_xt_symbol(xt_symbol_input VARCHAR)
RETURNS TABLE (
    exchange VARCHAR,
    symbol VARCHAR,
    base_asset VARCHAR,
    quote_asset VARCHAR,
    tick_size DECIMAL,
    step_size DECIMAL,
    min_qty DECIMAL,
    max_qty DECIMAL,
    min_notional DECIMAL,
    contract_size DECIMAL,
    max_leverage INTEGER,
    match_method VARCHAR
) AS $$
DECLARE
    xt_base VARCHAR;
    xt_quote VARCHAR;
BEGIN
    -- 1. 从XT表获取 base_asset 和 quote_asset
    SELECT xt.base_asset, xt.quote_asset INTO xt_base, xt_quote
    FROM xt_perpetual xt
    WHERE xt.symbol = xt_symbol_input
    LIMIT 1;

    IF xt_base IS NULL THEN
        RETURN;
    END IF;

    -- 2. 从所有交易所表查询该币种
    RETURN QUERY
    SELECT 'binance'::VARCHAR, m.symbol::VARCHAR, m.base_asset::VARCHAR, m.quote_asset::VARCHAR,
           bn.tick_size, bn.step_size, bn.min_qty, bn.max_qty, bn.min_notional,
           bn.contract_size, bn.max_leverage, m.match_method::VARCHAR
    FROM LATERAL find_cross_exchange_match(xt_base, xt_quote, 'binance') m
    INNER JOIN binance_perpetual bn ON m.symbol = bn.symbol

    UNION ALL

    SELECT 'xt'::VARCHAR, xt.symbol::VARCHAR, xt.base_asset::VARCHAR, xt.quote_asset::VARCHAR,
           xt.tick_size, xt.step_size, xt.min_qty, xt.max_qty, xt.min_notional,
           xt.contract_size, xt.max_leverage, 'EXACT'::VARCHAR
    FROM xt_perpetual xt
    WHERE xt.symbol = xt_symbol_input

    UNION ALL

    SELECT 'okx'::VARCHAR, m.symbol::VARCHAR, m.base_asset::VARCHAR, m.quote_asset::VARCHAR,
           okx.tick_size, okx.step_size, okx.min_qty, okx.max_qty, okx.min_notional,
           okx.contract_size, okx.max_leverage, m.match_method::VARCHAR
    FROM LATERAL find_cross_exchange_match(xt_base, xt_quote, 'okx') m
    INNER JOIN okx_perpetual okx ON m.symbol = okx.symbol

    UNION ALL

    SELECT 'bybit'::VARCHAR, m.symbol::VARCHAR, m.base_asset::VARCHAR, m.quote_asset::VARCHAR,
           bb.tick_size, bb.step_size, bb.min_qty, bb.max_qty, bb.min_notional,
           bb.contract_size, bb.max_leverage, m.match_method::VARCHAR
    FROM LATERAL find_cross_exchange_match(xt_base, xt_quote, 'bybit') m
    INNER JOIN bybit_perpetual bb ON m.symbol = bb.symbol

    UNION ALL

    SELECT 'gate'::VARCHAR, m.symbol::VARCHAR, m.base_asset::VARCHAR, m.quote_asset::VARCHAR,
           gt.tick_size, gt.step_size, gt.min_qty, gt.max_qty, gt.min_notional,
           gt.contract_size, gt.max_leverage, m.match_method::VARCHAR
    FROM LATERAL find_cross_exchange_match(xt_base, xt_quote, 'gate') m
    INNER JOIN gate_perpetual gt ON m.symbol = gt.symbol

    UNION ALL

    SELECT 'kucoin'::VARCHAR, m.symbol::VARCHAR, m.base_asset::VARCHAR, m.quote_asset::VARCHAR,
           kc.tick_size, kc.step_size, kc.min_qty, kc.max_qty, kc.min_notional,
           kc.contract_size, kc.max_leverage, m.match_method::VARCHAR
    FROM LATERAL find_cross_exchange_match(xt_base, xt_quote, 'kucoin') m
    INNER JOIN kucoin_perpetual kc ON m.symbol = kc.symbol

    UNION ALL

    SELECT 'mexc'::VARCHAR, m.symbol::VARCHAR, m.base_asset::VARCHAR, m.quote_asset::VARCHAR,
           mx.tick_size, mx.step_size, mx.min_qty, mx.max_qty, mx.min_notional,
           mx.contract_size, mx.max_leverage, m.match_method::VARCHAR
    FROM LATERAL find_cross_exchange_match(xt_base, xt_quote, 'mexc') m
    INNER JOIN mexc_perpetual mx ON m.symbol = mx.symbol

    ORDER BY 1;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 完成
-- ============================================================================
\echo '✅ 数据库创建完成！'
\echo ''
\echo '📊 已创建7个交易所独立表：'
\echo '   - binance_perpetual'
\echo '   - xt_perpetual'
\echo '   - okx_perpetual'
\echo '   - bybit_perpetual'
\echo '   - gate_perpetual'
\echo '   - kucoin_perpetual'
\echo '   - mexc_perpetual'
\echo ''
\echo '📚 辅助表：'
\echo '   - exchanges (交易所信息)'
\echo ''
\echo '⚙️  跨交易所映射函数：'
\echo '   - normalize_symbol(symbol) - 标准化币种符号'
\echo '   - find_cross_exchange_match(base, quote, exchange) - 跨交易所匹配'
\echo '   - get_all_exchanges_by_xt_symbol(xt_symbol) - 查询所有交易所配置'
\echo ''
\echo '💡 映射方式：基于 base_asset + quote_asset 直接匹配'
\echo ''
