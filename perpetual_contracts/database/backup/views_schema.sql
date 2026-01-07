--
-- PostgreSQL database dump
--

\restrict 5fLeNg6I6cs9DViE5pNNm1kYpv2rf0OKERqsp2HYbxCYltw9QQxO3YzoVdfRwDh

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

--
-- Name: v_raw_data; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_raw_data AS
 WITH base_mapping AS (
         SELECT DISTINCT unified_pair_mappings.xt_symbol,
            unified_pair_mappings.normalized_pair,
            unified_pair_mappings.normalized_base,
            unified_pair_mappings.normalized_quote
           FROM public.unified_pair_mappings
          WHERE (unified_pair_mappings.verified = true)
        )
 SELECT bm.xt_symbol,
    bm.normalized_pair,
    bm.normalized_base,
    bm.normalized_quote,
    to_jsonb(xt.*) AS xt_raw_data,
    ( SELECT to_jsonb(bn.*) AS to_jsonb
           FROM (public.unified_pair_mappings upm
             JOIN public.binance_perpetual bn ON (((upm.exchange = 'binance'::text) AND (upm.exchange_symbol = bn.symbol))))
          WHERE ((upm.xt_symbol = bm.xt_symbol) AND (upm.verified = true))
         LIMIT 1) AS binance_raw_data,
    ( SELECT to_jsonb(okx.*) AS to_jsonb
           FROM (public.unified_pair_mappings upm
             JOIN public.okx_perpetual okx ON (((upm.exchange = 'okx'::text) AND (upm.exchange_symbol = okx.instid))))
          WHERE ((upm.xt_symbol = bm.xt_symbol) AND (upm.verified = true))
         LIMIT 1) AS okx_raw_data,
    ( SELECT to_jsonb(bb.*) AS to_jsonb
           FROM (public.unified_pair_mappings upm
             JOIN public.bybit_perpetual bb ON (((upm.exchange = 'bybit'::text) AND (upm.exchange_symbol = bb.symbol))))
          WHERE ((upm.xt_symbol = bm.xt_symbol) AND (upm.verified = true))
         LIMIT 1) AS bybit_raw_data,
    ( SELECT to_jsonb(gt.*) AS to_jsonb
           FROM (public.unified_pair_mappings upm
             JOIN public.gate_perpetual gt ON (((upm.exchange = 'gate'::text) AND (upm.exchange_symbol = gt.name))))
          WHERE ((upm.xt_symbol = bm.xt_symbol) AND (upm.verified = true))
         LIMIT 1) AS gate_raw_data,
    ( SELECT to_jsonb(kc.*) AS to_jsonb
           FROM (public.unified_pair_mappings upm
             JOIN public.kucoin_perpetual kc ON (((upm.exchange = 'kucoin'::text) AND (upm.exchange_symbol = kc.symbol))))
          WHERE ((upm.xt_symbol = bm.xt_symbol) AND (upm.verified = true))
         LIMIT 1) AS kucoin_raw_data,
    ( SELECT to_jsonb(mx.*) AS to_jsonb
           FROM (public.unified_pair_mappings upm
             JOIN public.mexc_perpetual mx ON (((upm.exchange = 'mexc'::text) AND (upm.exchange_symbol = mx.symbol))))
          WHERE ((upm.xt_symbol = bm.xt_symbol) AND (upm.verified = true))
         LIMIT 1) AS mexc_raw_data
   FROM (base_mapping bm
     LEFT JOIN public.xt_perpetual xt ON ((bm.xt_symbol = xt.symbol)));


--
-- Name: VIEW v_raw_data; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_raw_data IS '原始数据视图 - 返回所有交易所的完整原始数据（JSONB格式），宽表格式';


