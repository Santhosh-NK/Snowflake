---------------------enabling directory on the stage---------------------
CREATE STAGE AZURE_FILES_STAGE
    URL = 'azure://account.blob.core.windows.net/container/files/'
    STORAGE_INTEGRATION = AZURE_STORAGE_INT
    DIRECTORY = (
        ENABLE = TRUE
    );

--------------------for checking the files------------------

SELECT *
FROM DIRECTORY(@AZURE_FILES_STAGE);