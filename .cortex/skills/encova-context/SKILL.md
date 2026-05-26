---
name: encova-context
title: Encova Lab Context
summary: Sets company context, environment, and table schemas for the Encova Cortex Code Medallion Architecture lab.
description: >-
  Use for ALL prompts during the Encova hands-on lab. Provides company context,
  Snowflake environment details, table schemas, medallion architecture patterns,
  and coding conventions.
  Triggers: encova, claim, policy, insurance, medallion, bronze, silver, gold, training, lab.
  Do NOT use for general Snowflake questions unrelated to this lab.
tools:
  - snowflake_sql_execute
  - snowflake_object_search
prompt: "$encova-context Explore the claims tables and describe the medallion architecture"
language: en
status: Published
author: Luke Turanski
type: snowflake
---

# Encova Lab Context

## When to Use
- Any prompt during the Encova Cortex Code hands-on lab
- Working with ENCOVA_TRAINING database objects
- Building medallion architecture pipelines on insurance claims data
- Creating Dynamic Tables, Streams, Semantic Views, or Agents

## What This Skill Provides
Company context, environment configuration, table schemas, medallion architecture patterns, and coding conventions for the Encova × Snowflake hands-on lab.

# Instructions

## Company Context

Encova Insurance is a mutual insurance group providing property and casualty insurance products to businesses and individuals across the Midwest and Southeast United States. Key lines include Commercial Property, General Liability, Workers Compensation, Commercial Auto, and Business Owners Policies.

The lab focuses on building a modern Medallion Architecture data pipeline using Snowflake-native features and AI capabilities, demonstrating how Cortex Code accelerates data engineering work.

## Environment

**Always use these settings:**
- **Role:** ATTENDEE_ROLE
- **Database:** TRAINING_<NAME> (your personal database)
- **Schemas:** BRONZE, SILVER, GOLD (one per layer)
- **Warehouse:** ENCOVA_TRAINING_WH (shared, multi-cluster, auto-scales to 10)

**CRITICAL: Always execute `USE ROLE ATTENDEE_ROLE` before creating ANY objects.
Never create objects as ACCOUNTADMIN. All Dynamic Tables, Streams, views, Semantic Views, 
Agents, and procedures MUST be owned by ATTENDEE_ROLE.**

## Database & Schema Layout

**Shared source** (stage with raw CSV files):
- `ENCOVA_TRAINING.RAW_DATA` — DATA_LOADING_STAGE with CSV files

**Your personal database** (`TRAINING_<NAME>`):
- `BRONZE` schema — raw tables loaded from stage + CLAIMS_BRONZE Dynamic Table
- `SILVER` schema — AI-enriched Dynamic Tables (CLAIMS_SILVER, CLAIM_NOTES_SILVER)
- `GOLD` schema — aggregated metrics, Semantic View, Cortex Agent

## Medallion Architecture

```
ENCOVA_TRAINING.RAW_DATA.DATA_LOADING_STAGE (CSV files)
    ↓ COPY INTO
TRAINING_<NAME>.BRONZE (raw tables + CLAIMS_BRONZE Dynamic Table)
    ↓ Dynamic Tables
TRAINING_<NAME>.SILVER (joined, enriched with Cortex AI)
    ↓ Dynamic Tables
TRAINING_<NAME>.GOLD (aggregated metrics, Semantic View, Agent)
```

## Tables (loaded into BRONZE schema from stage)

| Table | ~Rows | Purpose |
|-------|-------|---------|
| CLAIMS_RAW | 50,000 | Primary claims data |
| POLICIES | 10,000 | Policy master data |
| CLAIMANTS | 8,000 | Claimant/insured party info |
| AGENTS | 200 | Insurance agent directory |
| CLAIM_NOTES | 30,000 | Free-text adjuster notes (for AI) |

### Key Columns — CLAIMS_RAW
CLAIM_ID (PK), POLICY_ID (FK), CLAIMANT_ID (FK), CLAIM_NUMBER, DATE_OF_LOSS, DATE_REPORTED, CLAIM_STATUS (OPEN | UNDER_INVESTIGATION | APPROVED | PAID | CLOSED | DENIED), LOSS_TYPE, LOSS_DESCRIPTION (text), LOSS_LOCATION_STATE, LOSS_LOCATION_CITY, ESTIMATED_AMOUNT, PAID_AMOUNT, RESERVED_AMOUNT, ADJUSTER_ID, FRAUD_INDICATOR (NONE | SUSPICIOUS | CONFIRMED), SEVERITY (HIGH | MEDIUM | LOW), CAUSE_OF_LOSS, WEATHER_RELATED (BOOLEAN), LITIGATION_FLAG (BOOLEAN)

