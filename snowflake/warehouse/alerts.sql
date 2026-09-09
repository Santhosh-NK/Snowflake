-- Alerts in Snowflake

-- A Snowflake Alert is a schema-level object that periodically evaluates a SQL condition and performs an action when that condition returns one or more rows.

-- Alerts can:

-- Send email or webhook notifications
-- Insert records into an audit table
-- Call a stored procedure
-- Execute corrective SQL
-- Monitor data quality, pipeline failures, costs, security, or freshness

CREATE OR REPLACE ALERT <alert_name>
    WAREHOUSE = <warehouse_name>
    SCHEDULE = '<schedule>'
    COMMENT = '<description>'
IF (
    EXISTS (
        <condition_query>
    )
)
THEN
    <action>;


---------------------- complete example -----------------

CREATE OR REPLACE ALERT SALES_DB.MONITORING.LOAD_FAILURE_ALERT
    WAREHOUSE = MONITORING_WH
    SCHEDULE = '5 MINUTE'
    SUSPEND_ALERT_AFTER_NUM_FAILURES = 5
    COMMENT = 'Captures failed COPY operations'
IF (
    EXISTS (
        SELECT 1
        FROM SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY
        WHERE STATUS = 'LOAD_FAILED'
          AND LAST_LOAD_TIME >=
              DATEADD(
                  'minute',
                  -5,
                  SNOWFLAKE.ALERT.SCHEDULED_TIME()
              )
    )
)
THEN
    INSERT INTO SALES_DB.MONITORING.ALERT_LOG
    (
        ALERT_NAME,
        ALERT_MESSAGE,
        ALERT_TIME
    )
    VALUES
    (
        'LOAD_FAILURE_ALERT',
        'One or more data loads failed',
        CURRENT_TIMESTAMP()
    );

    ------------------

    CREATE OR REPLACE NOTIFICATION INTEGRATION EMAIL_NOTIFICATION_INT
    TYPE = EMAIL
    ENABLED = TRUE
    ALLOWED_RECIPIENTS = (
        'dataengineering@example.com'
    );

------------------------------------------------------------------------
    CREATE OR REPLACE ALERT SALES_DB.MONITORING.NEGATIVE_AMOUNT_ALERT
    WAREHOUSE = MONITORING_WH
    SCHEDULE = '10 MINUTE'
    COMMENT = 'Detects invalid negative order amounts'
IF (
    EXISTS (
        SELECT 1
        FROM SALES_DB.RAW.ORDERS
        WHERE ORDER_AMOUNT < 0
    )
)
THEN
    CALL SYSTEM$SEND_EMAIL(
        'EMAIL_NOTIFICATION_INT',
        'dataengineering@example.com',
        'Snowflake data-quality alert',
        'Negative order amounts were detected in SALES_DB.RAW.ORDERS.'
    );