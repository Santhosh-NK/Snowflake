select * from table(information_schema.task_history(
scheduled_time_range_start=>dateadd('day',-6,current_timestamp())
))


SELECT
    NAME,
    DATABASE_NAME,
    SCHEMA_NAME,
    STATE,
    SCHEDULED_TIME,
    COMPLETED_TIME,
    QUERY_ID
FROM SNOWFLAKE.ACCOUNT_USAGE.TASK_HISTORY
WHERE SCHEDULED_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
ORDER BY SCHEDULED_TIME DESC;


select * from table(information_schema.current_task_graphs(
root_task_name,
error_only=>true
));

select * from table(information_schema.complete_task_graphs(
root_task_name,
error_only=>true
));


