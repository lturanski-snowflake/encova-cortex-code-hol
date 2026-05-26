/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Attendee Provisioning — Per-Attendee Schemas
    
    Run as: ACCOUNTADMIN
    Driven by: attendees.txt (one first name per line, uppercase)
    
    For each attendee name <NAME>, this script creates:
      - SCHEMA: ENCOVA_TRAINING.TRAINING_<NAME>
      - OWNERSHIP: Transferred to ATTENDEE_ROLE
    
    All attendees share ENCOVA_TRAINING_WH (LARGE, multi-cluster, up to 10 clusters).
    
    NOTE: This file is a REFERENCE TEMPLATE. The actual provisioning is done
    via the CoCo prompt at: prompts/admin_prompts/0.0_provision_attendees.md
    which reads attendees.txt and executes dynamically.
*/

USE ROLE ACCOUNTADMIN;
USE DATABASE ENCOVA_TRAINING;

--------------------------------------------------------------------
-- Template: Repeat for EACH name in attendees.txt
-- Replace <NAME> with the attendee's first name (uppercase)
--------------------------------------------------------------------

-- 1. Create per-attendee schema
CREATE SCHEMA IF NOT EXISTS ENCOVA_TRAINING.TRAINING_<NAME>
    COMMENT = 'Workspace schema for attendee <NAME>';

-- 2. Transfer ownership to the shared training role
GRANT OWNERSHIP ON SCHEMA ENCOVA_TRAINING.TRAINING_<NAME>
    TO ROLE ATTENDEE_ROLE COPY CURRENT GRANTS;

--------------------------------------------------------------------
-- After provisioning, each attendee sets their context with:
--   USE ROLE ATTENDEE_ROLE;
--   USE DATABASE ENCOVA_TRAINING;
--   USE SCHEMA TRAINING_<NAME>;
--   USE WAREHOUSE ENCOVA_TRAINING_WH;
--------------------------------------------------------------------
