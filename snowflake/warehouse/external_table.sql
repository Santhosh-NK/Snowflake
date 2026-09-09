SELECT SYSTEM$EXTERNAL_TABLE_PIPE_STATUS(
    'SALES_DB.SALES.EXTERNAL_ORDERS'
);

-- check automatic refresh status

-- check registered files

SELECT *
FROM TABLE(
    SALES_DB.INFORMATION_SCHEMA.EXTERNAL_TABLE_FILES(
        TABLE_NAME => 'SALES.EXTERNAL_ORDERS'
    )
);
--------------------------normal table --------------------------
CREATE EXTERNAL TABLE IF NOT EXISTS SALES_DB.SALES.EXTERNAL_ORDERS
(
    ORDER_ID       NUMBER        AS (VALUE:order_id::NUMBER),
    CUSTOMER_ID    NUMBER        AS (VALUE:customer_id::NUMBER),
    ORDER_DATE     DATE          AS (VALUE:order_date::DATE),
    ORDER_AMOUNT   NUMBER(12,2)  AS (VALUE:order_amount::NUMBER(12,2)),
    ORDER_STATUS   VARCHAR(20)   AS (VALUE:order_status::VARCHAR)
)
WITH LOCATION = @SALES_DB.SALES.AZURE_ORDERS_STAGE
FILE_FORMAT = (
    TYPE = PARQUET
)
PATTERN = '.*[.]parquet'
REFRESH_ON_CREATE = TRUE
AUTO_REFRESH = TRUE
COMMENT = 'External table for order data stored in Azure';

----------------------------------partitioned table------------------------------

CREATE EXTERNAL TABLE IF NOT EXISTS SALES_DB.SALES.EXTERNAL_ORDERS
(
    ORDER_ID       NUMBER AS (VALUE:order_id::NUMBER),
    ORDER_AMOUNT   NUMBER(12,2) AS (VALUE:order_amount::NUMBER(12,2)),

    ORDER_YEAR     NUMBER AS (
        SPLIT_PART(METADATA$FILENAME, '/', 1)::NUMBER
    ),

    ORDER_MONTH    NUMBER AS (
        SPLIT_PART(METADATA$FILENAME, '/', 2)::NUMBER
    )
)
PARTITION BY (ORDER_YEAR, ORDER_MONTH)
WITH LOCATION = @SALES_DB.SALES.AZURE_ORDERS_STAGE
FILE_FORMAT = (
    TYPE = PARQUET
)
REFRESH_ON_CREATE = TRUE
AUTO_REFRESH = TRUE
COMMENT = 'Partitioned external orders table';

-----------------------------------------------------------------------------