/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Admin Pre-Lab: Environment Setup
    
    Run as: ACCOUNTADMIN
    This is run by the admin BEFORE the lab. Attendees do NOT run this.
*/

USE ROLE ACCOUNTADMIN;

--------------------------------------------------------------------
-- 1. Shared Database & Warehouse
--------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS ENCOVA_TRAINING
    COMMENT = 'Shared lab database — raw data and stage for all attendees';

CREATE WAREHOUSE IF NOT EXISTS ENCOVA_TRAINING_WH
    WAREHOUSE_SIZE = 'LARGE'
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 10
    SCALING_POLICY = 'STANDARD'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    COMMENT = 'Shared multi-cluster warehouse (scales to 10 clusters)';

USE DATABASE ENCOVA_TRAINING;
USE WAREHOUSE ENCOVA_TRAINING_WH;

--------------------------------------------------------------------
-- 2. Shared Source Schema (raw data + loading stage)
--------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS RAW_DATA
    COMMENT = 'Shared raw data — attendees read from here via stage';

--------------------------------------------------------------------
-- 3. Per-Attendee Databases
--    NOT created here. Use the CoCo provisioning prompt:
--    prompts/admin_prompts/0.0_provision_attendees.md
--    That prompt reads attendees.txt and creates:
--      - TRAINING_<NAME> database
--      - BRONZE, SILVER, GOLD schemas within it
--    All owned by ATTENDEE_ROLE.
--------------------------------------------------------------------

--------------------------------------------------------------------
-- 4. Workshop Role
--------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS ATTENDEE_ROLE
    COMMENT = 'Role for Encova HoL attendees — owns all lab objects';

--------------------------------------------------------------------
-- 5. Transfer Ownership (ATTENDEE_ROLE owns shared resources)
--------------------------------------------------------------------
GRANT OWNERSHIP ON DATABASE ENCOVA_TRAINING TO ROLE ATTENDEE_ROLE COPY CURRENT GRANTS;
GRANT OWNERSHIP ON SCHEMA ENCOVA_TRAINING.RAW_DATA TO ROLE ATTENDEE_ROLE COPY CURRENT GRANTS;
GRANT OWNERSHIP ON WAREHOUSE ENCOVA_TRAINING_WH TO ROLE ATTENDEE_ROLE COPY CURRENT GRANTS;

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ATTENDEE_ROLE;

--------------------------------------------------------------------
-- 6. Account-Level Grants
--------------------------------------------------------------------
GRANT EXECUTE TASK ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE ATTENDEE_ROLE;

--------------------------------------------------------------------
-- 7. Assign Role to Attendees (update with actual usernames)
--------------------------------------------------------------------
-- GRANT ROLE ATTENDEE_ROLE TO USER encova_user1;
-- GRANT ROLE ATTENDEE_ROLE TO USER encova_user2;
