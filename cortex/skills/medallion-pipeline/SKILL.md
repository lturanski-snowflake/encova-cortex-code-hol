---
name: medallion-pipeline
title: Medallion Pipeline Patterns
summary: Provides Snowflake-native patterns for building Medallion Architecture with Dynamic Tables, Streams, and Cortex AI.
description: >-
  Use when building pipeline layers (Bronze, Silver, Gold), creating Dynamic Tables
  with AI enrichment, setting up Streams, or designing Semantic Views.
  Triggers: medallion, pipeline, bronze, silver, gold, dynamic table, stream, cortex ai,
  sentiment, classify, extract, semantic view, agent.
tools:
  - snowflake_sql_execute
  - snowflake_object_search
prompt: "$medallion-pipeline Create a Silver layer Dynamic Table with AI enrichment"
language: en
status: Published
author: Luke Turanski
type: snowflake
---

# Medallion Pipeline Patterns

## When to Use
- Creating any layer of the Medallion Architecture
- Building Dynamic Tables with Cortex AI functions
- Setting up Streams for incremental processing
- Designing Gold layer aggregations
- Creating Semantic Views or Cortex Agents

# Instructions

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  S3 Landing Zone (External Stage / Snowpipe)                     │
│  OR Internal Stage (simulated with Streams on RAW_DATA)          │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  BRONZE LAYER (Dynamic Table, TARGET_LAG = '1 minute')           │
│  • Parse raw data (JSON → columns)                               │
│  • Basic validation (null checks, type casting)                  │
│  • Add ingestion metadata (timestamps, source file)              │
│  • Light deduplication                                           │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  SILVER LAYER (Dynamic Table, TARGET_LAG = '5 minutes')          │
│  • Join with reference/dimension tables                          │
│  • Apply business rules and calculations                         │
│  • Cortex AI enrichment (SENTIMENT, CLASSIFY, EXTRACT)           │
│  • Data quality flags                                            │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  GOLD LAYER (Dynamic Table, TARGET_LAG = '10 minutes' to '1 hr') │
│  • Aggregated KPIs by dimensions                                 │
│  • Denormalized summaries                                        │
│  • Performance metrics                                           │
│  • Ready for Semantic Views / BI tools                           │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  ANALYTICS LAYER                                                 │
│  • Semantic View (natural language interface)                     │
│  • Cortex Agent (conversational querying)                        │
│  • Streamlit App (visual dashboards)                             │
└─────────────────────────────────────────────────────────────────┘
```

## Bronze Layer Pattern

```sql
CREATE OR REPLACE DYNAMIC TABLE <NAME>_BRONZE
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '1 minute'
    COMMENT = 'Bronze layer: parsed and validated <domain>'
AS
SELECT
    -- Core fields
    <columns>,
    
    -- Validation columns
    CASE WHEN <required_field> IS NULL THEN FALSE ELSE TRUE END AS IS_VALID,
    
    -- Metadata
    CURRENT_TIMESTAMP() AS BRONZE_LOADED_AT
FROM BRONZE.<source_table>;
```

**Key principles:**
- Minimal transformation — just parse and validate
- Keep all source columns (don't drop anything yet)
- Add validation flags but don't filter out bad records
- Fast refresh (1 minute lag)

## Silver Layer Pattern (with Cortex AI)

```sql
CREATE OR REPLACE DYNAMIC TABLE <NAME>_SILVER
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '5 minutes'
    COMMENT = 'Silver layer: enriched with joins and AI features'
AS
SELECT
    -- From Bronze
    b.<columns>,
    
    -- Joined reference data
    ref.FIELD AS REF_FIELD,
    
    -- Calculated fields
    DATEDIFF('day', b.START_DATE, b.END_DATE) AS DURATION_DAYS,
    
    -- AI ENRICHMENT: Sentiment
    SNOWFLAKE.CORTEX.SENTIMENT(b.TEXT_COLUMN) AS TEXT_SENTIMENT,
    
    -- AI ENRICHMENT: Classification
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
        b.TEXT_COLUMN,
        ['Category A', 'Category B', 'Category C']
    ):label::VARCHAR AS AI_CATEGORY,
    
    -- AI ENRICHMENT: Entity Extraction
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
        b.TEXT_COLUMN,
        'What is the key finding?'
    )[0]:answer::VARCHAR AS AI_EXTRACTED_FINDING,
    
    CURRENT_TIMESTAMP() AS SILVER_LOADED_AT
FROM <NAME>_BRONZE b
LEFT JOIN BRONZE.<ref_table> ref ON b.FK = ref.PK;
```

**Key principles:**
- Join with dimension/reference tables
- Apply Cortex AI functions on text fields
- Add business logic calculations
- 5 minute lag (AI functions have compute cost)

## Gold Layer Pattern

```sql
CREATE OR REPLACE DYNAMIC TABLE <NAME>_GOLD
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '10 minutes'
    COMMENT = 'Gold layer: aggregated business metrics'
