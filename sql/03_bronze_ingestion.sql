/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Module 1 Reference: Bronze Layer Ingestion
    
    Pattern: External Stage (S3) → File Format → Snowpipe → Bronze Table
    
    In the lab, attendees will use Cortex Code to generate this.
    This file is a reference implementation.
*/

--------------------------------------------------------------------
-- OPTION A: Real S3 External Stage (if storage integration is set up)
--------------------------------------------------------------------

/*
-- External Stage pointing to S3 landing zone
CREATE OR REPLACE STAGE LANDING_ZONE_STAGE
    STORAGE_INTEGRATION = encova_s3_integration
    URL = 's3://encova-training-landing-zone/claims/'
    FILE_FORMAT = (TYPE = 'JSON');

-- File format for raw JSON claim files
CREATE OR REPLACE FILE FORMAT CLAIMS_JSON_FORMAT
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    COMPRESSION = 'AUTO';

-- File format for CSV policy files
CREATE OR REPLACE FILE FORMAT POLICIES_CSV_FORMAT
    TYPE = 'CSV'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('', 'NULL');

-- Bronze table for raw claims (stores raw JSON variant)
CREATE OR REPLACE TABLE CLAIMS_BRONZE (
    RAW_DATA        VARIANT,
    SOURCE_FILE     VARCHAR(500),
    INGESTION_TS    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    RECORD_METADATA VARIANT
);

-- Snowpipe for auto-ingest from S3 (requires SQS notification setup)
CREATE OR REPLACE PIPE CLAIMS_INGEST_PIPE
    AUTO_INGEST = TRUE
    AS
    COPY INTO CLAIMS_BRONZE (RAW_DATA, SOURCE_FILE, INGESTION_TS, RECORD_METADATA)
    FROM (
        SELECT 
            $1,
            METADATA$FILENAME,
            CURRENT_TIMESTAMP(),
            OBJECT_CONSTRUCT(
                'file_row_number', METADATA$FILE_ROW_NUMBER,
                'file_content_key', METADATA$FILE_CONTENT_KEY,
                'file_last_modified', METADATA$FILE_LAST_MODIFIED
            )
        FROM @LANDING_ZONE_STAGE
    )
    FILE_FORMAT = (FORMAT_NAME = 'CLAIMS_JSON_FORMAT');

-- Show pipe status
SHOW PIPES;
SELECT SYSTEM$PIPE_STATUS('CLAIMS_INGEST_PIPE');
*/

--------------------------------------------------------------------
-- OPTION B: Internal Stage Simulation (for lab use)
-- Uses Streams on RAW_DATA tables to simulate incremental S3 loads
--------------------------------------------------------------------

-- Stream on CLAIMS_RAW to capture new/changed records (simulates new S3 files arriving)
CREATE OR REPLACE STREAM CLAIMS_RAW_STREAM
    ON TABLE RAW_DATA.CLAIMS_RAW
    SHOW_INITIAL_ROWS = TRUE
    COMMENT = 'Captures new claims arriving in landing zone (simulates S3 ingest)';

-- Stream on CLAIM_NOTES for incremental note processing
CREATE OR REPLACE STREAM CLAIM_NOTES_STREAM
    ON TABLE RAW_DATA.CLAIM_NOTES
    SHOW_INITIAL_ROWS = TRUE
    COMMENT = 'Captures new adjuster notes for AI enrichment';

-- Bronze layer: Parsed and lightly validated claims
-- Dynamic Table auto-refreshes as new data arrives via stream
CREATE OR REPLACE DYNAMIC TABLE CLAIMS_BRONZE
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '1 minute'
    COMMENT = 'Bronze layer: parsed raw claims with basic validation'
AS
SELECT
    CLAIM_ID,
    POLICY_ID,
    CLAIMANT_ID,
    CLAIM_NUMBER,
    DATE_OF_LOSS,
    DATE_REPORTED,
    CLAIM_STATUS,
    LOSS_TYPE,
    LOSS_DESCRIPTION,
    LOSS_LOCATION_STATE,
    LOSS_LOCATION_CITY,
    ESTIMATED_AMOUNT,
    PAID_AMOUNT,
    RESERVED_AMOUNT,
    ADJUSTER_ID,
    FRAUD_INDICATOR,
    SEVERITY,
    CAUSE_OF_LOSS,
    WEATHER_RELATED,
    LITIGATION_FLAG,
    CREATED_AT,
    -- Bronze metadata
    DATEDIFF('day', DATE_OF_LOSS, DATE_REPORTED) AS DAYS_TO_REPORT,
    CASE 
        WHEN ESTIMATED_AMOUNT IS NULL OR ESTIMATED_AMOUNT <= 0 THEN FALSE
        ELSE TRUE
    END AS HAS_VALID_ESTIMATE,
    CURRENT_TIMESTAMP() AS BRONZE_LOADED_AT
FROM RAW_DATA.CLAIMS_RAW;

-- Verify Bronze table
SELECT COUNT(*) AS BRONZE_ROW_COUNT FROM CLAIMS_BRONZE;
SELECT * FROM CLAIMS_BRONZE LIMIT 5;
