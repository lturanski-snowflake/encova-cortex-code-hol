/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Pre-Flight: Verify Grants and Environment
    
    Run as: ATTENDEE_ROLE
    Quick checks to confirm everything is ready for the lab.
*/

USE ROLE ATTENDEE_ROLE;
USE DATABASE ENCOVA_TRAINING;
USE WAREHOUSE ENCOVA_TRAINING_WH;

--------------------------------------------------------------------
-- Check 1: RAW_DATA tables exist and are accessible
--------------------------------------------------------------------
SELECT 'RAW_DATA Tables' AS CHECK_NAME, COUNT(*) AS TABLE_COUNT
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'RAW_DATA';
-- EXPECTED: 5 tables

--------------------------------------------------------------------
-- Check 2: Row counts look correct
--------------------------------------------------------------------
SELECT 'POLICIES' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM RAW_DATA.POLICIES
UNION ALL SELECT 'CLAIMANTS', COUNT(*) FROM RAW_DATA.CLAIMANTS
UNION ALL SELECT 'CLAIMS_RAW', COUNT(*) FROM RAW_DATA.CLAIMS_RAW
UNION ALL SELECT 'AGENTS', COUNT(*) FROM RAW_DATA.AGENTS
UNION ALL SELECT 'CLAIM_NOTES', COUNT(*) FROM RAW_DATA.CLAIM_NOTES;
-- EXPECTED: POLICIES ~10K, CLAIMANTS ~8K, CLAIMS_RAW ~50K, AGENTS ~200, CLAIM_NOTES ~30K

--------------------------------------------------------------------
-- Check 3: Cortex AI Functions work
--------------------------------------------------------------------
SELECT SNOWFLAKE.CORTEX.SENTIMENT('The claim was processed quickly and the customer is satisfied.') AS SENTIMENT_TEST;
-- EXPECTED: Positive number (> 0)

--------------------------------------------------------------------
-- Check 4: Can create objects in attendee schema
--------------------------------------------------------------------
-- Replace with your schema
-- USE SCHEMA TRAINING_USER1;
-- CREATE OR REPLACE TABLE _GRANT_TEST (ID INT);
-- DROP TABLE _GRANT_TEST;
-- EXPECTED: Success (no errors)

--------------------------------------------------------------------
-- Check 5: Change tracking is enabled
--------------------------------------------------------------------
SELECT TABLE_NAME, CHANGE_TRACKING 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'RAW_DATA' 
AND TABLE_NAME IN ('CLAIMS_RAW', 'CLAIM_NOTES', 'POLICIES');
-- EXPECTED: All show CHANGE_TRACKING = 'ON'

--------------------------------------------------------------------
-- Check 6: Current context
--------------------------------------------------------------------
SELECT 
    CURRENT_ROLE() AS ROLE,
    CURRENT_DATABASE() AS DB,
    CURRENT_SCHEMA() AS SCHEMA,
    CURRENT_WAREHOUSE() AS WH;