AS
SELECT
    -- Dimensions
    DIMENSION_1,
    DIMENSION_2,
    DATE_TRUNC('month', DATE_FIELD) AS PERIOD,
    
    -- Measures
    COUNT(*) AS RECORD_COUNT,
    SUM(AMOUNT_FIELD) AS TOTAL_AMOUNT,
    ROUND(AVG(AMOUNT_FIELD), 2) AS AVG_AMOUNT,
    
    -- AI-derived aggregates
    ROUND(AVG(TEXT_SENTIMENT), 3) AS AVG_SENTIMENT,
    SUM(CASE WHEN AI_CATEGORY = 'Category A' THEN 1 ELSE 0 END) AS CATEGORY_A_COUNT,
    
    CURRENT_TIMESTAMP() AS GOLD_LOADED_AT
FROM <NAME>_SILVER
GROUP BY 1, 2, 3;
```

## Stream Pattern (for CDC awareness)

```sql
-- Create stream to track changes on source table
CREATE OR REPLACE STREAM <NAME>_STREAM
    ON TABLE RAW_DATA.<table>
    SHOW_INITIAL_ROWS = TRUE
    COMMENT = 'Tracks new/changed records in <table>';

-- Check stream has data
SELECT SYSTEM$STREAM_HAS_DATA('<NAME>_STREAM');
```

**Note:** When using Dynamic Tables, you typically don't need explicit Streams — 
Dynamic Tables handle incremental refresh automatically. Streams are shown here for 
educational purposes and for cases where you want explicit CDC visibility.

## Semantic View Pattern

```sql
CREATE OR REPLACE SEMANTIC VIEW <NAME>_SV
    COMMENT = 'description'
AS SEMANTIC MODEL
    NAME = 'Model Name'
    DESCRIPTION = 'What this model covers'
    ENTITIES = (
        ENTITY <entity_name>
            TABLE = <GOLD_TABLE>
            PRIMARY_KEY = (<PK_COLUMN>)
            COLUMNS = (
                COLUMN_NAME DESCRIPTION = 'description' SYNONYMS = ('alias1', 'alias2')
            )
    )
    METRICS = (
        METRIC metric_name
            EXPRESSION = 'AGG(entity.COLUMN)'
            DESCRIPTION = 'what it measures'
    )
    FILTERS = (
        FILTER filter_name
            EXPRESSION = 'entity.COLUMN'
            DESCRIPTION = 'what it filters'
    );
```

## Cortex Agent Pattern

```sql
CREATE OR REPLACE AGENT <NAME>_AGENT
    COMMENT = 'description'
    MODEL = 'claude-3-5-sonnet'
    SYSTEM_PROMPT = 'You are a <domain> assistant. Provide specific numbers, format currency with $ and commas, percentages to 1 decimal.'
    TOOLS = (
        ANALYST_TOOL(
            SEMANTIC_VIEW => '<SEMANTIC_VIEW_NAME>'
        )
    );
```

## Cortex AI Function Reference

| Function | Input | Output | Use Case |
|----------|-------|--------|----------|
| `SENTIMENT(text)` | VARCHAR | FLOAT (-1 to 1) | Customer satisfaction, urgency detection |
| `CLASSIFY_TEXT(text, categories)` | VARCHAR, ARRAY | OBJECT {label, score} | Auto-categorization, routing |
| `EXTRACT_ANSWER(text, question)` | VARCHAR, VARCHAR | ARRAY of objects | Entity extraction, key info pull |
| `SUMMARIZE(text)` | VARCHAR | VARCHAR | Long text → concise summary |
| `COMPLETE(model, prompt)` | VARCHAR, VARCHAR | VARCHAR | Custom AI tasks, reasoning |

## Anti-Patterns to Avoid

1. **Don't** put AI functions in Gold layer (expensive to re-aggregate)
2. **Don't** use Tasks + Stored Procedures when Dynamic Tables suffice
3. **Don't** set TARGET_LAG too aggressively (costs compute credits)
4. **Don't** forget COALESCE on nullable joins
5. **Don't** skip the Bronze layer (always have a parsed intermediary)

# Examples

## Example: Full pipeline prompt
User: $medallion-pipeline Create a Silver Dynamic Table that enriches claims with AI sentiment and classification
Assistant: Creates CLAIMS_SILVER with SENTIMENT on LOSS_DESCRIPTION, CLASSIFY_TEXT for complexity, and joins to POLICIES and CLAIMANTS
