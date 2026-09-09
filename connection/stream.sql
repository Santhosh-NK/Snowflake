
truncate TABLE BOOKINGS;

create notification integration snowpipenotification
type=QUEUE
ENABLED=TRUE
NOTIFICATION_PROVIDER='AZURE_STORAGE_QUEUE'
AZURE_TENANT_ID='e18e8ddf-4cdd-4c0d-86e9-af9546b5441f'
AZURE_STORAGE_QUEUE_PRIMARY_URI='https://santhoshdbtaccount.queue.core.windows.net/snowpipe-queue'

DESCRIBE INTEGRATION SNOWPIPENOTIFICATION


create OR REPLACE pipe snowpipe
auto_ingest = true
integration=SNOWPIPENOTIFICATION
as 
copy into bookings
from @STAGESNOWBATCH

SELECT SYSTEM$PIPE_STATUS('snowpipe');

LIST @STAGESNOWBATCH

SELECT * FROM BOOKINGS

