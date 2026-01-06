-- 交易对映射表（列式存储）
CREATE TABLE IF NOT EXISTS pair_mappings (
    id SERIAL PRIMARY KEY,

    -- 标准化交易对
    normalized_pair TEXT NOT NULL,
    normalized_base TEXT NOT NULL,
    normalized_quote TEXT NOT NULL,

    -- XT信息（基准）
    xt_symbol TEXT NOT NULL UNIQUE,
    xt_base TEXT,
    xt_quote TEXT,
    xt_multiplier INT DEFAULT 1,
    xt_price DECIMAL(20, 8),

    -- 各交易所symbol（独立列）
    binance_symbol TEXT,
    okx_symbol TEXT,
    bybit_symbol TEXT,
    gate_symbol TEXT,
    kucoin_symbol TEXT,
    mexc_symbol TEXT,

    -- 各交易所倍数
    binance_multiplier INT,
    okx_multiplier INT,
    bybit_multiplier INT,
    gate_multiplier INT,
    kucoin_multiplier INT,
    mexc_multiplier INT,

    -- 各交易所价格
    binance_price DECIMAL(20, 8),
    okx_price DECIMAL(20, 8),
    bybit_price DECIMAL(20, 8),
    gate_price DECIMAL(20, 8),
    kucoin_price DECIMAL(20, 8),
    mexc_price DECIMAL(20, 8),

    -- 统计
    exchange_count INT DEFAULT 1,

    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_pair_mappings_normalized ON pair_mappings(normalized_pair);
CREATE INDEX IF NOT EXISTS idx_pair_mappings_base_quote ON pair_mappings(normalized_base, normalized_quote);
CREATE INDEX IF NOT EXISTS idx_pair_mappings_xt_symbol ON pair_mappings(xt_symbol);
CREATE INDEX IF NOT EXISTS idx_pair_mappings_binance ON pair_mappings(binance_symbol) WHERE binance_symbol IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pair_mappings_okx ON pair_mappings(okx_symbol) WHERE okx_symbol IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pair_mappings_bybit ON pair_mappings(bybit_symbol) WHERE bybit_symbol IS NOT NULL;

-- 注释
COMMENT ON TABLE pair_mappings IS 'XT与其他交易所的交易对映射表（列式存储）';
COMMENT ON COLUMN pair_mappings.normalized_pair IS '标准化后的交易对名称';
COMMENT ON COLUMN pair_mappings.xt_symbol IS 'XT交易对符号';
COMMENT ON COLUMN pair_mappings.binance_symbol IS 'Binance对应的交易对符号';
COMMENT ON COLUMN pair_mappings.okx_symbol IS 'OKX对应的交易对符号';
COMMENT ON COLUMN pair_mappings.exchange_count IS '支持的交易所总数（包括XT）';
