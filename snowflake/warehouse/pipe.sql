CREATE [ OR REPLACE ] PIPE [ IF NOT EXISTS ] <pipe_name>
    [ AUTO_INGEST = TRUE | FALSE ]
    [ ERROR_INTEGRATION = <error_notification_integration> ]
    [ AWS_SNS_TOPIC = '<sns_topic_arn>' ]
    [ INTEGRATION = '<notification_integration>' ]
    [ COMMENT = '<description>' ]
AS
COPY INTO <target_table>
FROM <stage>
[ FILE_FORMAT = (...) ]
[ PATTERN = '<regular_expression>' ]
[ copy_options ];



------------------------COPY INTO definition inside the pipe

-- The AS COPY INTO statement defines:

-- Target table
-- Source stage and path
-- File format
-- File selection pattern
-- Column matching
-- Error handling
-- Metadata columns
-- Optional transformations

-------------------------------complete path 

CREATE OR REPLACE PIPE SALES_DB.RAW.ORDERS_PIPE
    AUTO_INGEST = TRUE
    INTEGRATION = 'AZURE_SNOWPIPE_NOTIFICATION_INT'
    ERROR_INTEGRATION = SNOWPIPE_ERROR_INT
    COMMENT = 'Continuously loads Azure order CSV files'
AS
COPY INTO SALES_DB.RAW.ORDERS
FROM @SALES_DB.RAW.ORDERS_STAGE
PATTERN = '.*[.]csv'
FILE_FORMAT = (
    FORMAT_NAME = SALES_DB.RAW.ORDERS_CSV_FORMAT
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
INCLUDE_METADATA = (
    SOURCE_FILE      = METADATA$FILENAME,
    FILE_ROW_NUMBER  = METADATA$FILE_ROW_NUMBER,
    FILE_MODIFIED_AT = METADATA$FILE_LAST_MODIFIED,
    LOAD_STARTED_AT  = METADATA$START_SCAN_TIME
)
ON_ERROR = CONTINUE;



------------

-- Schema evolution with a pipe

-- Snowpipe can automatically evolve a target table when:

-- The table has ENABLE_SCHEMA_EVOLUTION = TRUE.
-- The pipe’s COPY INTO uses MATCH_BY_COLUMN_NAME.
-- The pipe owner role has EVOLVE SCHEMA or OWNERSHIP on the target table.
-- For CSV, PARSE_HEADER = TRUE and ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE are configured.
----------------------------------------


-- An auto-ingest pipe normally responds to new event notifications. Files already present before the notification system or pipe was configured might not have generated events for the pipe.

-- You can request Snowpipe to scan the stage path and queue unprocessed files:


ALTER PIPE SALES_DB.RAW.ORDERS_PIPE
REFRESH;

---------------------------------------------

-- Monitoring a pipe
-- View pipe definition

DESC PIPE SALES_DB.RAW.ORDERS_PIPE;

----------------------list pipes

SHOW PIPES IN SCHEMA SALES_DB.RAW;

------------------check current status ----------------------

SELECT SYSTEM$PIPE_STATUS(
    'SALES_DB.RAW.ORDERS_PIPE'
);

-----------------------------load history -----------------------

SELECT *
FROM TABLE(
    SALES_DB.INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'SALES_DB.RAW.ORDERS',
        START_TIME => DATEADD('hour', -24, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME DESC;


------------------------- complete workflow

Stage
    Stores or references the files

Storage integration
    Allows Snowflake to read external storage

Notification integration
    Delivers file-arrival events to Snowpipe

Pipe
    Stores the COPY INTO definition

AUTO_INGEST
    Automatically processes arrival events

ERROR_INTEGRATION
    Sends ingestion failure notifications

Target table
    Stores the loaded records




