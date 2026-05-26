# Cortex Code Hands-On Lab — Prompt Guide

**Encova × Snowflake** | Copy-paste these prompts into Cortex Code as you go.

---

## Module 0: Setup

### 0.1 — Set Context

Run this SQL directly (replace `<NAME>` with your assigned first name):

```sql
USE ROLE ATTENDEE_ROLE;
USE DATABASE TRAINING_<NAME>;
USE SCHEMA BRONZE;
USE WAREHOUSE ENCOVA_TRAINING_WH;
```

### 0.2 — Pre-Flight Check

Run this to confirm everything is working:

```sql
SELECT 'ENCOVA_TRAINING.RAW_DATA' AS SOURCE, COUNT(*) AS FILE_COUNT
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
-- OR simply:
LIST @ENCOVA_TRAINING.RAW_DATA.DATA_LOADING_STAGE;
```

You should see CSV files in the stage. Your database (`TRAINING_<NAME>`) should have `BRONZE`, `SILVER`, and `GOLD` schemas.

---

## Module 1: Bronze Layer (Data Ingestion)

### 1.1 — Explore the Landing Zone (Stage)

```
First, confirm context:
USE ROLE ATTENDEE_ROLE;
USE DATABASE TRAINING_<NAME>;
USE SCHEMA BRONZE;
USE WAREHOUSE ENCOVA_TRAINING_WH;

List all files in the stage @ENCOVA_TRAINING.RAW_DATA.DATA_LOADING_STAGE and 
show me what's available. Then preview the first few rows of each CSV file 
in the stage so I can understand the data before loading it.
```

### 1.2 — Load Data from Stage into Bronze Schema

```
Use skill .cortex/skills/encova-context/SKILL.md. Load the CSV data from 
@ENCOVA_TRAINING.RAW_DATA.DATA_LOADING_STAGE into tables in my BRONZE schema.

Create these tables and COPY INTO them from the stage:
- CLAIMS_RAW (from @ENCOVA_TRAINING.RAW_DATA.DATA_LOADING_STAGE/claims_raw)
- POLICIES (from @ENCOVA_TRAINING.RAW_DATA.DATA_LOADING_STAGE/policies)
- CLAIMANTS (from @ENCOVA_TRAINING.RAW_DATA.DATA_LOADING_STAGE/claimants)
- AGENTS (from @ENCOVA_TRAINING.RAW_DATA.DATA_LOADING_STAGE/agents)
- CLAIM_NOTES (from @ENCOVA_TRAINING.RAW_DATA.DATA_LOADING_STAGE/claim_notes)

Use FILE_FORMAT with TYPE='CSV', SKIP_HEADER=1, FIELD_OPTIONALLY_ENCLOSED_BY='"', 
NULL_IF=('','NULL'). Use ON_ERROR='CONTINUE'.

After loading, show the row counts for each table to confirm success.
Enable CHANGE_TRACKING on CLAIMS_RAW, CLAIM_NOTES, and POLICIES 
(needed for Dynamic Tables later).
```

### 1.3 — Understand the Data

```
Show me 5 sample rows from BRONZE.CLAIMS_RAW and BRONZE.POLICIES. 
What are the join keys between them? Also show the distribution of 
CLAIM_STATUS and LOSS_TYPE in CLAIMS_RAW.
```

### 1.4 — Create the Bronze Dynamic Table

```
Use skill .cortex/skills/medallion-pipeline/SKILL.md. Create a Dynamic Table 
called CLAIMS_BRONZE in my BRONZE schema that refreshes every 1 minute using 
ENCOVA_TRAINING_WH.

It should read from BRONZE.CLAIMS_RAW and:
1. Include all source columns
2. Add a calculated column DAYS_TO_REPORT = DATEDIFF('day', DATE_OF_LOSS, DATE_REPORTED)
3. Add a validation flag HAS_VALID_ESTIMATE (TRUE if ESTIMATED_AMOUNT > 0)
4. Add BRONZE_LOADED_AT timestamp

This is the Bronze layer — minimal transformation, just parse and validate.
```

### 1.5 — Validate Bronze

```
Query my BRONZE.CLAIMS_BRONZE table: total row count, count by CLAIM_STATUS, 
and average DAYS_TO_REPORT. Confirm it matches my BRONZE.CLAIMS_RAW source counts.
```

---

## Module 2: Silver Layer (AI-Enriched Transforms)

### 2.1 — Create Silver Claims (with Cortex AI)

