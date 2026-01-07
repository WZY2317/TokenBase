-- 模糊匹配映射表 Schema
-- 用于存储基于字符串相似度的模糊匹配结果

-- 创建序列（如果不存在）
CREATE SEQUENCE IF NOT EXISTS fuzzy_pair_mappings_id_seq;

-- 创建或替换表
CREATE TABLE IF NOT EXISTS fuzzy_pair_mappings (
    id integer NOT NULL DEFAULT nextval('fuzzy_pair_mappings_id_seq'::regclass),
    xt_symbol text NOT NULL,
    xt_base text NOT NULL,
    xt_quote text NOT NULL,
    xt_price numeric(20,10),
    exchange text NOT NULL,
    exchange_symbol text NOT NULL,
    exchange_base text NOT NULL,
    exchange_quote text NOT NULL,
    exchange_price numeric(20,10),
    string_similarity numeric(5,4),
    price_diff numeric(10,6),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    verified boolean DEFAULT true,
    notes text,

    CONSTRAINT fuzzy_pair_mappings_pkey PRIMARY KEY (id),
    CONSTRAINT fuzzy_pair_mappings_unique UNIQUE (xt_symbol, exchange)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_fuzzy_xt_symbol ON fuzzy_pair_mappings(xt_symbol);
CREATE INDEX IF NOT EXISTS idx_fuzzy_exchange ON fuzzy_pair_mappings(exchange);
CREATE INDEX IF NOT EXISTS idx_fuzzy_similarity ON fuzzy_pair_mappings(string_similarity);
CREATE INDEX IF NOT EXISTS idx_fuzzy_price_diff ON fuzzy_pair_mappings(price_diff);
