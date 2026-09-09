-- we have three types of streams 

-- Standard streams (which tracks all the changes)
-- append only stream for normal table and views and tracks the insert only 
-- insert only stream for external table 

-- I will get three option 

-- METADATA$ACTION
-- METADATA$IS_UPDATE
-- METADATA$ROW_ID

CREATE STREAM ORDERS_STREAM
ON TABLE ORDERS;

-------------------OR-----------------

CREATE STREAM ORDERS_STREAM
ON TABLE ORDERS
APPEND_ONLY = FALSE;

---------------------APPEND ONLY STREAM---------------

CREATE STREAM NEW_ORDERS_STREAM
ON TABLE ORDERS
APPEND_ONLY = TRUE;

--------------------- INSERT ONLY STREAM------------------

CREATE STREAM EXTERNAL_ORDERS_STREAM
ON EXTERNAL TABLE EXTERNAL_ORDERS

------------------------ using a stream with merge -------------------------------

MERGE INTO ORDERS_TARGET T
USING ORDERS_STREAM S
    ON T.ORDER_ID = S.ORDER_ID

WHEN MATCHED
     AND S.METADATA$ACTION = 'DELETE'
     AND S.METADATA$ISUPDATE = FALSE
THEN DELETE

WHEN MATCHED
     AND S.METADATA$ACTION = 'INSERT'
THEN UPDATE SET
    T.STATUS = S.STATUS,
    T.ORDER_AMOUNT = S.ORDER_AMOUNT

WHEN NOT MATCHED
     AND S.METADATA$ACTION = 'INSERT'
THEN INSERT
(
    ORDER_ID,
    STATUS,
    ORDER_AMOUNT
)
VALUES
(
    S.ORDER_ID,
    S.STATUS,
    S.ORDER_AMOUNT
);
--------------------------- show initial rows --------------------------------
-- why we needed for incremental processing, before you create stream your table might have some data, if you need that data
-- add that option

CREATE STREAM ORDERS_STREAM
ON TABLE ORDERS
SHOW_INITIAL_ROWS = TRUE;

-------------------------------------creating a stream with different options ------------------------------------------

CREATE STREAM ORDERS_STREAM
ON TABLE ORDERS
AT (
    TIMESTAMP => '2026-09-03 10:00:00'
);


CREATE STREAM ORDERS_STREAM
ON TABLE ORDERS
BEFORE (
    STATEMENT => 'query-id')


CREATE STREAM ORDERS_STREAM_COPY
ON TABLE ORDERS
AT (
    STREAM => 'ORDERS_STREAM'
);
--------------------------------------------------------------

-- Stream options summary
-- OR REPLACE: Replaces an existing stream.
-- IF NOT EXISTS: Creates it only when it does not already exist.
-- COPY GRANTS: Preserves explicit grants during replacement.
-- APPEND_ONLY: Returns inserted rows only on supported tables and views.
-- INSERT_ONLY: Tracks inserted rows for external tables.
-- SHOW_INITIAL_ROWS: Includes rows present before stream creation during initial consumption.
-- AT | BEFORE: Sets the stream offset at a historical transactional point.
-- COMMENT: Documents the stream's purpose.
-- TAG: Assigns governance metadata.
-- CLONE: Creates another stream with the source stream's current offset.
-- Easy way to remember

-- A stream is a bookmark over a source object's change history. It shows what changed after the bookmark, and the bookmark advances when those changes are consumed in a committed DML transaction.