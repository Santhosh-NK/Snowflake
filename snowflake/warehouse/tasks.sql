-- Source table changes
--         ↓
-- Stream captures changes
--         ↓
-- Task detects stream data
--         ↓
-- Task runs MERGE
--         ↓
-- Target table updated

-------------------- schedule ------------------------------

CREATE OR REPLACE TASK SALES_DB.ETL.LOAD_ORDERS_TASK
    WAREHOUSE = ETL_WH
    SCHEDULE = '5 MINUTES'
AS
INSERT INTO SALES_DB.ETL.ORDER_SUMMARY
SELECT
    ORDER_DATE,
    SUM(ORDER_AMOUNT)
FROM SALES_DB.RAW.ORDERS
GROUP BY ORDER_DATE;

---------------------cron job ------------------------------

CREATE OR REPLACE TASK SALES_DB.ETL.DAILY_SALES_TASK
    WAREHOUSE = ETL_WH
    SCHEDULE = 'USING CRON 0 2 * * * Asia/Kolkata'
AS
CALL SALES_DB.ETL.PROCESS_DAILY_SALES();

minute hour day-of-month month day-of-week timezone
---------------------- trigger task using a stream -----------

CREATE OR REPLACE TASK SALES_DB.ETL.PROCESS_ORDERS_TASK
    WAREHOUSE = ETL_WH
    WHEN SYSTEM$STREAM_HAS_DATA(
        'SALES_DB.RAW.ORDERS_STREAM'
    )
AS
MERGE INTO SALES_DB.CURATED.ORDERS T
USING SALES_DB.RAW.ORDERS_STREAM S
    ON T.ORDER_ID = S.ORDER_ID

WHEN MATCHED
     AND S.METADATA$ACTION = 'DELETE'
     AND S.METADATA$ISUPDATE = FALSE
THEN DELETE

WHEN MATCHED
     AND S.METADATA$ACTION = 'INSERT'
THEN UPDATE SET
    T.ORDER_STATUS = S.ORDER_STATUS,
    T.ORDER_AMOUNT = S.ORDER_AMOUNT,
    T.UPDATED_AT = CURRENT_TIMESTAMP()

WHEN NOT MATCHED
     AND S.METADATA$ACTION = 'INSERT'
THEN INSERT
(
    ORDER_ID,
    CUSTOMER_ID,
    ORDER_STATUS,
    ORDER_AMOUNT,
    CREATED_AT
)
VALUES
(
    S.ORDER_ID,
    S.CUSTOMER_ID,
    S.ORDER_STATUS,
    S.ORDER_AMOUNT,
    CURRENT_TIMESTAMP()
);


-----------------------serverless task ---------------------------

CREATE OR REPLACE TASK PROCESS_ORDERS_TASK
    SCHEDULE = '5 MINUTES'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
CALL PROCESS_ORDERS();

--------------------------------------------------------------

-- Task graph

-- A task graph is a dependency-based workflow consisting of:

-- One root task
-- One or more child tasks
-- An optional finalizer task

--------------------------Root task defines the schedule-----------------------------------

CREATE OR REPLACE TASK ROOT_TASK
    WAREHOUSE = ETL_WH
    SCHEDULE = '10 MINUTES'
AS
CALL LOAD_RAW_DATA();
----------------------------------child task follows the root --------------------------

CREATE OR REPLACE TASK CLEAN_ORDERS_TASK
    WAREHOUSE = ETL_WH
    AFTER ROOT_TASK
AS
CALL CLEAN_ORDERS();

--------------------------------------task with multiple parents -------------------------

CREATE OR REPLACE TASK BUILD_SALES_TASK
    WAREHOUSE = ETL_WH
    AFTER CLEAN_ORDERS_TASK, CLEAN_CUSTOMERS_TASK
AS
CALL BUILD_SALES_MODEL();

----------------------------------- finalizer task associated with root task to run at the end of the other tasks in the graph

CREATE OR REPLACE TASK PIPELINE_FINALIZER
    WAREHOUSE = ETL_WH
    FINALIZE = ROOT_TASK
AS
CALL LOG_PIPELINE_COMPLETION();

-------------------------------------lifecycle

1. task is in suspended mode(

ALTER TASK PROCESS_ORDERS_TASK RESUME;

2. suspend if you want to stop the task

ALTER TASK PROCESS_ORDERS_TASK SUSPEND;

3. if you want to run manually than execute by schedule 

EXECUTE TASK PROCESS_ORDERS_TASK;

---------------------------Monitoring task ---------------------------

SHOW TASKS IN SCHEMA SALES_DB.ETL;


DESCRIBE TASK SALES_DB.ETL.PROCESS_ORDERS_TASK;



SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME => 'PROCESS_ORDERS_TASK',
        SCHEDULED_TIME_RANGE_START =>
            DATEADD('hour', -24, CURRENT_TIMESTAMP())
    )
)
ORDER BY SCHEDULED_TIME DESC;


-- A stream tells you what changed, while a task determines when and how to process those changes