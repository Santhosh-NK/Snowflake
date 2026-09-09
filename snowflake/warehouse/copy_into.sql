----------------------Basic Syntax----------------------------
COPY INTO SALES_DB.RAW.ORDERS
FROM @SALES_DB.RAW.ORDERS_STAGE
FILE_FORMAT = (
    FORMAT_NAME = SALES_DB.RAW.PARQUET_FORMAT
)
ON_ERROR = ABORT_STATEMENT;
------------------------------------------------------------

-------------in the stage, you know the file name then use 


FILES = (
    'orders_20260901.parquet',
    'orders_20260902.parquet'
)

----------------or use the pattern---------------------

COPY INTO ORDERS
FROM @ORDERS_STAGE
PATTERN = '.*2026/09/.*[.]parquet';

-----------------------

MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE/CASE_SENSITIVE/NONE

FORCE = FALSE -- To insert the already loaded file

-------------error handling with on_error

ON_ERROR = ABORT_STATEMENT / CONTINUE / SKIP_FILES / SKIP_FILES_N / SKIP_FILES_N%

-------------------------This is useful before a production load because it identifies parsing, conversion, and column-related errors without inserting records.

VALIDATION_MODE = RETURN_N_ERRORS / RETURN_ERRORS / RETURN_ALL_ERRORS

-----------------STRING LENGTH --------------------------

ENFORCE_LENGTH = TRUE/FALSE -- It will fail if the string exceeds the length if it is false then it will truncate the string
TRUNCATE_COLUMNS = TRUE/FALSE 

-----------------delete the files once loaded into the table

PURGE = TRUE/FALSE

------------------Limit the data load per copy into operation

SIZE_LIMIT = in_bytes

------------------------Include the metadate into the table using 

-- Useful metadata includes:

-- File name
-- File row number
-- File content key
-- File last-modified timestamp
-- Scan start time


INCLUDE_MEDATA =(
SOURCE_FILE = METADATA$FILENAME,
FILE_MODIFIED_AT = METADATA$FILE_LAST_MODIFIED
)


COPY INTO ORDERS
FROM @ORDERS_STAGE
FILE_FORMAT = (TYPE = PARQUET)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
INCLUDE_METADATA = (
    SOURCE_FILE = METADATA$FILENAME,
    FILE_MODIFIED_AT = METADATA$FILE_LAST_MODIFIED
);

---- Transform data during data load ----------------

COPY INTO ORDERS
(
    ORDER_ID,
    CUSTOMER_NAME,
    ORDER_DATE,
    ORDER_AMOUNT,
    SOURCE_FILE
)
FROM (
    SELECT
        $1::NUMBER,
        UPPER($2::VARCHAR),
        TO_DATE($3::VARCHAR, 'YYYY-MM-DD'),
        $4::NUMBER(12,2),
        METADATA$FILENAME
    FROM @ORDERS_STAGE
)
FILE_FORMAT = (
    TYPE = CSV
    SKIP_HEADER = 1
);

----------------------------------------


--------------CSV file format needed -----------------------

CREATE OR REPLACE FILE FORMAT SALES_DB.RAW.ORDERS_CSV_FORMAT
    TYPE = CSV
    PARSE_HEADER = TRUE  -- should be true for schema evolution
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'AUTO'
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE  -- should be false for schema evolution
    REPLACE_INVALID_CHARACTERS = FALSE
    COMPRESSION = AUTO;


-- To apply schema evolution automatically, table should have 

GRANT EVOLVE SCHEMA
ON TABLE SALES_DB.RAW.ORDERS
TO ROLE DATA_LOADER_ROLE;

--------------------------------