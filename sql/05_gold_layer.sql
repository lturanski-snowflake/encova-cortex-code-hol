/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Module 3 Reference: Gold Layer (Aggregated Analytics)
    
    Pattern: Silver → Dynamic Tables → Gold (business-ready metrics)
    
    Gold layer tables are optimized for analytics and reporting:
    - Pre-aggregated metrics by key dimensions
    - Claim summaries with AI-generated insights
    - Ready for Semantic Views and Cortex Agents
*/

--------------------------------------------------------------------
-- Gold: Claims Summary (one row per claim, fully enriched)
--------------------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE CLAIMS_GOLD
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '10 minutes'
    COMMENT = 'Gold layer: denormalized claim summaries with AI insights and note aggregations'
AS
WITH note_agg AS (
    SELECT
        CLAIM_ID,
        COUNT(*) AS TOTAL_NOTES,
        ROUND(AVG(CASE LOWER(NOTE_SENTIMENT)
            WHEN 'positive' THEN  1.0
            WHEN 'neutral'  THEN  0.0
            WHEN 'negative' THEN -1.0
            ELSE 0.0
        END), 3) AS AVG_NOTE_SENTIMENT,
        SUM(CASE WHEN SENTIMENT_CATEGORY = 'NEGATIVE' THEN 1 ELSE 0 END) AS NEGATIVE_NOTE_COUNT,
        MAX(NOTE_DATE) AS LAST_NOTE_DATE,
        LISTAGG(DISTINCT NOTE_TYPE, ', ') WITHIN GROUP (ORDER BY NOTE_TYPE) AS NOTE_TYPES_USED
    FROM CLAIM_NOTES_SILVER
    GROUP BY CLAIM_ID
)
SELECT
    cs.CLAIM_ID,
    cs.CLAIM_NUMBER,
    cs.POLICY_NUMBER,
    cs.LINE_OF_BUSINESS,
    cs.COVERAGE_TYPE,
    cs.CLAIMANT_NAME,
    cs.CLAIMANT_TYPE,
    cs.CLAIMANT_INDUSTRY,
    cs.DATE_OF_LOSS,
    cs.DATE_REPORTED,
    cs.CLAIM_STATUS,
    cs.LOSS_TYPE,
    cs.LOSS_DESCRIPTION,
    cs.LOSS_LOCATION_STATE,
    cs.LOSS_LOCATION_CITY,
    cs.ESTIMATED_AMOUNT,
    cs.PAID_AMOUNT,
    cs.RESERVED_AMOUNT,
    cs.TOTAL_INCURRED,
    cs.PAYMENT_TO_ESTIMATE_RATIO,
    cs.PREMIUM_AMOUNT,
    cs.DEDUCTIBLE_AMOUNT,
    cs.COVERAGE_LIMIT,
    cs.EXCEEDS_COVERAGE,
    cs.ADJUSTER_ID,
    cs.FRAUD_INDICATOR,
    cs.SEVERITY,
    cs.CAUSE_OF_LOSS,
    cs.WEATHER_RELATED,
    cs.LITIGATION_FLAG,
    cs.DAYS_TO_REPORT,
    cs.POLICY_STATE,
    cs.AGENCY_CODE,
    
    -- AI-derived fields from Silver
    cs.DESCRIPTION_SENTIMENT,
    cs.AI_COMPLEXITY_CLASS,
    cs.AI_EXTRACTED_DAMAGE_TYPE,
    
    -- Note aggregations
    COALESCE(na.TOTAL_NOTES, 0) AS TOTAL_NOTES,
    na.AVG_NOTE_SENTIMENT,
    COALESCE(na.NEGATIVE_NOTE_COUNT, 0) AS NEGATIVE_NOTE_COUNT,
    na.LAST_NOTE_DATE,
    na.NOTE_TYPES_USED,
    
    -- Derived risk score (business logic + AI signals)
    CASE
        WHEN cs.FRAUD_INDICATOR IN ('SUSPICIOUS', 'CONFIRMED') THEN 90
        WHEN cs.LITIGATION_FLAG = TRUE AND cs.SEVERITY = 'HIGH' THEN 80
        WHEN cs.SEVERITY = 'HIGH' AND cs.ESTIMATED_AMOUNT > 100000 THEN 70
        WHEN COALESCE(na.NEGATIVE_NOTE_COUNT, 0) >= 3 THEN 60
        WHEN cs.AI_COMPLEXITY_CLASS LIKE 'Complex%' THEN 50
        WHEN cs.SEVERITY = 'MEDIUM' THEN 30
        ELSE 10
    END AS RISK_SCORE,
    
    CURRENT_TIMESTAMP() AS GOLD_LOADED_AT

FROM CLAIMS_SILVER cs
LEFT JOIN note_agg na ON cs.CLAIM_ID = na.CLAIM_ID;

--------------------------------------------------------------------
-- Gold: Monthly Claims Metrics (aggregated KPIs)
--------------------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE CLAIMS_METRICS_MONTHLY
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = DOWNSTREAM
    COMMENT = 'Gold layer: monthly aggregated claims metrics by line of business and state — refreshes automatically after CLAIMS_GOLD'
