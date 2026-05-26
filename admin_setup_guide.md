# Admin Setup Guide — Encova Medallion Architecture Lab

**For: Luke Turanski (SE)** | Run BEFORE the lab session

This guide walks you through setting up the dedicated Snowflake account so attendees have zero pre-work beyond signing in.

---

## Pre-Session Checklist

- [ ] Dedicated Snowflake account provisioned
- [ ] Attendee first names collected → populate `attendees.txt` (one per line, uppercase)
- [ ] S3 bucket with sample data ready (or internal stage simulation)
- [ ] Storage integration created for S3 access
- [ ] Run `01_admin_environment_setup.sql` as ACCOUNTADMIN
- [ ] Run `02_admin_sample_data.sql` as ACCOUNTADMIN
- [ ] **Provision attendees:** Run CoCo prompt from `prompts/admin_prompts/0.0_provision_attendees.md`
- [ ] Run `00_verify_grants.sql` to confirm everything works
- [ ] Test end-to-end as ATTENDEE_ROLE
- [ ] Confirm Cortex Code is enabled in the account
- [ ] Share login credentials with attendees (single shared user)

---

## Step 1: Account Configuration

Connect to the dedicated Snowflake account as ACCOUNTADMIN.

```sql
USE ROLE ACCOUNTADMIN;
```

### Enable Cortex Features

Ensure the following are enabled in the account:
- Cortex AI Functions (SENTIMENT, CLASSIFY, EXTRACT, SUMMARIZE, COMPLETE)
- Cortex Agents
- Semantic Views
- Cortex Code (Snowsight sidebar)

Check with:
```sql
SELECT SYSTEM$BEHAVIOR_CHANGE_BUNDLE_STATUS('2024_08');
-- Cortex functions should be available by default in newer accounts
```

---

## Step 2: Run Environment Setup

Execute `sql/01_admin_environment_setup.sql`. This creates:

1. **Database:** `ENCOVA_TRAINING`
2. **Warehouse:** `ENCOVA_TRAINING_WH` (MEDIUM, admin-only for data loads)
3. **Schemas:**
   - `RAW_DATA` — Simulated landing zone (Bronze layer source)
4. **Role:** `ATTENDEE_ROLE` with all necessary grants

> **Per-attendee warehouses and schemas are NOT created here.** See Step 2b below.

---

## Step 2b: Provision Attendees (Day-of)

1. Populate `attendees.txt` with one first name per line (uppercase):
   ```
   LUKE
   ALEX
   JORDAN
   ```

2. Run the CoCo prompt from `prompts/admin_prompts/0.0_provision_attendees.md`.  
   This creates **per attendee**:
   - `TRAINING_<NAME>` — workspace schema in ENCOVA_TRAINING (owned by `ATTENDEE_ROLE`)

3. All attendees share the same user, role, and warehouse (`ENCOVA_TRAINING_WH` — LARGE, multi-cluster, up to 10). They differentiate by selecting their schema in Module 0.1.

### Critical Grants Needed

The training role needs:
- USAGE on database, all schemas, warehouse
- CREATE DYNAMIC TABLE, TABLE, VIEW, STAGE, STREAM, TASK, PIPE
- CREATE SEMANTIC VIEW, AGENT, MODEL, STREAMLIT, NOTEBOOK, PROCEDURE
- EXECUTE TASK on ACCOUNT
- SELECT on RAW_DATA tables
- SNOWFLAKE.CORTEX_USER database role
- CREATE INTEGRATION (or pre-create the storage integration)

---

## Step 3: Load Sample Data

Execute `sql/02_admin_sample_data.sql`. This creates synthetic insurance data:

| Table | Schema | ~Rows | Description |
|-------|--------|-------|-------------|
| CLAIMS_RAW | RAW_DATA | 50,000 | Raw claim submissions (simulates S3 ingest) |
| POLICIES | RAW_DATA | 10,000 | Policy master data |
| CLAIMANTS | RAW_DATA | 8,000 | Claimant/insured party info |
| AGENTS | RAW_DATA | 200 | Insurance agent directory |
| CLAIM_NOTES | RAW_DATA | 30,000 | Free-text adjuster notes (for AI enrichment) |

---

