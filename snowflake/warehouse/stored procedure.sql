CREATE OR REPLACE PROCEDURE SALES_DB.ETL.UPDATE_ORDER_STATUS(
    P_ORDER_ID NUMBER,
    P_NEW_STATUS VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
    UPDATE SALES_DB.SALES.ORDERS
    SET
        ORDER_STATUS = :P_NEW_STATUS,
        UPDATED_AT = CURRENT_TIMESTAMP()
    WHERE ORDER_ID = :P_ORDER_ID;

    RETURN 'Order status updated successfully';
END;
$$;
---------------------------------------------------
CALL SALES_DB.ETL.UPDATE_ORDER_STATUS(
    1001,
    'COMPLETED'
);
---------------------------------------------------

-- General Procedure structure

CREATE [ OR REPLACE ] PROCEDURE procedure_name
(
    argument_name data_type,
    ...
)
RETURNS return_type
LANGUAGE SQL
EXECUTE AS OWNER | CALLER | RESTRICTED CALLER
AS
$$
DECLARE
    -- Variables, cursors and result sets
BEGIN
    -- Procedure logic

    RETURN value;

EXCEPTION
    -- Error-handling logic
END;
$$;

-----------------------------------------------------

-- Default Arguments must generally appear after required arguments

CREATE OR REPLACE PROCEDURE greet_user(
    user_name VARCHAR,
    greeting VARCHAR DEFAULT 'Hello'
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    RETURN greeting || ', ' || user_name;
END;
$$;

-----------------------------------------------------
-- we can define the variable using declare and let

-- declare a number(18,2) default 0
-- let b number (18,2) :=2

-- above we can see the difference on defining the variable 

-- inside the sql statement append colon infront of variable but not for return, if or any assignment 

-- but a := b + c use the colon 

-- after the DML statement if you use the SQLROWCOUNT it will give the affected row count we can use that on return statement 

------------------------------------------------------

-- IF, FOR, REVERSE FOR, WHILE, CASE

-- IF 

CREATE OR REPLACE PROCEDURE classify_salary(salary NUMBER)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    IF (salary >= 100000) THEN
        RETURN 'High';
    ELSEIF (salary >= 50000) THEN
        RETURN 'Medium';
    ELSE
        RETURN 'Low';
    END IF;
END;
$$;

-----------------------------------------------

-- CASE 

CREATE OR REPLACE PROCEDURE get_quarter_name(month_number NUMBER)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    quarter_name VARCHAR;
BEGIN
    CASE
        WHEN month_number BETWEEN 1 AND 3 THEN
            quarter_name := 'Q1';
        WHEN month_number BETWEEN 4 AND 6 THEN
            quarter_name := 'Q2';
        WHEN month_number BETWEEN 7 AND 9 THEN
            quarter_name := 'Q3';
        WHEN month_number BETWEEN 10 AND 12 THEN
            quarter_name := 'Q4';
        ELSE
            quarter_name := 'Invalid month';
    END CASE;

    RETURN quarter_name;
END;
$$;

------------------------------------------------------------

-- for loop 
-- Snowflake Scripting supports counter-based, cursor-based, and RESULTSET-based FOR loops.

CREATE OR REPLACE PROCEDURE insert_numbers(max_number NUMBER)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    FOR i IN 1 TO max_number DO
        INSERT INTO number_table(number_value)
        VALUES (:i);
    END FOR;

    RETURN max_number || ' rows inserted';
END;
$$;

---------------------------------------------------------------------

-- while loop 

CREATE OR REPLACE PROCEDURE while_loop_example(max_number NUMBER)
RETURNS NUMBER
LANGUAGE SQL
AS
$$
DECLARE
    current_number NUMBER DEFAULT 1;
    total NUMBER DEFAULT 0;
BEGIN
    WHILE (current_number <= max_number) DO
        total := total + current_number;
        current_number := current_number + 1;
    END WHILE;

    RETURN total;
END;
$$;

-------------------------------------------------------

-- Result set and returning a table 

CREATE OR REPLACE PROCEDURE get_employees_by_department(
    input_department VARCHAR
)
RETURNS TABLE (
    employee_id NUMBER,
    employee_name VARCHAR,
    department_name VARCHAR
)
LANGUAGE SQL
AS
$$
DECLARE
    result_set RESULTSET;
BEGIN
    result_set := (
        SELECT
            employee_id,
            employee_name,
            department_name
        FROM employees
        WHERE department_name = :input_department
        ORDER BY employee_id
    );

    RETURN TABLE(result_set);
END;
$$;

------------------------------------------------------------------

-- cursor based processing 

-- where each result row requires seperate procedural processing 

CREATE OR REPLACE PROCEDURE process_employees()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    employee_cursor CURSOR FOR
        SELECT employee_id, salary
        FROM employees
        WHERE active_flag = TRUE;

    processed_count NUMBER DEFAULT 0;
BEGIN
    FOR employee_record IN employee_cursor DO
        UPDATE employees
        SET salary = employee_record.salary * 1.05
        WHERE employee_id = employee_record.employee_id;

        processed_count := processed_count + 1;
    END FOR;

    RETURN processed_count || ' employees processed';
END;
$$;

-------------------------------------------------------

-- Dynamic sql, we can create the dynamic sql which knows part of the sql statement at runtime. we can run using Execute immediate

CREATE OR REPLACE PROCEDURE count_table_rows(table_name VARCHAR)
RETURNS NUMBER
LANGUAGE SQL
AS
$$
DECLARE
    sql_statement VARCHAR;
    row_count NUMBER;
    result_set RESULTSET;
BEGIN
    sql_statement :=
        'SELECT COUNT(*) AS row_count FROM IDENTIFIER(?)';

    result_set := (
        EXECUTE IMMEDIATE :sql_statement
        USING (table_name)
    );

    LET result_cursor CURSOR FOR result_set;

    FOR record IN result_cursor DO
        row_count := record.row_count;
    END FOR;

    RETURN row_count;
END;
$$;

----------------------------------------------------------------------------------

-- Exception handling 

CREATE OR REPLACE PROCEDURE count_table_rows(table_name VARCHAR)
RETURNS NUMBER
LANGUAGE SQL
AS
$$
DECLARE
    sql_statement VARCHAR;
    row_count NUMBER;
    result_set RESULTSET;
BEGIN
    sql_statement :=
        'SELECT COUNT(*) AS row_count FROM IDENTIFIER(?)';

    result_set := (
        EXECUTE IMMEDIATE :sql_statement
        USING (table_name)
    );

    LET result_cursor CURSOR FOR result_set;

    FOR record IN result_cursor DO
        row_count := record.row_count;
    END FOR;

    RETURN row_count;
END;
$$;


------------------Custom Exception handling also we can use continue to make sure the following statements runs fine 

CREATE OR REPLACE PROCEDURE validate_salary(salary NUMBER)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    invalid_salary EXCEPTION (
        -20001,
        'Salary must be greater than zero'
    );
BEGIN
    IF (salary <= 0) THEN
        RAISE invalid_salary;
    END IF;

    RETURN 'Salary is valid';

EXCEPTION
    WHEN invalid_salary THEN
        RETURN SQLERRM;
END;
$$;

-----------------------------------------------

-- Transaction Handling is important in database why because consistency is important. if both the statements are inter connected then both should be atomic or else we should rollback it to make it atomic 

CREATE OR REPLACE PROCEDURE transfer_amount(
    from_account NUMBER,
    to_account NUMBER,
    transfer_amount NUMBER
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    BEGIN TRANSACTION; -- start 

    UPDATE accounts
    SET balance = balance - :transfer_amount
    WHERE account_id = :from_account;

    UPDATE accounts
    SET balance = balance + :transfer_amount
    WHERE account_id = :to_account;

    COMMIT;  -- end 

    RETURN 'Transfer completed';

EXCEPTION
    WHEN OTHER THEN
        ROLLBACK;  -- else case
        RETURN 'Transfer failed: ' || SQLERRM;
END;
$$;

-------------------------------------------------------------

-- Production Style ETL Procedure

CREATE OR REPLACE PROCEDURE load_customer_dimension(
    load_date DATE
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    inserted_rows NUMBER DEFAULT 0;
    updated_rows NUMBER DEFAULT 0;
    message VARCHAR;
BEGIN
    BEGIN TRANSACTION;

    UPDATE customer_dimension AS target
    SET
        target.customer_name = source.customer_name,
        target.email_address = source.email_address,
        target.updated_at = CURRENT_TIMESTAMP()
    FROM customer_stage AS source
    WHERE target.customer_id = source.customer_id
      AND source.load_date = :load_date
      AND (
          target.customer_name <> source.customer_name
          OR target.email_address <> source.email_address
      );

    updated_rows := SQLROWCOUNT;

    INSERT INTO customer_dimension (
        customer_id,
        customer_name,
        email_address,
        created_at,
        updated_at
    )
    SELECT
        source.customer_id,
        source.customer_name,
        source.email_address,
        CURRENT_TIMESTAMP(),
        CURRENT_TIMESTAMP()
    FROM customer_stage AS source
    WHERE source.load_date = :load_date
      AND NOT EXISTS (
          SELECT 1
          FROM customer_dimension AS target
          WHERE target.customer_id = source.customer_id
      );

    inserted_rows := SQLROWCOUNT;

    COMMIT;

    message :=
        'Load completed. Inserted: ' || inserted_rows ||
        ', Updated: ' || updated_rows;

    RETURN message;

EXCEPTION
    WHEN OTHER THEN
        ROLLBACK;

        INSERT INTO procedure_error_log (
            procedure_name,
            error_code,
            error_message,
            error_state,
            logged_at
        )
        VALUES (
            'LOAD_CUSTOMER_DIMENSION',
            :SQLCODE,
            :SQLERRM,
            :SQLSTATE,
            CURRENT_TIMESTAMP()
        );

        RAISE;
END;
$$;

------------------------------------------------------------

-- Procedure Management commands 

1. SHOW PROCEDURE 
2. SHOW PROCEDURE LIKE 
3. DESCRIBE PROCEDURE load_customer_dimension(DATE);
4. DROP PROCEDURE load_customer_dimension(DATE);
5. GRANT USAGE
ON PROCEDURE load_customer_dimension(DATE)
TO ROLE data_engineer_role;


-- Reusable Advanced Template

CREATE OR REPLACE PROCEDURE database_name.schema_name.procedure_name(
    input_parameter VARCHAR,
    processing_date DATE DEFAULT CURRENT_DATE()
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
COMMENT = 'Description of the procedure'
AS
$$
DECLARE
    affected_rows NUMBER DEFAULT 0;
    return_message VARCHAR;
BEGIN
    BEGIN TRANSACTION;

    -- Validate input
    IF (input_parameter IS NULL) THEN
        RETURN 'Input parameter cannot be NULL';
    END IF;

    -- Main processing
    UPDATE target_table
    SET
        status = 'PROCESSED',
        updated_at = CURRENT_TIMESTAMP()
    WHERE business_key = :input_parameter
      AND record_date = :processing_date;

    affected_rows := SQLROWCOUNT;

    COMMIT;

    return_message :=
        'Procedure completed. Rows affected: ' ||
        affected_rows;

    RETURN return_message;

EXCEPTION
    WHEN STATEMENT_ERROR THEN
        ROLLBACK;

        RETURN
            'Statement error. Code: ' || SQLCODE ||
            ', State: ' || SQLSTATE ||
            ', Message: ' || SQLERRM;

    WHEN OTHER THEN
        ROLLBACK;

        RETURN 'Unexpected error: ' || SQLERRM;
END;
$$;
-----------------------------------------------------------------

-- Use RETURN TABLE(result_set) for table-returning procedures.
-- Use EXECUTE IMMEDIATE only when SQL composition must happen at runtime.
-- Prefer bindings and IDENTIFIER() over concatenating values into dynamic SQL.
-- Use set-based SQL instead of cursors whenever possible.
-- Choose EXECUTE AS OWNER or EXECUTE AS CALLER deliberately.
-- Add explicit transaction handling when a multi-statement operation must be atomic.
-- Include the procedure’s argument types when describing, dropping, or granting access to an overloaded procedure.


-- Nested blocks and local exception handling 

CREATE OR REPLACE PROCEDURE nested_exception_example()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    audit_status VARCHAR DEFAULT 'Not attempted';
BEGIN
    UPDATE customer_target
    SET processed_flag = TRUE
    WHERE processed_flag = FALSE;

    BEGIN
        INSERT INTO optional_audit_table(
            process_name,
            executed_at
        )
        VALUES (
            'CUSTOMER_PROCESS',
            CURRENT_TIMESTAMP()
        );

        audit_status := 'Audit successful';

    EXCEPTION
        WHEN OTHER THEN
            audit_status := 'Audit failed: ' || SQLERRM;
    END;

    RETURN 'Main processing completed. ' || audit_status;

EXCEPTION
    WHEN OTHER THEN
        RETURN 'Main processing failed: ' || SQLERRM;
END;
$$;

-----------------------------------------------------------------

-- Re-raising an exception is important when we work with orchestration tool why because when we use the exception handling at that time the tools will think like the procedure successfull it will lead to a problem. So we should throw a error to make it aware of the error also log it for the future reference

CREATE OR REPLACE PROCEDURE load_orders()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO order_target
    SELECT *
    FROM order_stage;

    RETURN 'Order load completed';

EXCEPTION
    WHEN OTHER THEN
        INSERT INTO error_log (
            procedure_name,
            error_code,
            error_state,
            error_message,
            error_timestamp
        )
        VALUES (
            'LOAD_ORDERS',
            :SQLCODE,
            :SQLSTATE,
            :SQLERRM,
            CURRENT_TIMESTAMP()
        );

        RAISE; -- important 
END;
$$;

-----------------------------------------------------------

-- Production exception pattern 

CREATE OR REPLACE PROCEDURE load_customer_dimension(
    load_date DATE
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    current_step VARCHAR DEFAULT 'Validation';
    affected_rows NUMBER DEFAULT 0;

    invalid_load_date EXCEPTION (
        -20001,
        'Load date cannot be NULL'
    );
BEGIN
    IF (load_date IS NULL) THEN
        RAISE invalid_load_date;
    END IF;

    current_step := 'Starting transaction';

    BEGIN TRANSACTION;

    current_step := 'Merging customer records';

    MERGE INTO customer_dimension AS target
    USING (
        SELECT *
        FROM customer_stage
        WHERE load_date = :load_date
    ) AS source
        ON target.customer_id = source.customer_id
    WHEN MATCHED THEN
        UPDATE SET
            target.customer_name = source.customer_name,
            target.updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN
        INSERT (
            customer_id,
            customer_name,
            created_at,
            updated_at
        )
        VALUES (
            source.customer_id,
            source.customer_name,
            CURRENT_TIMESTAMP(),
            CURRENT_TIMESTAMP()
        );

    affected_rows := SQLROWCOUNT;

    current_step := 'Committing transaction';

    COMMIT;

    RETURN
        'Load completed successfully. Rows affected: ' ||
        affected_rows;

EXCEPTION
    WHEN invalid_load_date THEN
        RETURN 'Validation failure: ' || SQLERRM;

    WHEN STATEMENT_ERROR THEN
        ROLLBACK;

        INSERT INTO procedure_error_log (
            procedure_name,
            processing_step,
            error_code,
            error_state,
            error_message,
            logged_at
        )
        VALUES (
            'LOAD_CUSTOMER_DIMENSION',
            :current_step,
            :SQLCODE,
            :SQLSTATE,
            :SQLERRM,
            CURRENT_TIMESTAMP()
        );

        RAISE;

    WHEN OTHER THEN
        ROLLBACK;

        INSERT INTO procedure_error_log (
            procedure_name,
            processing_step,
            error_code,
            error_state,
            error_message,
            logged_at
        )
        VALUES (
            'LOAD_CUSTOMER_DIMENSION',
            :current_step,
            :SQLCODE,
            :SQLSTATE,
            :SQLERRM,
            CURRENT_TIMESTAMP()
        );

        RAISE;
END;
$$;

-------------------------------------------------------------------