### Key Columns — POLICIES
POLICY_ID (PK), POLICY_NUMBER, POLICYHOLDER_NAME, LINE_OF_BUSINESS (Commercial Property | General Liability | Workers Compensation | Commercial Auto | Business Owners Policy), COVERAGE_TYPE, EFFECTIVE_DATE, EXPIRATION_DATE, PREMIUM_AMOUNT, DEDUCTIBLE_AMOUNT, COVERAGE_LIMIT, STATE, AGENCY_CODE, STATUS

### Key Columns — CLAIMANTS
CLAIMANT_ID (PK), CLAIMANT_NAME, CLAIMANT_TYPE (Individual | Business | Third Party), BUSINESS_NAME, INDUSTRY, ADDRESS_STATE, ADDRESS_CITY

### Key Columns — CLAIM_NOTES
NOTE_ID (PK), CLAIM_ID (FK), NOTE_DATE, NOTE_AUTHOR, NOTE_TYPE (Initial Assessment | Investigation Update | Payment Processing | Claimant Communication | Closure Summary), NOTE_TEXT (free text — AI target)

### Relationships
- CLAIMS_RAW.POLICY_ID → POLICIES.POLICY_ID
- CLAIMS_RAW.CLAIMANT_ID → CLAIMANTS.CLAIMANT_ID
- CLAIM_NOTES.CLAIM_ID → CLAIMS_RAW.CLAIM_ID
- POLICIES.AGENCY_CODE → AGENTS.AGENCY_CODE

## Conventions

1. Your database is `TRAINING_<NAME>` with schemas: BRONZE, SILVER, GOLD
2. **BRONZE schema:** Raw tables + CLAIMS_BRONZE DT (reads from BRONZE.CLAIMS_RAW)
3. **SILVER schema:** Enriched DTs (reads from BRONZE.* tables, cross-schema within your DB)
4. **GOLD schema:** Aggregated DTs + Semantic View + Agent (reads from SILVER.*)
5. Use ENCOVA_TRAINING_WH for all compute
6. Use Dynamic Tables for all layer transitions (not Tasks + SPs)
7. Embed Cortex AI Functions directly in Silver layer Dynamic Tables
8. Name objects clearly by layer: `CLAIMS_BRONZE`, `CLAIMS_SILVER`, `CLAIMS_GOLD`

## Cortex AI Functions Available

Use these in Silver layer transformations:
- `SNOWFLAKE.CORTEX.SENTIMENT(text)` — Returns -1.0 to 1.0
- `SNOWFLAKE.CORTEX.CLASSIFY_TEXT(text, categories_array)` — Returns label + score
- `SNOWFLAKE.CORTEX.EXTRACT_ANSWER(text, question)` — Returns answer array
- `SNOWFLAKE.CORTEX.SUMMARIZE(text)` — Returns summary string
- `SNOWFLAKE.CORTEX.COMPLETE(model, prompt)` — General LLM completion

## Best Practices
- Use COALESCE for nullable aggregation results
- Use NULLIF to prevent division-by-zero in ratios
- Use CREATE OR REPLACE for iterative development
- Use LEFT JOIN when joining to optional reference tables
- Set appropriate TARGET_LAG for each Dynamic Table layer:
  - Bronze: 1 minute (near real-time ingest)
  - Silver: 5 minutes (AI enrichment has compute cost)
  - Gold: 10 minutes to 1 hour (aggregations)
- Keep Cortex AI calls in Silver layer (not Gold) to avoid redundant processing

# Examples

## Example 1: Set context
User: $encova-context Set up my session for the lab
Assistant: Executes USE ROLE/DATABASE/SCHEMA/WAREHOUSE statements

## Example 2: Explore data
User: $encova-context Show me the claims table structure and distribution by loss type
Assistant: Runs DESCRIBE TABLE and aggregation query

## Example 3: Create Bronze layer
User: $encova-context Create a Bronze Dynamic Table for claims
Assistant: Creates CLAIMS_BRONZE with validation columns and appropriate TARGET_LAG