--
-- Name: v_unified_trading_info; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_unified_trading_info AS
 WITH base_mapping AS (
         SELECT unified_pair_mappings.xt_symbol,
            unified_pair_mappings.normalized_pair,
            unified_pair_mappings.normalized_base,
            unified_pair_mappings.normalized_quote,
            unified_pair_mappings.xt_multiplier,
            unified_pair_mappings.exchange,
            unified_pair_mappings.exchange_symbol,
            unified_pair_mappings.exchange_multiplier,
            unified_pair_mappings.match_type,
            unified_pair_mappings.string_similarity,
            unified_pair_mappings.price_diff,
            unified_pair_mappings.verified
           FROM public.unified_pair_mappings
          WHERE (unified_pair_mappings.verified = true)
        )
 SELECT bm.xt_symbol,
    bm.normalized_pair,
    bm.normalized_base,
    bm.normalized_quote,
    bm.match_type,
    bm.string_similarity,
    bm.price_diff,
    jsonb_build_object('exchange', 'xt', 'symbol', xt.symbol, 'base_asset', xt.basecoin, 'quote_asset', xt.quotecoin, 'multiplier', bm.xt_multiplier, 'price_precision', (xt.priceprecision)::integer, 'quantity_precision', (xt.quantityprecision)::integer, 'tick_size', xt.minstepprice, 'min_price', xt.minprice, 'max_price', xt.maxprice, 'step_size', NULL::unknown, 'min_qty', xt.minqty, 'max_qty', NULL::unknown, 'max_market_qty', NULL::unknown, 'min_notional', xt.minnotional, 'max_notional', xt.maxnotional, 'contract_size', xt.contractsize, 'min_leverage', NULL::unknown, 'max_leverage', NULL::unknown) AS xt_info,
    bm.exchange AS matched_exchange,
        CASE
            WHEN (bm.exchange = 'binance'::text) THEN jsonb_build_object('exchange', 'binance', 'symbol', bn.symbol, 'base_asset', bn.baseasset, 'quote_asset', bn.quoteasset, 'multiplier', bm.exchange_multiplier, 'price_precision', (bn.priceprecision)::integer, 'quantity_precision', (bn.quantityprecision)::integer, 'tick_size', (((bn.filters_dict)::jsonb -> 'PRICE_FILTER'::text) ->> 'tickSize'::text), 'min_price', (((bn.filters_dict)::jsonb -> 'PRICE_FILTER'::text) ->> 'minPrice'::text), 'max_price', (((bn.filters_dict)::jsonb -> 'PRICE_FILTER'::text) ->> 'maxPrice'::text), 'step_size', (((bn.filters_dict)::jsonb -> 'LOT_SIZE'::text) ->> 'stepSize'::text), 'min_qty', (((bn.filters_dict)::jsonb -> 'LOT_SIZE'::text) ->> 'minQty'::text), 'max_qty', (((bn.filters_dict)::jsonb -> 'LOT_SIZE'::text) ->> 'maxQty'::text), 'max_market_qty', (((bn.filters_dict)::jsonb -> 'MARKET_LOT_SIZE'::text) ->> 'maxQty'::text), 'min_notional', (((bn.filters_dict)::jsonb -> 'MIN_NOTIONAL'::text) ->> 'notional'::text), 'max_notional', NULL::unknown, 'contract_size', NULL::unknown, 'min_leverage', NULL::unknown, 'max_leverage', NULL::unknown)
            ELSE NULL::jsonb
        END AS binance_info,
        CASE
            WHEN (bm.exchange = 'okx'::text) THEN jsonb_build_object('exchange', 'okx', 'symbol', okx.instid, 'base_asset', okx.baseccy, 'quote_asset', okx.quoteccy, 'multiplier', bm.exchange_multiplier, 'price_precision', NULL::unknown, 'quantity_precision', NULL::unknown, 'tick_size', okx.ticksz, 'min_price', NULL::unknown, 'max_price', NULL::unknown, 'step_size', okx.lotsz, 'min_qty', ((((okx.minsz)::numeric * NULLIF((okx.ctval)::numeric, (0)::numeric)) * NULLIF((okx.ctmult)::numeric, (0)::numeric)))::text, 'max_qty', ((((okx.maxlmtsz)::numeric * NULLIF((okx.ctval)::numeric, (0)::numeric)) * NULLIF((okx.ctmult)::numeric, (0)::numeric)))::text, 'max_market_qty', ((((okx.maxmktsz)::numeric * NULLIF((okx.ctval)::numeric, (0)::numeric)) * NULLIF((okx.ctmult)::numeric, (0)::numeric)))::text, 'min_notional', NULL::unknown, 'max_notional', okx.maxlmtamt, 'contract_size', okx.ctval, 'contract_multiplier', okx.ctmult, 'min_leverage', '1', 'max_leverage', okx.lever)
            ELSE NULL::jsonb
        END AS okx_info,
        CASE
            WHEN (bm.exchange = 'bybit'::text) THEN jsonb_build_object('exchange', 'bybit', 'symbol', bb.symbol, 'base_asset', bb.basecoin, 'quote_asset', bb.quotecoin, 'multiplier', bm.exchange_multiplier, 'price_precision', (bb.pricescale)::integer, 'quantity_precision', NULL::unknown, 'tick_size', ((bb.pricefilter)::jsonb ->> 'tickSize'::text), 'min_price', ((bb.pricefilter)::jsonb ->> 'minPrice'::text), 'max_price', ((bb.pricefilter)::jsonb ->> 'maxPrice'::text), 'step_size', ((bb.lotsizefilter)::jsonb ->> 'qtyStep'::text), 'min_qty', ((bb.lotsizefilter)::jsonb ->> 'minOrderQty'::text), 'max_qty', ((bb.lotsizefilter)::jsonb ->> 'maxOrderQty'::text), 'max_market_qty', ((bb.lotsizefilter)::jsonb ->> 'maxMktOrderQty'::text), 'min_notional', ((bb.lotsizefilter)::jsonb ->> 'minNotionalValue'::text), 'max_notional', NULL::unknown, 'contract_size', NULL::unknown, 'min_leverage', ((bb.leveragefilter)::jsonb ->> 'minLeverage'::text), 'max_leverage', ((bb.leveragefilter)::jsonb ->> 'maxLeverage'::text))
            ELSE NULL::jsonb
        END AS bybit_info,
        CASE
            WHEN (bm.exchange = 'gate'::text) THEN jsonb_build_object('exchange', 'gate', 'symbol', gt.name, 'base_asset', split_part(gt.name, '_'::text, 1), 'quote_asset', split_part(gt.name, '_'::text, 2), 'multiplier', bm.exchange_multiplier, 'price_precision', NULL::unknown, 'quantity_precision', NULL::unknown, 'tick_size', gt.order_price_round, 'min_price', NULL::unknown, 'max_price', NULL::unknown, 'step_size', NULL::unknown, 'min_qty', (((gt.order_size_min)::numeric * NULLIF((gt.quanto_multiplier)::numeric, (0)::numeric)))::text, 'max_qty', (((gt.order_size_max)::numeric * NULLIF((gt.quanto_multiplier)::numeric, (0)::numeric)))::text, 'max_market_qty', (((gt.market_order_size_max)::numeric * NULLIF((gt.quanto_multiplier)::numeric, (0)::numeric)))::text, 'min_notional', NULL::unknown, 'max_notional', NULL::unknown, 'contract_size', gt.quanto_multiplier, 'min_leverage', gt.leverage_min, 'max_leverage', gt.leverage_max)
            ELSE NULL::jsonb
        END AS gate_info,
        CASE
            WHEN (bm.exchange = 'kucoin'::text) THEN jsonb_build_object('exchange', 'kucoin', 'symbol', kc.symbol, 'base_asset', kc.basecurrency, 'quote_asset', kc.quotecurrency, 'multiplier', bm.exchange_multiplier, 'price_precision', NULL::unknown, 'quantity_precision', NULL::unknown, 'tick_size', kc.ticksize, 'min_price', NULL::unknown, 'max_price', kc.maxprice, 'step_size', kc.lotsize, 'min_qty', NULL::unknown, 'max_qty', kc.maxorderqty, 'max_market_qty', kc.marketmaxorderqty, 'min_notional', NULL::unknown, 'max_notional', NULL::unknown, 'contract_size', kc.multiplier, 'min_leverage', '1', 'max_leverage', kc.maxleverage)
            ELSE NULL::jsonb
        END AS kucoin_info,
        CASE
            WHEN (bm.exchange = 'mexc'::text) THEN jsonb_build_object('exchange', 'mexc', 'symbol', mx.symbol, 'base_asset', mx.basecoin, 'quote_asset', mx.quotecoin, 'multiplier', bm.exchange_multiplier, 'price_precision', (mx.pricescale)::integer, 'quantity_precision', (mx.volscale)::integer, 'tick_size', mx.priceunit, 'min_price', NULL::unknown, 'max_price', NULL::unknown, 'step_size', mx.volunit, 'min_qty', (((mx.minvol)::numeric * NULLIF((mx.contractsize)::numeric, (0)::numeric)))::text, 'max_qty', (((mx.maxvol)::numeric * NULLIF((mx.contractsize)::numeric, (0)::numeric)))::text, 'max_market_qty', (((mx.limitmaxvol)::numeric * NULLIF((mx.contractsize)::numeric, (0)::numeric)))::text, 'min_notional', NULL::unknown, 'max_notional', NULL::unknown, 'contract_size', mx.contractsize, 'min_leverage', mx.minleverage, 'max_leverage', mx.maxleverage)
            ELSE NULL::jsonb
        END AS mexc_info
   FROM (((((((base_mapping bm
     LEFT JOIN public.xt_perpetual xt ON ((bm.xt_symbol = xt.symbol)))
     LEFT JOIN public.binance_perpetual bn ON (((bm.exchange = 'binance'::text) AND (bm.exchange_symbol = bn.symbol))))
     LEFT JOIN public.okx_perpetual okx ON (((bm.exchange = 'okx'::text) AND (bm.exchange_symbol = okx.instid))))
     LEFT JOIN public.bybit_perpetual bb ON (((bm.exchange = 'bybit'::text) AND (bm.exchange_symbol = bb.symbol))))
     LEFT JOIN public.gate_perpetual gt ON (((bm.exchange = 'gate'::text) AND (bm.exchange_symbol = gt.name))))
     LEFT JOIN public.kucoin_perpetual kc ON (((bm.exchange = 'kucoin'::text) AND (bm.exchange_symbol = kc.symbol))))
     LEFT JOIN public.mexc_perpetual mx ON (((bm.exchange = 'mexc'::text) AND (bm.exchange_symbol = mx.symbol))));