## Step 4: S3 External Stage Setup

### Option A: Real S3 Bucket (Preferred for Production Feel)

1. Create an S3 bucket (e.g., `encova-training-landing-zone`)
2. Upload sample JSON/CSV files (exported from RAW_DATA tables)
3. Create storage integration:

```sql
CREATE OR REPLACE STORAGE INTEGRATION encova_s3_integration
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<account-id>:role/encova-snowflake-role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://encova-training-landing-zone/');

-- Get the AWS IAM info for trust policy
DESC INTEGRATION encova_s3_integration;
```

4. Grant usage to training role:
```sql
GRANT USAGE ON INTEGRATION encova_s3_integration TO ROLE ATTENDEE_ROLE;
```

### Option B: Internal Stage Simulation (Simpler Setup)

If S3 setup is impractical, use an internal stage to simulate the landing zone:

```sql
CREATE OR REPLACE STAGE ENCOVA_TRAINING.RAW_DATA.LANDING_ZONE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Data is already in tables; attendees will create streams on those tables
-- to simulate the S3 → Bronze flow
```

**Recommendation:** For the lab, use Option B (internal stage + streams on RAW_DATA tables) to avoid S3 IAM complexity during a time-boxed session. Explain the real-world S3 pattern in slides.

---

## Step 5: Create Shared Attendee User

Since all attendees share a single Snowflake user:

```sql
CREATE USER IF NOT EXISTS ENCOVA_HOL_USER
    PASSWORD = '<temp-password>'
    DEFAULT_ROLE = ATTENDEE_ROLE
    DEFAULT_WAREHOUSE = ENCOVA_TRAINING_WH
    DEFAULT_NAMESPACE = ENCOVA_TRAINING
    MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE ATTENDEE_ROLE TO USER ENCOVA_HOL_USER;
```

Distribute this single login to all attendees. Each attendee then sets their own warehouse/schema context using Module 0.1.

---

## Step 6: Verify Everything Works

1. Switch to training role:
```sql
USE ROLE ATTENDEE_ROLE;
USE DATABASE ENCOVA_TRAINING;
USE SCHEMA TRAINING_<your_test_schema>;
USE WAREHOUSE ENCOVA_TRAINING_WH;
```

2. Run `sql/00_verify_grants.sql` — all checks should pass.

3. Test a Cortex AI function:
```sql
SELECT SNOWFLAKE.CORTEX.SENTIMENT('The claim was handled quickly and professionally.');
```

4. Test creating a Dynamic Table:
```sql
CREATE OR REPLACE DYNAMIC TABLE TEST_DT
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '1 hour'
AS SELECT COUNT(*) AS CNT FROM RAW_DATA.CLAIMS_RAW;

DROP DYNAMIC TABLE TEST_DT;
```

5. Open Cortex Code in Snowsight and confirm it's accessible.

---

## Step 7: Day-of Preparation

1. Have the lab repo cloned/available for screen sharing
2. Open Snowsight with ACCOUNTADMIN ready for troubleshooting
3. Have attendee credentials printed/ready to distribute
4. Pre-open the Cortex Code panel to show it immediately
5. Ensure warehouse is resumed: `ALTER WAREHOUSE ENCOVA_TRAINING_WH RESUME;`

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Insufficient privileges" on Cortex functions | `GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ATTENDEE_ROLE;` |
| Can't create Dynamic Tables | `GRANT CREATE DYNAMIC TABLE ON SCHEMA ... TO ROLE ...;` |
| Cortex Code not visible | Check account feature flags; may need Snowflake support |
| Streams not working | Ensure source tables have change tracking: `ALTER TABLE ... SET CHANGE_TRACKING = TRUE;` |
| Semantic View creation fails | `GRANT CREATE SEMANTIC VIEW ON SCHEMA ... TO ROLE ...;` |
| Agent creation fails | `GRANT CREATE AGENT ON SCHEMA ... TO ROLE ...;` |

---

## Timing Guide

| Task | Time |
|------|------|
| Account setup + grants | 15 min |
| Sample data load | 5 min |
| S3/Stage setup | 10 min (Option B) / 30 min (Option A) |
| End-to-end verification | 10 min |
| **Total admin prep** | **~40 min** |
