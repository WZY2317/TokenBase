--
-- PostgreSQL database dump
--

\restrict hqywNBnTM2cWxlRybeh19DEP6CwLYoyuN6HKI51rQazeSRiPDTDGSKbuuFPV7Nb

-- Dumped from database version 15.14 (Homebrew)
-- Dumped by pg_dump version 15.14 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: binance_perpetual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.binance_perpetual (
    id integer NOT NULL,
    baseasset text,
    baseassetprecision text,
    contracttype text,
    deliverydate text,
    filters text,
    filters_dict text,
    liquidationfee text,
    maintmarginpercent text,
    marginasset text,
    markettakebound text,
    maxmoveorderlimit text,
    onboarddate text,
    ordertypes text,
    pair text,
    permissionsets text,
    priceprecision text,
    quantityprecision text,
    quoteasset text,
    quoteprecision text,
    requiredmarginpercent text,
    status text,
    symbol text NOT NULL,
    timeinforce text,
    triggerprotect text,
    underlyingsubtype text,
    underlyingtype text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: binance_perpetual_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.binance_perpetual_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: binance_perpetual_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.binance_perpetual_id_seq OWNED BY public.binance_perpetual.id;


--
-- Name: bybit_perpetual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bybit_perpetual (
    id integer NOT NULL,
    basecoin text,
    contracttype text,
    copytrading text,
    deliveryfeerate text,
    deliverytime text,
    displayname text,
    forbiduplwithdrawal text,
    fundinginterval text,
    isprelisting text,
    launchtime text,
    leveragefilter text,
    lotsizefilter text,
    lowerfundingrate text,
    prelistinginfo text,
    pricefilter text,
    pricescale text,
    quotecoin text,
    riskparameters text,
    settlecoin text,
    status text,
    symbol text NOT NULL,
    symboltype text,
    unifiedmargintrade text,
    upperfundingrate text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: bybit_perpetual_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bybit_perpetual_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bybit_perpetual_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bybit_perpetual_id_seq OWNED BY public.bybit_perpetual.id;


--
-- Name: fuzzy_pair_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fuzzy_pair_mappings (
    id integer NOT NULL,
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
    notes text
);


--
-- Name: TABLE fuzzy_pair_mappings; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.fuzzy_pair_mappings IS '模糊匹配映射表 - 通过字符串相似度和价格验证找到的特殊映射';


--
-- Name: COLUMN fuzzy_pair_mappings.string_similarity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fuzzy_pair_mappings.string_similarity IS '字符串相似度分数 (0.0 - 1.0)';


--
-- Name: COLUMN fuzzy_pair_mappings.price_diff; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fuzzy_pair_mappings.price_diff IS '价格差异百分比 (如 0.035 表示 3.5%)';


--
-- Name: COLUMN fuzzy_pair_mappings.verified; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fuzzy_pair_mappings.verified IS '是否已人工验证';


--
-- Name: fuzzy_pair_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fuzzy_pair_mappings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fuzzy_pair_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fuzzy_pair_mappings_id_seq OWNED BY public.fuzzy_pair_mappings.id;


--
-- Name: gate_perpetual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gate_perpetual (
    id integer NOT NULL,
    config_change_time text,
    create_time text,
    cross_leverage_default text,
    enable_bonus text,
    enable_circuit_breaker text,
    enable_credit text,
    funding_cap_ratio text,
    funding_impact_value text,
    funding_interval text,
    funding_next_apply text,
    funding_offset text,
    funding_rate text,
    funding_rate_indicative text,
    funding_rate_limit text,
    in_delisting text,
    index_price text,
    interest_rate text,
    is_pre_market text,
    last_price text,
    launch_time text,
    leverage_max text,
    leverage_min text,
    long_users text,
    maintenance_rate text,
    maker_fee_rate text,
    mark_price text,
    mark_price_round text,
    mark_type text,
    market_order_size_max text,
    market_order_slip_ratio text,
    name text NOT NULL,
    order_price_deviate text,
    order_price_round text,
    order_size_max text,
    order_size_min text,
    orderbook_id text,
    orders_limit text,
    position_size text,
    quanto_multiplier text,
    ref_discount_rate text,
    ref_rebate_rate text,
    risk_limit_base text,
    risk_limit_max text,
    risk_limit_step text,
    short_users text,
    status text,
    taker_fee_rate text,
    trade_id text,
    trade_size text,
    type text,
    voucher_leverage text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: gate_perpetual_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gate_perpetual_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gate_perpetual_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gate_perpetual_id_seq OWNED BY public.gate_perpetual.id;


--
-- Name: kucoin_perpetual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kucoin_perpetual (
    id integer NOT NULL,
    adjustactivetime text,
    adjustk text,
    adjustm text,
    adjustmmrlevconstant text,
    basecurrency text,
    buylimit text,
    crossrisklimit text,
    currentfundingrategranularity text,
    dailyinterestrate text,
    displaybasecurrency text,
    displaysymbol text,
    effectivefundingratecyclestarttime text,
    expiredate text,
    f text,
    fairmethod text,
    firstopendate text,
    fundingbasesymbol text,
    fundingbasesymbol1m text,
    fundingfeerate text,
    fundingquotesymbol text,
    fundingquotesymbol1m text,
    fundingratecap text,
    fundingratefloor text,
    fundingrategranularity text,
    fundingratesymbol text,
    highprice text,
    indexprice text,
    indexpriceticksize text,
    indexsymbol text,
    initialmargin text,
    isdeleverage text,
    isinverse text,
    isquanto text,
    k text,
    lasttradeprice text,
    lotsize text,
    lowprice text,
    m text,
    maintainmargin text,
    makerfeerate text,
    makerfixfee text,
    markmethod text,
    markprice text,
    marketmaxorderqty text,
    marketstage text,
    maxleverage text,
    maxorderqty text,
    maxprice text,
    maxrisklimit text,
    minrisklimit text,
    mmrlevconstant text,
    mmrlimit text,
    multiplier text,
    nextfundingratedatetime text,
    nextfundingratetime text,
    openinterest text,
    orderpricerange text,
    period text,
    premarkettoperpdate text,
    predictedfundingfeerate text,
    premiumssymbol1m text,
    premiumssymbol8h text,
    pricechg text,
    pricechgpct text,
    quotecurrency text,
    riskstep text,
    rootsymbol text,
    selllimit text,
    settlecurrency text,
    settledate text,
    settlementfee text,
    settlementsymbol text,
    sourceexchanges text,
    status text,
    supportcross text,
    symbol text NOT NULL,
    takerfeerate text,
    takerfixfee text,
    ticksize text,
    turnoverof24h text,
    type text,
    volumeof24h text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: kucoin_perpetual_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.kucoin_perpetual_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: kucoin_perpetual_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.kucoin_perpetual_id_seq OWNED BY public.kucoin_perpetual.id;


--
-- Name: mexc_perpetual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mexc_perpetual (
    id integer NOT NULL,
    amountscale text,
    apiallowed text,
    api_id text,
    appraisal text,
    asklimitpricerate text,
    automaticdelivery text,
    basecoin text,
    basecoiniconurl text,
    basecoinid text,
    basecoinname text,
    bidlimitpricerate text,
    conceptplate text,
    conceptplateid text,
    contractsize text,
    countryconfigcontractmaxleverage text,
    createtime text,
    deliverypricetrend text,
    deliverytime text,
    depthsteplist text,
    displayname text,
    displaynameen text,
    feeratemode text,
    futuretype text,
    indexorigin text,
    initialmarginrate text,
    ishidden text,
    ishot text,
    ismaxleverage text,
    isnew text,
    iszerofeerate text,
    iszerofeesymbol text,
    leveragefeerates text,
    limitmaxvol text,
    liquidationfeerate text,
    maintenancemarginrate text,
    makerfeerate text,
    marketordermaxlevel text,
    marketorderpricelimitrate1 text,
    marketorderpricelimitrate2 text,
    maxleverage text,
    maxnumorders text,
    maxvol text,
    minleverage text,
    minvol text,
    openingcountdownoption text,
    openingtime text,
    positionopentype text,
    premarket text,
    pricecoefficientvariation text,
    pricescale text,
    priceunit text,
    quotecoin text,
    quotecoinname text,
    riskbasevol text,
    riskincrimr text,
    riskincrmmr text,
    riskincrvol text,
    risklevellimit text,
    risklimitcustom text,
    risklimitmode text,
    risklimittype text,
    risklongshortswitch text,
    settlecoin text,
    showappraisalcountdown text,
    showbeforeopen text,
    state text,
    stoponlyfair text,
    symbol text NOT NULL,
    takerfeerate text,
    threshold text,
    tieredfeerates text,
    triggerprotect text,
    type text,
    vid text,
    volscale text,
    volunit text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: mexc_perpetual_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mexc_perpetual_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mexc_perpetual_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mexc_perpetual_id_seq OWNED BY public.mexc_perpetual.id;


--
-- Name: okx_perpetual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.okx_perpetual (
    id integer NOT NULL,
    alias text,
    auctionendtime text,
    baseccy text,
    category text,
    conttdswtime text,
    ctmult text,
    cttype text,
    ctval text,
    ctvalccy text,
    exptime text,
    futuresettlement text,
    groupid text,
    instfamily text,
    instid text NOT NULL,
    instidcode text,
    insttype text,
    lever text,
    listtime text,
    longposremainingquota text,
    lotsz text,
    maxicebergsz text,
    maxlmtamt text,
    maxlmtsz text,
    maxmktamt text,
    maxmktsz text,
    maxplatoilmt text,
    maxstopsz text,
    maxtriggersz text,
    maxtwapsz text,
    minsz text,
    opentype text,
    opttype text,
    poslmtamt text,
    poslmtpct text,
    premktswtime text,
    quoteccy text,
    ruletype text,
    settleccy text,
    shortposremainingquota text,
    state text,
    stk text,
    ticksz text,
    tradequoteccylist text,
    uly text,
    upcchg text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: okx_perpetual_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.okx_perpetual_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: okx_perpetual_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.okx_perpetual_id_seq OWNED BY public.okx_perpetual.id;


--
-- Name: pair_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pair_mappings (
    id integer NOT NULL,
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
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE pair_mappings; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pair_mappings IS 'XT与其他交易所的交易对映射表（列式存储）';


--
-- Name: COLUMN pair_mappings.normalized_pair; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pair_mappings.normalized_pair IS '标准化后的交易对名称';


--
-- Name: COLUMN pair_mappings.xt_symbol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pair_mappings.xt_symbol IS 'XT交易对符号';


--
-- Name: COLUMN pair_mappings.binance_symbol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pair_mappings.binance_symbol IS 'Binance对应的交易对符号';


--
-- Name: COLUMN pair_mappings.okx_symbol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pair_mappings.okx_symbol IS 'OKX对应的交易对符号';


--
-- Name: COLUMN pair_mappings.exchange_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pair_mappings.exchange_count IS '支持的交易所总数（包括XT）';


--
-- Name: pair_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pair_mappings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pair_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pair_mappings_id_seq OWNED BY public.pair_mappings.id;


--
-- Name: unified_pair_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unified_pair_mappings (
    id integer NOT NULL,
    xt_symbol text NOT NULL,
    xt_base text NOT NULL,
    xt_quote text NOT NULL,
    xt_price numeric(20,10),
    xt_multiplier integer DEFAULT 1,
    normalized_pair text NOT NULL,
    normalized_base text NOT NULL,
    normalized_quote text NOT NULL,
    exchange text NOT NULL,
    exchange_symbol text NOT NULL,
    exchange_base text,
    exchange_quote text,
    exchange_price numeric(20,10),
    exchange_multiplier integer DEFAULT 1,
    match_type text NOT NULL,
    string_similarity numeric(5,4),
    price_diff numeric(20,10),
    verified boolean DEFAULT true,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unified_pair_mappings_match_type_check CHECK ((match_type = ANY (ARRAY['exact'::text, 'fuzzy'::text])))
);


--
-- Name: TABLE unified_pair_mappings; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.unified_pair_mappings IS '统一映射表 - 包含精确匹配和模糊匹配的所有交易对映射';


--
-- Name: COLUMN unified_pair_mappings.match_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unified_pair_mappings.match_type IS '匹配类型: exact(精确匹配) 或 fuzzy(模糊匹配)';


--
-- Name: COLUMN unified_pair_mappings.string_similarity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unified_pair_mappings.string_similarity IS '字符串相似度分数 (0.0 - 1.0)，精确匹配为 1.0';


--
-- Name: COLUMN unified_pair_mappings.price_diff; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unified_pair_mappings.price_diff IS '价格差异百分比 (如 0.035 表示 3.5%)';


--
-- Name: COLUMN unified_pair_mappings.verified; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unified_pair_mappings.verified IS '是否已验证（人工或自动）';


--
-- Name: unified_pair_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.unified_pair_mappings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: unified_pair_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.unified_pair_mappings_id_seq OWNED BY public.unified_pair_mappings.id;


--
-- Name: xt_perpetual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.xt_perpetual (
    id integer NOT NULL,
    api_id text,
    basecoin text,
    basecoindisplayprecision text,
    basecoinprecision text,
    cndesc text,
    cnname text,
    cnremark text,
    contractsize text,
    contracttype text,
    curmaxleverage text,
    deliverycompletion text,
    deliverydate text,
    deliveryprice text,
    depthprecisionmerge text,
    displayswitch text,
    endesc text,
    enname text,
    enremark text,
    fasttrackcallbackrate1 text,
    fasttrackcallbackrate2 text,
    initleverage text,
    initpositiontype text,
    isdisplay text,
    isopenapi text,
    labels text,
    latestpricedeviation text,
    liquidationfee text,
    makerfee text,
    marketclosetakebound text,
    marketopentakebound text,
    markettakebound text,
    maxentrusts text,
    maxnotional text,
    maxopenorders text,
    maxprice text,
    maxtrackcallbackrate text,
    minnotional text,
    minprice text,
    minqty text,
    minstepprice text,
    mintrackcallbackrate text,
    multiplierdown text,
    multiplierup text,
    nextopentime text,
    offtime text,
    onboarddate text,
    openswitch text,
    pair text,
    plates text,
    predicteventparam text,
    predicteventsort text,
    predicteventtype text,
    priceprecision text,
    producttype text,
    quantityprecision text,
    quotecoin text,
    quotecoindisplayprecision text,
    quotecoinprecision text,
    riskexpiretime text,
    risknominalvaluecoefficient text,
    spotcoin text,
    state text,
    supportentrusttype text,
    supportordertype text,
    supportpositiontype text,
    supporttimeinforce text,
    symbol text NOT NULL,
    symbolgroupid text,
    symbolid text,
    takerfee text,
    thanosswitch text,
    tradeswitch text,
    underlyingtype text,
    updatedtime text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: xt_perpetual_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.xt_perpetual_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: xt_perpetual_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.xt_perpetual_id_seq OWNED BY public.xt_perpetual.id;


--
-- Name: binance_perpetual id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.binance_perpetual ALTER COLUMN id SET DEFAULT nextval('public.binance_perpetual_id_seq'::regclass);


--
-- Name: bybit_perpetual id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bybit_perpetual ALTER COLUMN id SET DEFAULT nextval('public.bybit_perpetual_id_seq'::regclass);


--
-- Name: fuzzy_pair_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuzzy_pair_mappings ALTER COLUMN id SET DEFAULT nextval('public.fuzzy_pair_mappings_id_seq'::regclass);


--
-- Name: gate_perpetual id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gate_perpetual ALTER COLUMN id SET DEFAULT nextval('public.gate_perpetual_id_seq'::regclass);


--
-- Name: kucoin_perpetual id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kucoin_perpetual ALTER COLUMN id SET DEFAULT nextval('public.kucoin_perpetual_id_seq'::regclass);


--
-- Name: mexc_perpetual id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mexc_perpetual ALTER COLUMN id SET DEFAULT nextval('public.mexc_perpetual_id_seq'::regclass);


--
-- Name: okx_perpetual id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.okx_perpetual ALTER COLUMN id SET DEFAULT nextval('public.okx_perpetual_id_seq'::regclass);


--
-- Name: pair_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pair_mappings ALTER COLUMN id SET DEFAULT nextval('public.pair_mappings_id_seq'::regclass);


--
-- Name: unified_pair_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unified_pair_mappings ALTER COLUMN id SET DEFAULT nextval('public.unified_pair_mappings_id_seq'::regclass);


--
-- Name: xt_perpetual id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xt_perpetual ALTER COLUMN id SET DEFAULT nextval('public.xt_perpetual_id_seq'::regclass);


--
-- Name: binance_perpetual binance_perpetual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.binance_perpetual
    ADD CONSTRAINT binance_perpetual_pkey PRIMARY KEY (id);


--
-- Name: binance_perpetual binance_perpetual_symbol_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.binance_perpetual
    ADD CONSTRAINT binance_perpetual_symbol_key UNIQUE (symbol);


--
-- Name: bybit_perpetual bybit_perpetual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bybit_perpetual
    ADD CONSTRAINT bybit_perpetual_pkey PRIMARY KEY (id);


--
-- Name: bybit_perpetual bybit_perpetual_symbol_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bybit_perpetual
    ADD CONSTRAINT bybit_perpetual_symbol_key UNIQUE (symbol);


--
-- Name: fuzzy_pair_mappings fuzzy_pair_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuzzy_pair_mappings
    ADD CONSTRAINT fuzzy_pair_mappings_pkey PRIMARY KEY (id);


--
-- Name: fuzzy_pair_mappings fuzzy_pair_mappings_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuzzy_pair_mappings
    ADD CONSTRAINT fuzzy_pair_mappings_unique UNIQUE (xt_symbol, exchange);


--
-- Name: gate_perpetual gate_perpetual_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gate_perpetual
    ADD CONSTRAINT gate_perpetual_name_key UNIQUE (name);


--
-- Name: gate_perpetual gate_perpetual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gate_perpetual
    ADD CONSTRAINT gate_perpetual_pkey PRIMARY KEY (id);


--
-- Name: kucoin_perpetual kucoin_perpetual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kucoin_perpetual
    ADD CONSTRAINT kucoin_perpetual_pkey PRIMARY KEY (id);


--
-- Name: kucoin_perpetual kucoin_perpetual_symbol_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kucoin_perpetual
    ADD CONSTRAINT kucoin_perpetual_symbol_key UNIQUE (symbol);


--
-- Name: mexc_perpetual mexc_perpetual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mexc_perpetual
    ADD CONSTRAINT mexc_perpetual_pkey PRIMARY KEY (id);


--
-- Name: mexc_perpetual mexc_perpetual_symbol_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mexc_perpetual
    ADD CONSTRAINT mexc_perpetual_symbol_key UNIQUE (symbol);


--
-- Name: okx_perpetual okx_perpetual_instid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.okx_perpetual
    ADD CONSTRAINT okx_perpetual_instid_key UNIQUE (instid);


--
-- Name: okx_perpetual okx_perpetual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.okx_perpetual
    ADD CONSTRAINT okx_perpetual_pkey PRIMARY KEY (id);


--
-- Name: pair_mappings pair_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pair_mappings
    ADD CONSTRAINT pair_mappings_pkey PRIMARY KEY (id);


--
-- Name: pair_mappings pair_mappings_xt_symbol_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pair_mappings
    ADD CONSTRAINT pair_mappings_xt_symbol_key UNIQUE (xt_symbol);


--
-- Name: unified_pair_mappings unified_mappings_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unified_pair_mappings
    ADD CONSTRAINT unified_mappings_unique UNIQUE (xt_symbol, exchange);


--
-- Name: unified_pair_mappings unified_pair_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unified_pair_mappings
    ADD CONSTRAINT unified_pair_mappings_pkey PRIMARY KEY (id);


--
-- Name: xt_perpetual xt_perpetual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xt_perpetual
    ADD CONSTRAINT xt_perpetual_pkey PRIMARY KEY (id);


--
-- Name: xt_perpetual xt_perpetual_symbol_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xt_perpetual
    ADD CONSTRAINT xt_perpetual_symbol_key UNIQUE (symbol);


--
-- Name: idx_binance_perpetual_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_binance_perpetual_symbol ON public.binance_perpetual USING btree (symbol);


--
-- Name: idx_bybit_perpetual_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bybit_perpetual_symbol ON public.bybit_perpetual USING btree (symbol);


--
-- Name: idx_fuzzy_exchange; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fuzzy_exchange ON public.fuzzy_pair_mappings USING btree (exchange);


--
-- Name: idx_fuzzy_price_diff; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fuzzy_price_diff ON public.fuzzy_pair_mappings USING btree (price_diff);


--
-- Name: idx_fuzzy_similarity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fuzzy_similarity ON public.fuzzy_pair_mappings USING btree (string_similarity);


--
-- Name: idx_fuzzy_xt_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fuzzy_xt_symbol ON public.fuzzy_pair_mappings USING btree (xt_symbol);


--
-- Name: idx_gate_perpetual_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gate_perpetual_name ON public.gate_perpetual USING btree (name);


--
-- Name: idx_kucoin_perpetual_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kucoin_perpetual_symbol ON public.kucoin_perpetual USING btree (symbol);


--
-- Name: idx_mexc_perpetual_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mexc_perpetual_symbol ON public.mexc_perpetual USING btree (symbol);


--
-- Name: idx_okx_perpetual_instid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_okx_perpetual_instid ON public.okx_perpetual USING btree (instid);


--
-- Name: idx_pair_mappings_base_quote; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pair_mappings_base_quote ON public.pair_mappings USING btree (normalized_base, normalized_quote);


--
-- Name: idx_pair_mappings_binance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pair_mappings_binance ON public.pair_mappings USING btree (binance_symbol) WHERE (binance_symbol IS NOT NULL);


--
-- Name: idx_pair_mappings_bybit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pair_mappings_bybit ON public.pair_mappings USING btree (bybit_symbol) WHERE (bybit_symbol IS NOT NULL);


--
-- Name: idx_pair_mappings_normalized; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pair_mappings_normalized ON public.pair_mappings USING btree (normalized_pair);


--
-- Name: idx_pair_mappings_okx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pair_mappings_okx ON public.pair_mappings USING btree (okx_symbol) WHERE (okx_symbol IS NOT NULL);


--
-- Name: idx_pair_mappings_xt_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pair_mappings_xt_symbol ON public.pair_mappings USING btree (xt_symbol);


--
-- Name: idx_unified_exchange; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_unified_exchange ON public.unified_pair_mappings USING btree (exchange);


--
-- Name: idx_unified_exchange_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_unified_exchange_symbol ON public.unified_pair_mappings USING btree (exchange, exchange_symbol);


--
-- Name: idx_unified_match_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_unified_match_type ON public.unified_pair_mappings USING btree (match_type);


--
-- Name: idx_unified_normalized; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_unified_normalized ON public.unified_pair_mappings USING btree (normalized_pair);


--
-- Name: idx_unified_price_diff; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_unified_price_diff ON public.unified_pair_mappings USING btree (price_diff);


--
-- Name: idx_unified_similarity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_unified_similarity ON public.unified_pair_mappings USING btree (string_similarity);


--
-- Name: idx_unified_xt_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_unified_xt_symbol ON public.unified_pair_mappings USING btree (xt_symbol);


--
-- Name: idx_xt_perpetual_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_xt_perpetual_symbol ON public.xt_perpetual USING btree (symbol);


--
-- PostgreSQL database dump complete
--

\unrestrict hqywNBnTM2cWxlRybeh19DEP6CwLYoyuN6HKI51rQazeSRiPDTDGSKbuuFPV7Nb

