-- 交易对映射表 Schema
-- 用于存储 XT 交易对到其他交易所的精确匹配映射

-- 创建序列（如果不存在）
CREATE SEQUENCE IF NOT EXISTS pair_mappings_id_seq;

-- 创建或替换表
CREATE TABLE IF NOT EXISTS pair_mappings (
    id integer NOT NULL DEFAULT nextval('pair_mappings_id_seq'::regclass),
    normalized_pair text NOT NULL,
    normalized_base text NOT NULL,
    normalized_quote text NOT NULL,
    xt_symbol text NOT NULL,
    xt_base text,
    xt_quote text,
    xt_multiplier integer DEFAULT 1,
    xt_price numeric(20,8),
    binance_symbol text,
    okx_symbol text,
    bybit_symbol text,
    gate_symbol text,
    kucoin_symbol text,
    mexc_symbol text,
    binance_multiplier integer,
    okx_multiplier integer,
    bybit_multiplier integer,
    gate_multiplier integer,
    kucoin_multiplier integer,
    mexc_multiplier integer,
    binance_price numeric(20,8),
    okx_price numeric(20,8),
    bybit_price numeric(20,8),
    gate_price numeric(20,8),
    kucoin_price numeric(20,8),
    mexc_price numeric(20,8),
    exchange_count integer DEFAULT 1,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pair_mappings_pkey PRIMARY KEY (id),
    CONSTRAINT pair_mappings_xt_symbol_key UNIQUE (xt_symbol)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_pair_mappings_normalized ON pair_mappings(normalized_pair);
CREATE INDEX IF NOT EXISTS idx_pair_mappings_base_quote ON pair_mappings(normalized_base, normalized_quote);
CREATE INDEX IF NOT EXISTS idx_pair_mappings_xt_symbol ON pair_mappings(xt_symbol);
CREATE INDEX IF NOT EXISTS idx_pair_mappings_binance ON pair_mappings(binance_symbol) WHERE binance_symbol IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pair_mappings_okx ON pair_mappings(okx_symbol) WHERE okx_symbol IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pair_mappings_bybit ON pair_mappings(bybit_symbol) WHERE bybit_symbol IS NOT NULL;
