-- ============================================================================
-- 永续合约数据库 - 原始字段展开存储
-- 新建独立数据库
-- ============================================================================

DROP DATABASE IF EXISTS perpetual_contracts_raw;
CREATE DATABASE perpetual_contracts_raw;

\c perpetual_contracts_raw

-- 说明：表结构将由Python程序根据API返回的字段自动生成
