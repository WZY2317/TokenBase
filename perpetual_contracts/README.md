# 永续合约数据采集系统

模块化、工程化的交易所永续合约数据采集系统，使用JSONB格式存储API原始数据。

## 项目结构

```
perpetual_contracts/
├── config.py                 # 配置文件
├── main_jsonb.py            # 主程序入口（JSONB存储）
├── main.py                  # 主程序入口（字段展开存储 - 实验性）
├── README.md                # 本文件
├── requirements.txt         # Python依赖
├── QUERY_EXAMPLES.md        # SQL查询示例
├── exchanges/               # 交易所API模块
│   ├── __init__.py
│   ├── base.py             # API基类
│   ├── binance.py          # Binance API
│   ├── xt.py               # XT API
│   ├── okx.py              # OKX API
│   ├── bybit.py            # Bybit API
│   ├── gate.py             # Gate.io API
│   ├── kucoin.py           # KuCoin API
│   └── mexc.py             # MEXC API
├── database/               # 数据库模块
│   ├── __init__.py
│   ├── db_jsonb.py         # 数据库操作（JSONB模式）
│   ├── db.py               # 数据库操作（字段展开模式 - 实验性）
│   └── schemas_raw.sql     # 生成的表结构（自动生成）
└── utils/                  # 工具模块
    ├── __init__.py
    └── schema_generator.py # 自动生成表结构

## 特性

1. **模块化设计**: 每个交易所独立模块，易于维护和扩展
2. **原始数据保存**: 使用JSONB格式完整保存API返回的所有字段
3. **无类型转换问题**: JSONB存储避免了复杂的类型推断和转换
4. **强大的查询能力**: 利用PostgreSQL的JSONB查询功能，可灵活访问任意字段
5. **高性能索引**: JSONB字段支持GIN索引，查询性能优秀
6. **异步处理**: 使用asyncpg实现高效的异步数据库操作

## 使用方法

### 1. 安装依赖

```bash
cd perpetual_contracts
pip install -r requirements.txt
```

### 2. 配置数据库

编辑 `config.py` 文件，设置数据库连接参数：

```python
DB_CONFIG = {
    'user': 'your_user',
    'password': 'your_password',
    'host': '127.0.0.1',
    'port': 5432,
    'database': 'perpetual_trading'
}
```

### 3. 运行程序

```bash
python main_jsonb.py
```

程序将：
1. 从各交易所API获取永续合约数据
2. 创建简洁的JSONB存储表
3. 将所有原始API数据以JSON格式存入数据库

## 数据库表结构

每个交易所对应一张独立的表，表名格式为 `{exchange}_perpetual_raw`：

| 表名 | 主键字段 | 说明 |
|------|----------|------|
| `binance_perpetual_raw` | symbol | Binance永续合约 |
| `xt_perpetual_raw` | symbol | XT永续合约 |
| `okx_perpetual_raw` | instId | OKX永续合约 |
| `bybit_perpetual_raw` | symbol | Bybit永续合约 |
| `gate_perpetual_raw` | name | Gate.io永续合约 |
| `kucoin_perpetual_raw` | symbol | KuCoin永续合约 |
| `mexc_perpetual_raw` | symbol | MEXC永续合约 |

### 表结构示例

```sql
CREATE TABLE xt_perpetual_raw (
    id SERIAL PRIMARY KEY,
    symbol TEXT UNIQUE NOT NULL,     -- 交易对符号（主键）
    data JSONB NOT NULL,              -- 完整的API响应数据
    created_at TIMESTAMP,             -- 创建时间
    updated_at TIMESTAMP              -- 更新时间
);

CREATE INDEX idx_xt_perpetual_raw_data ON xt_perpetual_raw USING GIN(data);
```

## 查询示例

### 基本查询

```sql
-- 查询指定交易对
SELECT data FROM xt_perpetual_raw WHERE symbol = 'btc_usdt';

-- 查询特定字段
SELECT
    symbol,
    data->>'pricePrecision' as price_precision,
    data->>'makerFee' as maker_fee,
    data->>'takerFee' as taker_fee
FROM xt_perpetual_raw
WHERE symbol = 'btc_usdt';

-- 查询所有USDT交易对
SELECT symbol, data->>'baseCoin' as base_coin
FROM xt_perpetual_raw
WHERE data->>'quoteCoin' = 'usdt'
LIMIT 10;
```

### 跨交易所查询

```sql
-- 查询BTC在不同交易所的信息
SELECT
    'Binance' as exchange,
    symbol,
    data->>'pricePrecision' as price_prec
FROM binance_perpetual_raw
WHERE symbol = 'BTCUSDT'

UNION ALL

SELECT
    'XT',
    symbol,
    data->>'pricePrecision'
FROM xt_perpetual_raw
WHERE symbol = 'btc_usdt';
```

更多查询示例请参考 [QUERY_EXAMPLES.md](QUERY_EXAMPLES.md)

## 支持的交易所

- ✅ Binance (币安) - 577个合约
- ✅ XT.COM - 799个合约
- ✅ OKX (欧易) - 253个合约
- ✅ Bybit - 469个合约
- ✅ Gate.io (芝麻开门) - 592个合约
- ✅ KuCoin (库币) - 539个合约
- ✅ MEXC (抹茶) - 821个合约

## 扩展新交易所

1. 在 `exchanges/` 目录下创建新的API客户端文件
2. 继承 `BaseExchange` 类
3. 实现 `get_perpetuals()` 方法，返回原始API数据列表
4. 在 `config.py` 中添加交易所配置
5. 在 `main_jsonb.py` 中添加数据获取和插入逻辑

## 优势

### 相比字段展开存储的优势

1. **无类型冲突**: 不需要推断字段类型，避免类型转换错误
2. **灵活性强**: 不同交易所API字段差异大，JSONB可以完美适配
3. **易于维护**: 无需为每个交易所定义不同的表结构
4. **数据完整**: 100%保留API返回的所有原始数据
5. **查询灵活**: PostgreSQL的JSONB操作符非常强大，支持各种复杂查询

### PostgreSQL JSONB优势

- 支持索引（GIN索引）
- 支持丰富的操作符（->、->>、@>、?等）
- 查询性能接近普通列
- 存储效率高（二进制格式）

## 注意事项

- JSONB格式存储保留完整的API原始数据
- 可以使用PostgreSQL的JSON函数和操作符查询任意字段
- 支持GIN索引，查询性能优秀
- 数据更新时会基于主键进行UPSERT操作
- 建议定期运行以保持数据最新
