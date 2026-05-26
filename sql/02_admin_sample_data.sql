/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Admin Pre-Lab: Upload CSV Files to Stage
    
    Run as: ATTENDEE_ROLE (owns ENCOVA_TRAINING)
    After: 01_admin_environment_setup.sql
    
    This ONLY uploads CSV files to the stage. Attendees will create tables 
    and load data themselves in Module 1.2.
*/

USE ROLE ATTENDEE_ROLE;
USE DATABASE ENCOVA_TRAINING;
USE SCHEMA RAW_DATA;
USE WAREHOUSE ENCOVA_TRAINING_WH;

--------------------------------------------------------------------
-- 1. Create internal stage for CSV files
--------------------------------------------------------------------
CREATE OR REPLACE STAGE DATA_LOADING_STAGE
    FILE_FORMAT = (
        TYPE = 'CSV'
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
        NULL_IF = ('', 'NULL')
        EMPTY_FIELD_AS_NULL = TRUE
    )
    COMMENT = 'Stage holding raw CSV files — attendees load from here into their BRONZE schemas';

--------------------------------------------------------------------
-- 2. PUT CSV files to stage
--    Run from SnowSQL CLI (adjust path to your local repo clone)
--------------------------------------------------------------------
-- PUT file:///path/to/Encova/HoL/data/policies.csv @DATA_LOADING_STAGE/policies AUTO_COMPRESS=TRUE;
-- PUT file:///path/to/Encova/HoL/data/claimants.csv @DATA_LOADING_STAGE/claimants AUTO_COMPRESS=TRUE;
-- PUT file:///path/to/Encova/HoL/data/claims_raw.csv @DATA_LOADING_STAGE/claims_raw AUTO_COMPRESS=TRUE;
-- PUT file:///path/to/Encova/HoL/data/agents.csv @DATA_LOADING_STAGE/agents AUTO_COMPRESS=TRUE;
-- PUT file:///path/to/Encova/HoL/data/claim_notes.csv @DATA_LOADING_STAGE/claim_notes AUTO_COMPRESS=TRUE;

--------------------------------------------------------------------
-- 3. Verify files are in stage
--------------------------------------------------------------------
LIST @DATA_LOADING_STAGE;
