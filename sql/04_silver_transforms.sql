/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Module 2 Reference: Silver Layer Transforms (Dynamic Tables + Cortex AI)
    
    Pattern: Bronze → Dynamic Tables with AI enrichment → Silver
    
    This is where the new AISQL Functions shine:
    - AI_SENTIMENT  — sentiment analysis on claims and notes
    - AI_CLASSIFY   — classify claims by complexity
    - AI_EXTRACT    — extract structured fields from free text
*/

--------------------------------------------------------------------
-- Silver Layer: Enriched Claims with AI-Derived Features
--------------------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE CLAIMS_SILVER
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '5 minutes'
    COMMENT = 'Silver layer: claims enriched with policy data, claimant info, and AI features'
AS
SELECT
    c.CLAIM_ID,
    c.CLAIM_NUMBER,
    c.POLICY_ID,
    c.CLAIMANT_ID,
    
    -- Policy context
    p.POLICY_NUMBER,
    p.LINE_OF_BUSINESS,
    p.COVERAGE_TYPE,
    p.PREMIUM_AMOUNT,
    p.DEDUCTIBLE_AMOUNT,
    p.COVERAGE_LIMIT,
    p.STATE AS POLICY_STATE,
    p.AGENCY_CODE,
    
    -- Claimant context
    cl.CLAIMANT_NAME,
    cl.CLAIMANT_TYPE,
    cl.INDUSTRY AS CLAIMANT_INDUSTRY,
    
    -- Claim details
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
    
    -- Calculated fields
    COALESCE(c.PAID_AMOUNT, 0) + COALESCE(c.RESERVED_AMOUNT, 0) AS TOTAL_INCURRED,
    CASE 
        WHEN c.ESTIMATED_AMOUNT > 0 
        THEN ROUND(c.PAID_AMOUNT / NULLIF(c.ESTIMATED_AMOUNT, 0) * 100, 1)
        ELSE 0
    END AS PAYMENT_TO_ESTIMATE_RATIO,
    CASE
        WHEN c.ESTIMATED_AMOUNT > c.COVERAGE_LIMIT THEN TRUE
        ELSE FALSE
    END AS EXCEEDS_COVERAGE,
    
    -- AI ENRICHMENT: Sentiment of loss description
    -- Returns: 'positive', 'negative', 'neutral', or 'mixed'
    AI_SENTIMENT(c.LOSS_DESCRIPTION):categories[0]:sentiment::VARCHAR AS DESCRIPTION_SENTIMENT,
    
    -- AI ENRICHMENT: Classify claim complexity
    -- Returns object with 'labels' array; extract first label
    AI_CLASSIFY(
        c.LOSS_DESCRIPTION,
        ['Simple - straightforward damage claim', 
         'Moderate - requires investigation', 
         'Complex - multiple parties or litigation potential']
    ):labels[0]::VARCHAR AS AI_COMPLEXITY_CLASS,
    
    -- AI ENRICHMENT: Extract damage type from description
    -- AI_EXTRACT reliably pulls named fields from free text (replaces EXTRACT_ANSWER)
    AI_EXTRACT(
        c.LOSS_DESCRIPTION,
        {'damage_type': 'What is the primary type of damage or injury described?'}
    ):response:damage_type::VARCHAR AS AI_EXTRACTED_DAMAGE_TYPE,
    
    CURRENT_TIMESTAMP() AS SILVER_LOADED_AT

FROM CLAIMS_BRONZE c
LEFT JOIN RAW_DATA.POLICIES p 
    ON c.POLICY_ID = p.POLICY_ID
LEFT JOIN RAW_DATA.CLAIMANTS cl 
    ON c.CLAIMANT_ID = cl.CLAIMANT_ID;

--------------------------------------------------------------------
-- Silver Layer: AI-Enriched Claim Notes
--------------------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE CLAIM_NOTES_SILVER
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '5 minutes'
    COMMENT = 'Silver layer: claim notes with sentiment analysis and key extraction'
AS
SELECT
    n.NOTE_ID,
    n.CLAIM_ID,
    n.NOTE_DATE,
    n.NOTE_AUTHOR,
    n.NOTE_TYPE,
    n.NOTE_TEXT,
    
    -- AI ENRICHMENT: Sentiment of each note
    -- Returns: 'positive', 'negative', 'neutral', or 'mixed'
    AI_SENTIMENT(n.NOTE_TEXT):categories[0]:sentiment::VARCHAR AS NOTE_SENTIMENT,
    
    -- AI ENRICHMENT: Bucket sentiment into simple categories
    CASE AI_SENTIMENT(n.NOTE_TEXT):categories[0]:sentiment::VARCHAR
        WHEN 'negative' THEN 'NEGATIVE'
        WHEN 'positive' THEN 'POSITIVE'
        ELSE 'NEUTRAL'
    END AS SENTIMENT_CATEGORY,
    
    -- AI ENRICHMENT: Extract recommended action from note text
    AI_EXTRACT(
        n.NOTE_TEXT,
        {'action': 'What action or next step is recommended?'}
    ):response:action::VARCHAR AS AI_EXTRACTED_ACTION,
    
    CURRENT_TIMESTAMP() AS SILVER_LOADED_AT

FROM RAW_DATA.CLAIM_NOTES n;

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
