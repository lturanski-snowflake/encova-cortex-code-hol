/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Module 2 Reference: Silver Layer Transforms (Dynamic Tables + Cortex AI)
    
    Pattern: Bronze → Dynamic Tables with AI enrichment → Silver
    
    Only 2 AI functions per table (AI_CLASSIFY + AI_EXTRACT):
    - AI_CLASSIFY   — classify claims by complexity, notes by sentiment
    - AI_EXTRACT    — extract multiple structured fields in one call
    
    CTE pattern used to avoid duplicate AI calls (each call = $$$).
*/

--------------------------------------------------------------------
-- Silver Layer: Enriched Claims with AI-Derived Features
-- 5K rows × 2 AI calls = 10K LLM inferences (~2-3 min)
--------------------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE CLAIMS_SILVER
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '5 minutes'
    COMMENT = 'Silver layer: claims enriched with policy data, claimant info, and AI features'
AS
WITH base AS (
    SELECT
        c.CLAIM_ID,
        c.CLAIM_NUMBER,
        c.POLICY_ID,
        c.CLAIMANT_ID,
        p.POLICY_NUMBER,
        p.LINE_OF_BUSINESS,
        p.COVERAGE_TYPE,
        p.PREMIUM_AMOUNT,
        p.DEDUCTIBLE_AMOUNT,
        p.COVERAGE_LIMIT,
        p.STATE AS POLICY_STATE,
        p.AGENCY_CODE,
        cl.CLAIMANT_NAME,
        cl.CLAIMANT_TYPE,
        cl.INDUSTRY AS CLAIMANT_INDUSTRY,
        c.DATE_OF_LOSS,
        c.DATE_REPORTED,
        c.CLAIM_STATUS,
        c.LOSS_TYPE,
        c.LOSS_DESCRIPTION,
        c.LOSS_LOCATION_STATE,
        c.LOSS_LOCATION_CITY,
        c.ESTIMATED_AMOUNT,
        c.PAID_AMOUNT,
        c.RESERVED_AMOUNT,
        c.ADJUSTER_ID,
        c.FRAUD_INDICATOR,
        c.SEVERITY,
        c.CAUSE_OF_LOSS,
        c.WEATHER_RELATED,
        c.LITIGATION_FLAG,
        c.DAYS_TO_REPORT,
        COALESCE(c.PAID_AMOUNT, 0) + COALESCE(c.RESERVED_AMOUNT, 0) AS TOTAL_INCURRED,
        CASE 
            WHEN c.ESTIMATED_AMOUNT > 0 
            THEN ROUND(c.PAID_AMOUNT / NULLIF(c.ESTIMATED_AMOUNT, 0) * 100, 1)
            ELSE 0
        END AS PAYMENT_TO_ESTIMATE_RATIO,
        CASE
            WHEN c.ESTIMATED_AMOUNT > p.COVERAGE_LIMIT THEN TRUE
            ELSE FALSE
        END AS EXCEEDS_COVERAGE,
        -- AI call 1: Classify complexity
        AI_CLASSIFY(
            c.LOSS_DESCRIPTION,
            ['Simple - straightforward damage claim', 
             'Moderate - requires investigation', 
             'Complex - multiple parties or litigation potential']
        ):labels[0]::VARCHAR AS AI_COMPLEXITY_CLASS,
        -- AI call 2: Extract damage type + sentiment in a single call
        AI_EXTRACT(
            c.LOSS_DESCRIPTION,
            {'damage_type': 'What is the primary type of damage or injury?',
             'sentiment': 'Is the overall tone positive, negative, or neutral?'}
        ) AS _extracted
    FROM BRONZE.CLAIMS_RAW c
    LEFT JOIN BRONZE.POLICIES p ON c.POLICY_ID = p.POLICY_ID
    LEFT JOIN BRONZE.CLAIMANTS cl ON c.CLAIMANT_ID = cl.CLAIMANT_ID
)
SELECT
    *,
    _extracted:response:damage_type::VARCHAR AS AI_EXTRACTED_DAMAGE_TYPE,
    _extracted:response:sentiment::VARCHAR AS DESCRIPTION_SENTIMENT,
    CURRENT_TIMESTAMP() AS SILVER_LOADED_AT
FROM base;

-- Manual refresh after creation
ALTER DYNAMIC TABLE SILVER.CLAIMS_SILVER REFRESH;

--------------------------------------------------------------------
-- Silver Layer: AI-Enriched Claim Notes
-- 3K rows × 2 AI calls = 6K LLM inferences (~1-2 min)
-- CTE avoids calling each AI function twice
--------------------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE CLAIM_NOTES_SILVER
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '5 minutes'
    COMMENT = 'Silver layer: claim notes with sentiment classification and action extraction'
AS
WITH ai_enriched AS (
    SELECT
        n.NOTE_ID,
        n.CLAIM_ID,
        n.NOTE_DATE,
        n.NOTE_AUTHOR,
        n.NOTE_TYPE,
        n.NOTE_TEXT,
        AI_CLASSIFY(n.NOTE_TEXT, ['Positive', 'Negative', 'Neutral']):labels[0]::VARCHAR AS _sentiment,
        AI_EXTRACT(n.NOTE_TEXT, {'action': 'What action or next step is recommended?'}):response:action::VARCHAR AS _action
    FROM BRONZE.CLAIM_NOTES n
)
SELECT
    NOTE_ID,
    CLAIM_ID,
    NOTE_DATE,
    NOTE_AUTHOR,
    NOTE_TYPE,
    NOTE_TEXT,
    _sentiment AS NOTE_SENTIMENT,
    CASE _sentiment
        WHEN 'Negative' THEN 'NEGATIVE'
        WHEN 'Positive' THEN 'POSITIVE'
        ELSE 'NEUTRAL'
    END AS SENTIMENT_CATEGORY,
    _action AS AI_EXTRACTED_ACTION,
    CURRENT_TIMESTAMP() AS SILVER_LOADED_AT
FROM ai_enriched;

-- Manual refresh after creation
ALTER DYNAMIC TABLE SILVER.CLAIM_NOTES_SILVER REFRESH;

--------------------------------------------------------------------
-- Verify Silver Layer
--------------------------------------------------------------------
SELECT COUNT(*) AS SILVER_CLAIMS_COUNT FROM CLAIMS_SILVER;

SELECT 
    AI_COMPLEXITY_CLASS, 
    COUNT(*) AS CLAIM_COUNT,
    ROUND(AVG(ESTIMATED_AMOUNT), 2) AS AVG_ESTIMATE
FROM CLAIMS_SILVER 
GROUP BY AI_COMPLEXITY_CLASS
ORDER BY CLAIM_COUNT DESC;

SELECT 
    AI_EXTRACTED_DAMAGE_TYPE,
    COUNT(*) AS CLAIM_COUNT
FROM CLAIMS_SILVER
WHERE AI_EXTRACTED_DAMAGE_TYPE IS NOT NULL
GROUP BY AI_EXTRACTED_DAMAGE_TYPE
ORDER BY CLAIM_COUNT DESC
LIMIT 15;

SELECT 
    SENTIMENT_CATEGORY, 
    COUNT(*) AS NOTE_COUNT 
FROM CLAIM_NOTES_SILVER 
GROUP BY SENTIMENT_CATEGORY;