```
First, confirm context:
USE ROLE ATTENDEE_ROLE;
USE DATABASE TRAINING_<NAME>;
USE SCHEMA SILVER;
USE WAREHOUSE ENCOVA_TRAINING_WH;

Use skill .cortex/skills/medallion-pipeline/SKILL.md. Create a Dynamic Table 
called CLAIMS_SILVER in my SILVER schema with TARGET_LAG = '5 minutes' that:

1. Starts from BRONZE.CLAIMS_BRONZE as the base
2. LEFT JOIN BRONZE.POLICIES on POLICY_ID (get LINE_OF_BUSINESS, COVERAGE_TYPE, 
   PREMIUM_AMOUNT, DEDUCTIBLE_AMOUNT, COVERAGE_LIMIT, STATE, AGENCY_CODE)
3. LEFT JOIN BRONZE.CLAIMANTS on CLAIMANT_ID (get CLAIMANT_NAME, CLAIMANT_TYPE, INDUSTRY)

4. Add calculated fields:
   - TOTAL_INCURRED = PAID_AMOUNT + RESERVED_AMOUNT
   - PAYMENT_TO_ESTIMATE_RATIO 
   - EXCEEDS_COVERAGE (boolean: ESTIMATED_AMOUNT > COVERAGE_LIMIT)

5. AI ENRICHMENT (this is the key differentiator):
   - SNOWFLAKE.CORTEX.SENTIMENT(LOSS_DESCRIPTION) AS DESCRIPTION_SENTIMENT
   - SNOWFLAKE.CORTEX.CLASSIFY_TEXT(LOSS_DESCRIPTION, 
     ['Simple - straightforward damage claim', 
      'Moderate - requires investigation', 
      'Complex - multiple parties or litigation potential']) 
     → extract :label::VARCHAR AS AI_COMPLEXITY_CLASS
   - SNOWFLAKE.CORTEX.EXTRACT_ANSWER(LOSS_DESCRIPTION, 
     'What is the primary type of damage or injury described?')
     → extract [0]:answer::VARCHAR AS AI_EXTRACTED_DAMAGE_TYPE

Use COALESCE for nullable fields, NULLIF to avoid division by zero.
```

### 2.2 — Create Silver Claim Notes (AI Sentiment)

```
First, confirm context:
USE ROLE ATTENDEE_ROLE;
USE DATABASE TRAINING_<NAME>;
USE SCHEMA SILVER;
USE WAREHOUSE ENCOVA_TRAINING_WH;

Use skill .cortex/skills/medallion-pipeline/SKILL.md. Create a Dynamic Table 
called CLAIM_NOTES_SILVER in my SILVER schema with TARGET_LAG = '5 minutes' 
that reads from BRONZE.CLAIM_NOTES and adds:

1. SNOWFLAKE.CORTEX.SENTIMENT(NOTE_TEXT) AS NOTE_SENTIMENT
2. A SENTIMENT_CATEGORY column:
   - < -0.3 → 'NEGATIVE'
   - > 0.3 → 'POSITIVE'  
   - else → 'NEUTRAL'
3. SNOWFLAKE.CORTEX.EXTRACT_ANSWER(NOTE_TEXT, 
   'What action or next step is recommended?')[0]:answer::VARCHAR 
   AS AI_EXTRACTED_ACTION
```

### 2.3 — Validate Silver

```
Show me the distribution of AI_COMPLEXITY_CLASS in SILVER.CLAIMS_SILVER with 
average estimated amounts. Also show the sentiment distribution from 
SILVER.CLAIM_NOTES_SILVER. How does sentiment correlate with note type?
```

---

## Module 3: Gold Layer (Business Metrics)

### 3.1 — Create Claims Gold (Denormalized Summary)

```
First, confirm context:
USE ROLE ATTENDEE_ROLE;
USE DATABASE TRAINING_<NAME>;
USE SCHEMA GOLD;
USE WAREHOUSE ENCOVA_TRAINING_WH;

Use skill .cortex/skills/medallion-pipeline/SKILL.md. Create a Dynamic Table 
called CLAIMS_GOLD in my GOLD schema with TARGET_LAG = '10 minutes' that:

1. Starts from SILVER.CLAIMS_SILVER
2. LEFT JOINs an aggregation of SILVER.CLAIM_NOTES_SILVER by CLAIM_ID:
   - TOTAL_NOTES (count)
   - AVG_NOTE_SENTIMENT
   - NEGATIVE_NOTE_COUNT
   - LAST_NOTE_DATE
   - NOTE_TYPES_USED (LISTAGG of distinct note types)

3. Adds a RISK_SCORE (0-100) based on:
   - FRAUD_INDICATOR = SUSPICIOUS/CONFIRMED → 90
   - LITIGATION_FLAG + HIGH severity → 80
   - HIGH severity + ESTIMATED > 100K → 70
   - 3+ negative notes → 60
   - AI_COMPLEXITY_CLASS = Complex → 50
   - MEDIUM severity → 30
   - else → 10

This is the one-row-per-claim Gold table for analytics.
```

### 3.2 — Create Monthly Metrics Gold

