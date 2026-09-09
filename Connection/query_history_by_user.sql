select * from table(INFORMATION_SCHEMA.query_history_by_user(
user_name=>'santhosh0000',
end_time_range_start=>dateadd('day',-6,current_timestamp()),
end_time_range_end=>current_timestamp()

))

select * from snowflake.account_usage.query_history
where start_time >=dateadd('day',-7,current_timestamp()) and user_name='SANTHOSH0000'
order by end_time desc;


SELECT CURRENT_SESSION();