AS
SELECT
    DATE_TRUNC('month', DATE_OF_LOSS) AS LOSS_MONTH,
    LINE_OF_BUSINESS,
    LOSS_LOCATION_STATE AS STATE,
    SEVERITY,
    
    -- Volume metrics
    COUNT(*) AS CLAIM_COUNT,
    COUNT(DISTINCT POLICY_NUMBER) AS POLICIES_WITH_CLAIMS,
    
    -- Financial metrics
    SUM(ESTIMATED_AMOUNT) AS TOTAL_ESTIMATED,
    SUM(PAID_AMOUNT) AS TOTAL_PAID,
    SUM(RESERVED_AMOUNT) AS TOTAL_RESERVED,
    SUM(TOTAL_INCURRED) AS TOTAL_INCURRED,
    ROUND(AVG(ESTIMATED_AMOUNT), 2) AS AVG_CLAIM_AMOUNT,
    MAX(ESTIMATED_AMOUNT) AS MAX_CLAIM_AMOUNT,
    
    -- Performance metrics
    ROUND(AVG(DAYS_TO_REPORT), 1) AS AVG_DAYS_TO_REPORT,
    SUM(CASE WHEN CLAIM_STATUS = 'CLOSED' THEN 1 ELSE 0 END) AS CLOSED_COUNT,
    SUM(CASE WHEN CLAIM_STATUS = 'OPEN' THEN 1 ELSE 0 END) AS OPEN_COUNT,
    
    -- Risk metrics
    SUM(CASE WHEN FRAUD_INDICATOR != 'NONE' THEN 1 ELSE 0 END) AS SUSPICIOUS_COUNT,
    SUM(CASE WHEN LITIGATION_FLAG = TRUE THEN 1 ELSE 0 END) AS LITIGATION_COUNT,
    SUM(CASE WHEN WEATHER_RELATED = TRUE THEN 1 ELSE 0 END) AS WEATHER_CLAIMS,
    
    -- AI metrics (map string sentiment to numeric for averaging)
    ROUND(AVG(CASE LOWER(DESCRIPTION_SENTIMENT)
        WHEN 'positive' THEN  1.0
        WHEN 'neutral'  THEN  0.0
        WHEN 'negative' THEN -1.0
        ELSE 0.0
    END), 3) AS AVG_SENTIMENT,
    SUM(CASE WHEN AI_COMPLEXITY_CLASS LIKE 'Complex%' THEN 1 ELSE 0 END) AS COMPLEX_CLAIMS,
    
    CURRENT_TIMESTAMP() AS GOLD_LOADED_AT

FROM CLAIMS_GOLD
GROUP BY 1, 2, 3, 4;

--------------------------------------------------------------------
-- Gold: Adjuster Performance
--------------------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE ADJUSTER_PERFORMANCE_GOLD
    WAREHOUSE = ENCOVA_TRAINING_WH
    TARGET_LAG = '1 hour'
    COMMENT = 'Gold layer: adjuster workload and performance metrics'
AS
SELECT
    cg.ADJUSTER_ID,
    COUNT(*) AS TOTAL_CLAIMS,
    COUNT(CASE WHEN cg.CLAIM_STATUS = 'CLOSED' THEN 1 END) AS CLOSED_CLAIMS,
    COUNT(CASE WHEN cg.CLAIM_STATUS = 'OPEN' THEN 1 END) AS OPEN_CLAIMS,
    ROUND(AVG(cg.ESTIMATED_AMOUNT), 2) AS AVG_CLAIM_VALUE,
    SUM(cg.TOTAL_INCURRED) AS TOTAL_PORTFOLIO_INCURRED,
    ROUND(AVG(cg.DAYS_TO_REPORT), 1) AS AVG_DAYS_TO_REPORT,
    ROUND(AVG(cg.RISK_SCORE), 1) AS AVG_RISK_SCORE,
    SUM(CASE WHEN cg.FRAUD_INDICATOR != 'NONE' THEN 1 ELSE 0 END) AS FRAUD_FLAGS,
    SUM(CASE WHEN cg.LITIGATION_FLAG THEN 1 ELSE 0 END) AS LITIGATION_CASES,
    ROUND(AVG(cg.TOTAL_NOTES), 1) AS AVG_NOTES_PER_CLAIM,
    CURRENT_TIMESTAMP() AS GOLD_LOADED_AT
FROM CLAIMS_GOLD cg
GROUP BY cg.ADJUSTER_ID;

--------------------------------------------------------------------
-- Verify Gold Layer
--------------------------------------------------------------------
SELECT COUNT(*) AS GOLD_CLAIMS_COUNT FROM CLAIMS_GOLD;
SELECT * FROM CLAIMS_METRICS_MONTHLY LIMIT 10;
SELECT * FROM ADJUSTER_PERFORMANCE_GOLD ORDER BY TOTAL_CLAIMS DESC LIMIT 10;

-- Pipeline lineage view
SELECT 'RAW_DATA.CLAIMS_RAW' AS SOURCE, 'CLAIMS_BRONZE' AS TARGET, 'Bronze' AS LAYER
UNION ALL SELECT 'CLAIMS_BRONZE', 'CLAIMS_SILVER', 'Silver'
UNION ALL SELECT 'RAW_DATA.POLICIES', 'CLAIMS_SILVER', 'Silver (join)'
UNION ALL SELECT 'RAW_DATA.CLAIMANTS', 'CLAIMS_SILVER', 'Silver (join)'
UNION ALL SELECT 'CLAIMS_SILVER', 'CLAIMS_GOLD', 'Gold'
UNION ALL SELECT 'CLAIM_NOTES_SILVER', 'CLAIMS_GOLD', 'Gold (join)'
UNION ALL SELECT 'CLAIMS_GOLD', 'CLAIMS_METRICS_MONTHLY', 'Gold (agg)'
UNION ALL SELECT 'CLAIMS_GOLD', 'ADJUSTER_PERFORMANCE_GOLD', 'Gold (agg)';
