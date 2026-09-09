-- Source files
--      ↓
--    Stage
--      ↓
-- COPY INTO table
--      ↓
-- Snowflake table


-- four types of stage
-- 1. user stage
-- 2. table stage
-- 3. Internal named stage
-- 4. external stage

-- 1. user stage

-- refrenced by @~
-- PUT file:///data/orders.csv @~;


COPY INTO SALES_DB.RAW.ORDERS
FROM @~
FILE_FORMAT = (TYPE = CSV);


-- 2. Table STAGE

-- @%orders 

-- PUT file:///data/orders.csv @%ORDERS;

COPY INTO ORDERS
FROM @%ORDERS
FILE_FORMAT = (TYPE = CSV);

-- Internal named stage

CREATE STAGE SALES_DB.RAW.ORDERS_STAGE
    FILE_FORMAT = (
        TYPE = CSV
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    )
    COMMENT = 'Internal stage for order files';


-- External stage

CREATE STAGE SALES_DB.RAW.AZURE_ORDERS_STAGE
    URL = 'azure://account.blob.core.windows.net/container/orders/'
    STORAGE_INTEGRATION = AZURE_STORAGE_INT
    FILE_FORMAT = (
        TYPE = PARQUET
    )
    COMMENT = 'External stage for Azure order files';

-- common stage operations

LIST @SALES_DB.RAW.ORDERS_STAGE;

SELECT
    $1 AS ORDER_ID,
    $2 AS CUSTOMER_ID,
    $3 AS ORDER_AMOUNT
FROM @SALES_DB.RAW.ORDERS_STAGE
(FILE_FORMAT => 'SALES_DB.RAW.CSV_FORMAT');

-- view stage definition

DESC STAGE SALES_DB.RAW.ORDERS_STAGE;

--  remove files from internal stage 

REMOVE @SALES_DB.RAW.ORDERS_STAGE
PATTERN = '.*[.]csv';

-- drop a named stage 

REMOVE @SALES_DB.RAW.ORDERS_STAGE
PATTERN = '.*[.]csv';