--
-- Name: VIEW v_unified_trading_info; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_unified_trading_info IS '统一交易信息视图 - 包含精确匹配和模糊匹配的所有交易对信息';


--
-- Name: v_unified_trading_info_wide; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_unified_trading_info_wide AS
 WITH xt_mappings AS (
         SELECT DISTINCT unified_pair_mappings.xt_symbol,
            unified_pair_mappings.normalized_pair,
            unified_pair_mappings.normalized_base,
            unified_pair_mappings.normalized_quote,
            unified_pair_mappings.xt_multiplier
           FROM public.unified_pair_mappings
          WHERE (unified_pair_mappings.verified = true)
        )
 SELECT xm.xt_symbol,
    xm.normalized_pair,
    xm.normalized_base,
    xm.normalized_quote,
    jsonb_build_object('exchange', 'xt', 'symbol', xt.symbol, 'base_asset', xt.basecoin, 'quote_asset', xt.quotecoin, 'multiplier', xm.xt_multiplier, 'price_precision', (xt.priceprecision)::integer, 'quantity_precision', (xt.quantityprecision)::integer, 'tick_size', xt.minstepprice, 'min_price', xt.minprice, 'max_price', xt.maxprice, 'min_qty', xt.minqty, 'min_notional', xt.minnotional, 'max_notional', xt.maxnotional, 'contract_size', xt.contractsize) AS xt_info,
    ( SELECT jsonb_build_object('exchange', 'binance', 'symbol', bn.symbol, 'match_type', upm.match_type, 'similarity', upm.string_similarity, 'multiplier', upm.exchange_multiplier, 'tick_size', (((bn.filters_dict)::jsonb -> 'PRICE_FILTER'::text) ->> 'tickSize'::text), 'min_qty', (((bn.filters_dict)::jsonb -> 'LOT_SIZE'::text) ->> 'minQty'::text), 'min_notional', (((bn.filters_dict)::jsonb -> 'MIN_NOTIONAL'::text) ->> 'notional'::text)) AS jsonb_build_object
           FROM (public.unified_pair_mappings upm
             JOIN public.binance_perpetual bn ON ((upm.exchange_symbol = bn.symbol)))
          WHERE ((upm.xt_symbol = xm.xt_symbol) AND (upm.exchange = 'binance'::text) AND (upm.verified = true))
         LIMIT 1) AS binance_info,
    ( SELECT jsonb_build_object('exchange', 'okx', 'symbol', okx.instid, 'match_type', upm.match_type, 'similarity', upm.string_similarity, 'multiplier', upm.exchange_multiplier, 'tick_size', okx.ticksz, 'min_qty', ((((okx.minsz)::numeric * NULLIF((okx.ctval)::numeric, (0)::numeric)) * NULLIF((okx.ctmult)::numeric, (0)::numeric)))::text, 'contract_size', okx.ctval, 'contract_multiplier', okx.ctmult) AS jsonb_build_object
           FROM (public.unified_pair_mappings upm
             JOIN public.okx_perpetual okx ON ((upm.exchange_symbol = okx.instid)))
          WHERE ((upm.xt_symbol = xm.xt_symbol) AND (upm.exchange = 'okx'::text) AND (upm.verified = true))
         LIMIT 1) AS okx_info,
    ( SELECT jsonb_build_object('exchange', 'bybit', 'symbol', bb.symbol, 'match_type', upm.match_type, 'similarity', upm.string_similarity, 'multiplier', upm.exchange_multiplier, 'tick_size', ((bb.pricefilter)::jsonb ->> 'tickSize'::text), 'min_qty', ((bb.lotsizefilter)::jsonb ->> 'minOrderQty'::text), 'min_notional', ((bb.lotsizefilter)::jsonb ->> 'minNotionalValue'::text)) AS jsonb_build_object
           FROM (public.unified_pair_mappings upm
             JOIN public.bybit_perpetual bb ON ((upm.exchange_symbol = bb.symbol)))
          WHERE ((upm.xt_symbol = xm.xt_symbol) AND (upm.exchange = 'bybit'::text) AND (upm.verified = true))
         LIMIT 1) AS bybit_info,
    ( SELECT jsonb_build_object('exchange', 'gate', 'symbol', gt.name, 'match_type', upm.match_type, 'similarity', upm.string_similarity, 'multiplier', upm.exchange_multiplier, 'tick_size', gt.order_price_round, 'min_qty', (((gt.order_size_min)::numeric * NULLIF((gt.quanto_multiplier)::numeric, (0)::numeric)))::text, 'contract_size', gt.quanto_multiplier) AS jsonb_build_object
           FROM (public.unified_pair_mappings upm
             JOIN public.gate_perpetual gt ON ((upm.exchange_symbol = gt.name)))
          WHERE ((upm.xt_symbol = xm.xt_symbol) AND (upm.exchange = 'gate'::text) AND (upm.verified = true))
         LIMIT 1) AS gate_info,
    ( SELECT jsonb_build_object('exchange', 'kucoin', 'symbol', kc.symbol, 'match_type', upm.match_type, 'similarity', upm.string_similarity, 'multiplier', upm.exchange_multiplier, 'tick_size', kc.ticksize, 'max_qty', kc.maxorderqty, 'contract_size', kc.multiplier) AS jsonb_build_object
           FROM (public.unified_pair_mappings upm
             JOIN public.kucoin_perpetual kc ON ((upm.exchange_symbol = kc.symbol)))
          WHERE ((upm.xt_symbol = xm.xt_symbol) AND (upm.exchange = 'kucoin'::text) AND (upm.verified = true))
         LIMIT 1) AS kucoin_info,
    ( SELECT jsonb_build_object('exchange', 'mexc', 'symbol', mx.symbol, 'match_type', upm.match_type, 'similarity', upm.string_similarity, 'multiplier', upm.exchange_multiplier, 'tick_size', mx.priceunit, 'min_qty', (((mx.minvol)::numeric * NULLIF((mx.contractsize)::numeric, (0)::numeric)))::text, 'contract_size', mx.contractsize) AS jsonb_build_object
           FROM (public.unified_pair_mappings upm
             JOIN public.mexc_perpetual mx ON ((upm.exchange_symbol = mx.symbol)))
          WHERE ((upm.xt_symbol = xm.xt_symbol) AND (upm.exchange = 'mexc'::text) AND (upm.verified = true))
         LIMIT 1) AS mexc_info
   FROM (xt_mappings xm
     LEFT JOIN public.xt_perpetual xt ON ((xm.xt_symbol = xt.symbol)));


--
-- Name: VIEW v_unified_trading_info_wide; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_unified_trading_info_wide IS '统一交易信息宽表视图 - 一行展示一个XT交易对在所有交易所的信息';


--
-- PostgreSQL database dump complete
--

\unrestrict 5fLeNg6I6cs9DViE5pNNm1kYpv2rf0OKERqsp2HYbxCYltw9QQxO3YzoVdfRwDh

