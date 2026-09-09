CREATE OR REPLACE MASKING POLICY GOVERNANCE_DB.POLICIES.EMAIL_MASK
AS (EMAIL_VALUE VARCHAR)
RETURNS VARCHAR
->
CASE
    WHEN IS_ROLE_IN_SESSION('PII_ADMIN')
        THEN EMAIL_VALUE

    WHEN IS_ROLE_IN_SESSION('DATA_ANALYST')
        THEN REGEXP_REPLACE(
            EMAIL_VALUE,
            '^[^@]+',
            '*****'
        )

    ELSE '***MASKED***'
END
COMMENT = 'Masks email addresses based on role';


---------------------- Conditional Masking --------------------------------

CREATE OR REPLACE MASKING POLICY GOVERNANCE_DB.POLICIES.SALARY_MASK
AS (
    SALARY_VALUE NUMBER,
    DEPARTMENT_VALUE VARCHAR
)
RETURNS NUMBER
->
CASE
    WHEN IS_ROLE_IN_SESSION('HR_ADMIN')
        THEN SALARY_VALUE

    WHEN IS_ROLE_IN_SESSION('FINANCE_ANALYST')
         AND DEPARTMENT_VALUE = 'FINANCE'
        THEN SALARY_VALUE

    ELSE NULL
END;


--------------------------Apply the policy to a column --------------------------

ALTER TABLE SALES_DB.CUSTOMER.CUSTOMERS
    MODIFY COLUMN EMAIL
    SET MASKING POLICY GOVERNANCE_DB.POLICIES.EMAIL_MASK;
---------------------------- Unset Masking Policy ------------------------------

ALTER TABLE SALES_DB.CUSTOMER.CUSTOMERS
    MODIFY COLUMN EMAIL
    UNSET MASKING POLICY 

---------------------------- Apply it using both columns ------------------------

ALTER TABLE HR_DB.HR.EMPLOYEES
    MODIFY COLUMN SALARY
    SET MASKING POLICY GOVERNANCE_DB.POLICIES.SALARY_MASK
    USING (SALARY, DEPARTMENT);

----------------------------------------------------Row Access Policy--------------------------------------------------------------------

-- A Row Access Policy provides row-level security by evaluating a Boolean expression for each row.

-- TRUE: The user can see the row.
-- FALSE or NULL: The row is excluded.


CREATE OR REPLACE ROW ACCESS POLICY
    GOVERNANCE_DB.POLICIES.REGION_ACCESS_POLICY
AS (REGION_VALUE VARCHAR)
RETURNS BOOLEAN
->
CASE
    WHEN IS_ROLE_IN_SESSION('GLOBAL_SALES_ADMIN')
        THEN TRUE

    WHEN IS_ROLE_IN_SESSION('APAC_ANALYST')
         AND REGION_VALUE = 'APAC'
        THEN TRUE

    WHEN IS_ROLE_IN_SESSION('EMEA_ANALYST')
         AND REGION_VALUE = 'EMEA'
        THEN TRUE

    ELSE FALSE
END
COMMENT = 'Restricts sales rows based on region';

------------------------------------------------------------------------------------

ALTER TABLE SALES_DB.SALES.ORDERS
    ADD ROW ACCESS POLICY
        GOVERNANCE_DB.POLICIES.REGION_ACCESS_POLICY
    ON (REGION);

ALTER TABLE SALES_DB.SALES.ORDERS
    DROP ROW ACCESS POLICY
        GOVERNANCE_DB.POLICIES.REGION_ACCESS_POLICY;



--------------------------------- use with mapping table -----------------------------

CREATE OR REPLACE TABLE GOVERNANCE_DB.POLICIES.REGION_ACCESS_MAP
(
    ROLE_NAME VARCHAR,
    REGION    VARCHAR
);


INSERT INTO GOVERNANCE_DB.POLICIES.REGION_ACCESS_MAP
VALUES
    ('APAC_ANALYST', 'APAC'),
    ('INDIA_ANALYST', 'INDIA'),
    ('EMEA_ANALYST', 'EMEA');


CREATE OR REPLACE ROW ACCESS POLICY
    GOVERNANCE_DB.POLICIES.REGION_ACCESS_POLICY
AS (REGION_VALUE VARCHAR)
RETURNS BOOLEAN
->
    IS_ROLE_IN_SESSION('GLOBAL_SALES_ADMIN')
    OR EXISTS (
        SELECT 1
        FROM GOVERNANCE_DB.POLICIES.REGION_ACCESS_MAP M
        WHERE IS_ROLE_IN_SESSION(M.ROLE_NAME)
          AND M.REGION = REGION_VALUE
    );

    