```
First, confirm context:
USE ROLE ATTENDEE_ROLE;
USE DATABASE TRAINING_<NAME>;
USE SCHEMA GOLD;
USE WAREHOUSE ENCOVA_TRAINING_WH;

Use skill .cortex/skills/encova-context/SKILL.md. Create a Dynamic Table called 
CLAIMS_METRICS_MONTHLY in my GOLD schema with TARGET_LAG = '1 hour' that 
aggregates GOLD.CLAIMS_GOLD by:
- LOSS_MONTH (DATE_TRUNC month on DATE_OF_LOSS)
- LINE_OF_BUSINESS
- LOSS_LOCATION_STATE
- SEVERITY

Include: CLAIM_COUNT, TOTAL_ESTIMATED, TOTAL_PAID, TOTAL_INCURRED, 
AVG_CLAIM_AMOUNT, AVG_DAYS_TO_REPORT, SUSPICIOUS_COUNT, LITIGATION_COUNT, 
WEATHER_CLAIMS count, AVG_SENTIMENT, COMPLEX_CLAIMS count.
```

### 3.3 — Validate Gold & View Pipeline Lineage

```
Show me: total claims in GOLD.CLAIMS_GOLD, top 5 states by total incurred 
amount, and the risk score distribution. Also show me the full pipeline lineage 
(what feeds into what) across BRONZE → SILVER → GOLD.
```

---

## Module 4: Semantic View + Cortex Agent

### 4.1 — Create Semantic View

```
First, confirm context:
USE ROLE ATTENDEE_ROLE;
USE DATABASE TRAINING_<NAME>;
USE SCHEMA GOLD;
USE WAREHOUSE ENCOVA_TRAINING_WH;

Use skill .cortex/skills/medallion-pipeline/SKILL.md. Create a Semantic View 
called CLAIMS_ANALYTICS_SV in my GOLD schema over GOLD.CLAIMS_GOLD.

Include key columns with descriptions and synonyms. Define these metrics:
- total_claims (COUNT)
- total_incurred_amount (SUM TOTAL_INCURRED)
- average_claim_amount (AVG ESTIMATED_AMOUNT)
- fraud_rate (AVG of FRAUD_INDICATOR != 'NONE')
- avg_days_to_report
- litigation_rate
- avg_risk_score
- closure_rate
- weather_claim_pct

Filters: LINE_OF_BUSINESS, LOSS_LOCATION_STATE, SEVERITY, CLAIM_STATUS, LOSS_TYPE
```

### 4.2 — Create Cortex Agent

Replace `<NAME>` with your assigned first name:

```
First, confirm context:
USE ROLE ATTENDEE_ROLE;
USE DATABASE TRAINING_<NAME>;
USE SCHEMA GOLD;
USE WAREHOUSE ENCOVA_TRAINING_WH;

Use skill .cortex/skills/encova-context/SKILL.md. Create a Cortex Agent called 
CLAIMS_ANALYTICS_AGENT in my GOLD schema. Use claude-3-5-sonnet. 
Add an ANALYST_TOOL pointing to my CLAIMS_ANALYTICS_SV semantic view 
(fully qualified: TRAINING_<NAME>.GOLD.CLAIMS_ANALYTICS_SV).
System prompt: "You are a claims analytics assistant for Encova Insurance. 
Help adjusters, managers, and executives understand claims data. Provide 
specific numbers, format currency with $ and commas, percentages to 1 decimal."
```

### 4.3 — Test the Agent

```
Query my CLAIMS_ANALYTICS_AGENT: What is the total claims volume and 
incurred amount by line of business?
```

```
Query my CLAIMS_ANALYTICS_AGENT: Which states have the highest fraud rate?
```

```
Query my CLAIMS_ANALYTICS_AGENT: How does claim severity correlate with 
average days to report? Are high severity claims reported faster?
```

---

## Teardown (Optional)

Uncomment and run what you want to clean up:

```sql
-- Gold layer
-- DROP DYNAMIC TABLE IF EXISTS GOLD.CLAIMS_METRICS_MONTHLY;
-- DROP DYNAMIC TABLE IF EXISTS GOLD.CLAIMS_GOLD;
-- DROP AGENT IF EXISTS GOLD.CLAIMS_ANALYTICS_AGENT;
-- DROP SEMANTIC VIEW IF EXISTS GOLD.CLAIMS_ANALYTICS_SV;

-- Silver layer
-- DROP DYNAMIC TABLE IF EXISTS SILVER.CLAIM_NOTES_SILVER;
-- DROP DYNAMIC TABLE IF EXISTS SILVER.CLAIMS_SILVER;

-- Bronze layer
-- DROP DYNAMIC TABLE IF EXISTS BRONZE.CLAIMS_BRONZE;
-- DROP TABLE IF EXISTS BRONZE.CLAIMS_RAW;
-- DROP TABLE IF EXISTS BRONZE.POLICIES;
-- DROP TABLE IF EXISTS BRONZE.CLAIMANTS;
-- DROP TABLE IF EXISTS BRONZE.AGENTS;
-- DROP TABLE IF EXISTS BRONZE.CLAIM_NOTES;
```
