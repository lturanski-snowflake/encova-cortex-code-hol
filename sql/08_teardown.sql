/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Teardown: Clean up all lab objects
    
    Run as: ATTENDEE_ROLE (your attendee schema)
    Uncomment what you want to clean up.
*/

-- USE ROLE ATTENDEE_ROLE;
-- USE DATABASE ENCOVA_TRAINING;
-- USE SCHEMA TRAINING_<USERNAME>;

--------------------------------------------------------------------
-- Module 4: Agent + Semantic View
--------------------------------------------------------------------
-- DROP AGENT IF EXISTS CLAIMS_ANALYTICS_AGENT;
-- DROP SEMANTIC VIEW IF EXISTS CLAIMS_ANALYTICS_SV;

--------------------------------------------------------------------
-- Module 3: Gold Layer
--------------------------------------------------------------------
-- DROP DYNAMIC TABLE IF EXISTS ADJUSTER_PERFORMANCE_GOLD;
-- DROP DYNAMIC TABLE IF EXISTS CLAIMS_METRICS_MONTHLY;
-- DROP DYNAMIC TABLE IF EXISTS CLAIMS_GOLD;

--------------------------------------------------------------------
-- Module 2: Silver Layer
--------------------------------------------------------------------
-- DROP DYNAMIC TABLE IF EXISTS CLAIM_NOTES_SILVER;
-- DROP DYNAMIC TABLE IF EXISTS CLAIMS_SILVER;

--------------------------------------------------------------------
-- Module 1: Bronze Layer + Streams
--------------------------------------------------------------------
-- DROP DYNAMIC TABLE IF EXISTS CLAIMS_BRONZE;
-- DROP STREAM IF EXISTS CLAIMS_RAW_STREAM;
-- DROP STREAM IF EXISTS CLAIM_NOTES_STREAM;

--------------------------------------------------------------------
-- Admin Teardown (ACCOUNTADMIN only — use for full account cleanup)
--------------------------------------------------------------------
/*
USE ROLE ACCOUNTADMIN;
DROP DATABASE IF EXISTS ENCOVA_TRAINING;
DROP WAREHOUSE IF EXISTS ENCOVA_TRAINING_WH;
DROP ROLE IF EXISTS ATTENDEE_ROLE;
*/
