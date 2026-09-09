CREATE TABLE IF NOT EXISTS SALES_DB.SALES.ORDERS -- temporary table and transcient follows the same syntax
(
    ORDER_ID       NUMBER
        AUTOINCREMENT START 1 INCREMENT 1
        CONSTRAINT PK_ORDERS PRIMARY KEY,

    CUSTOMER_ID    NUMBER NOT NULL,

    ORDER_DATE     DATE NOT NULL
        DEFAULT CURRENT_DATE(),

    ORDER_STATUS   VARCHAR(20) NOT NULL
        DEFAULT 'PENDING',

    ORDER_AMOUNT   NUMBER(12,2) NOT NULL,

    CREATED_AT     TIMESTAMP_NTZ
        DEFAULT CURRENT_TIMESTAMP(),

    UPDATED_AT     TIMESTAMP_NTZ,

    CONSTRAINT FK_ORDERS_CUSTOMER
        FOREIGN KEY (CUSTOMER_ID)
        REFERENCES SALES_DB.SALES.CUSTOMERS(CUSTOMER_ID)
)
CLUSTER BY (ORDER_DATE)
ENABLE_SCHEMA_EVOLUTION = TRUE
DATA_RETENTION_TIME_IN_DAYS = 7
MAX_DATA_EXTENSION_TIME_IN_DAYS = 14
CHANGE_TRACKING = TRUE
DEFAULT_DDL_COLLATION = 'en-ci'
COMMENT = 'Stores production customer orders';


-------------------- schema evolution-------------------the loading role must have evolve schema permission or ownership on the table
COPY INTO CUSTOMER_DATA
FROM @CUSTOMER_STAGE
FILE_FORMAT = (FORMAT_NAME = CUSTOMER_PARQUET_FORMAT)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;  -- important for schema evolution
--------------------

-- Column-level options

-- Data type: Defines the type of data stored in the column, such as NUMBER, VARCHAR, DATE, TIMESTAMP, or BOOLEAN.
-- NOT NULL: Prevents the column from containing a null value.
-- DEFAULT: Supplies a default value when the column is omitted during insertion.
-- AUTOINCREMENT /IDENTITY: Automatically generates sequential numeric values.
-- PRIMARY KEY: Declares columns that uniquely identify records.
-- FOREIGN KEY: Declares a relationship with columns in another table.
-- UNIQUE: Declares that column values should be unique.
-- COLLATE: Defines string comparison rules for an individual column.
-- COMMENT: Adds documentation to an individual column.


-- Table-level options

-- OR REPLACE: Replaces an existing table with the same name.
-- IF NOT EXISTS: Creates the table only if it does not already exist. It cannot be combined with OR REPLACE.
-- TEMPORARY: Creates a session-specific table that is automatically removed when the session ends.
-- TRANSIENT: Creates a table without Fail-safe, normally used for staging and reproducible data.
-- CLUSTER BY: Defines clustering expressions to improve micro-partition pruning for large tables.
-- ENABLE_SCHEMA_EVOLUTION: Allows supported schema changes during data loading, such as adding new columns.
-- DATA_RETENTION_TIME_IN_DAYS: Defines the normal Time Travel retention period.
-- MAX_DATA_EXTENSION_TIME_IN_DAYS: Defines how long Snowflake can extend retention to prevent streams from becoming stale.
-- CHANGE_TRACKING: Stores change-tracking metadata required by features such as streams.
-- DEFAULT_DDL_COLLATION: Sets the default string collation for the table.
-- COPY GRANTS: Preserves existing privileges when replacing or cloning a table.
-- COMMENT: Documents the purpose of the table.


-- Other ways to create a table

-- CREATE TABLE AS SELECT, creates and populates a table from a query.
-- CREATE TABLE LIKE, copies only the structure of another table.
-- CREATE TABLE CLONE, creates a zero-copy clone.
-- CREATE TABLE USING TEMPLATE, derives column definitions from staged files

