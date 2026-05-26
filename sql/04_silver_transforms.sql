/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Module 2 Reference: Silver Layer Transforms (Dynamic Tables + Cortex AI)
    
    Pattern: Bronze → Dynamic Tables with AI enrichment → Silver
    
    ONE AI function call on CLAIMS_SILVER only (AI_EXTRACT).
    CLAIM_NOTES_SILVER has no AI calls — just a clean pass-through.
    This keeps refresh under 2-3 minutes for 5K rows.
*/

--------------------------------------------------------------------
-- Silver Layer: Enriched Claims with AI-Derived Features
-- 5K rows × 1 AI call (AI_EXTRACT) = 5K LLM inferences (~1-2 min)
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
        -- Single AI call: extract damage type, sentiment, and complexity
        AI_EXTRACT(
            c.LOSS_DESCRIPTION,
            {'damage_type': 'What is the primary type of damage or injury?',
             'sentiment': 'Is the overall tone positive, negative, or neutral? Reply with one word.',
             'complexity': 'Is this claim simple, moderate, or complex? Reply with one word.'}
        ) AS _extracted
    FROM BRONZE.CLAIMS_RAW c
    LEFT JOIN BRONZE.POLICIES p ON c.POLICY_ID = p.POLICY_ID
    LEFT JOIN BRONZE.CLAIMANTS cl ON c.CLAIMANT_ID = cl.CLAIMANT_ID
)
SELECT
    * EXCLUDE (_extracted),
    _extracted:response:damage_type::VARCHAR AS AI_EXTRACTED_DAMAGE_TYPE,
    _extracted:response:sentiment::VARCHAR AS DESCRIPTION_SENTIMENT,
    _extracted:response:complexity::VARCHAR AS AI_COMPLEXITY_CLASS,
    CURRENT_TIMESTAMP() AS SILVER_LOADED_AT
FROM base;

-- Manual refresh after creation
ALTER DYNAMIC TABLE SILVER.CLAIMS_SILVER REFRESH;

--------------------------------------------------------------------
-- Silver Layer: Claim Notes (no AI — simple pass-through)
-- Fast: no LLM calls, just reshaping
--------------------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE CLAIM_NOTES_SILVER
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '5 minutes'
    COMMENT = 'Silver layer: claim notes with derived sentiment from keywords'
AS
SELECT
    n.NOTE_ID,
    n.CLAIM_ID,
    n.NOTE_DATE,
    n.NOTE_AUTHOR,
    n.NOTE_TYPE,
    n.NOTE_TEXT,
    -- Simple keyword-based sentiment (no AI call — instant)
    CASE 
        WHEN LOWER(n.NOTE_TEXT) LIKE '%suspicious%' OR LOWER(n.NOTE_TEXT) LIKE '%denied%' 
             OR LOWER(n.NOTE_TEXT) LIKE '%frustrated%' OR LOWER(n.NOTE_TEXT) LIKE '%fraud%' 
        THEN 'NEGATIVE'
        WHEN LOWER(n.NOTE_TEXT) LIKE '%approved%' OR LOWER(n.NOTE_TEXT) LIKE '%satisfact%' 
             OR LOWER(n.NOTE_TEXT) LIKE '%completed%' OR LOWER(n.NOTE_TEXT) LIKE '%resolved%' 
        THEN 'POSITIVE'
        ELSE 'NEUTRAL'
    END AS SENTIMENT_CATEGORY,
    CURRENT_TIMESTAMP() AS SILVER_LOADED_AT
FROM BRONZE.CLAIM_NOTES n;

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
