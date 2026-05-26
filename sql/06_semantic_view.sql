/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Module 4 Reference: Semantic View + Cortex Agent
    
    Pattern: Gold Layer → Semantic View → Cortex Agent → Natural Language Queries
    
    This enables business users to query claims data conversationally
    without writing SQL — directly from Copilot, chat tools, or Snowsight.
*/

--------------------------------------------------------------------
-- Semantic View over CLAIMS_GOLD
--------------------------------------------------------------------
CREATE OR REPLACE SEMANTIC VIEW CLAIMS_ANALYTICS_SV
    COMMENT = 'Semantic view over claims gold layer for natural language analytics'
AS SEMANTIC MODEL
    NAME = 'Claims Analytics'
    DESCRIPTION = 'Insurance claims analytics model for Encova. Covers claim volumes, financials, risk indicators, AI-derived complexity, and adjuster performance.'
    ENTITIES = (
        ENTITY claims
            TABLE = CLAIMS_GOLD
            PRIMARY_KEY = (CLAIM_ID)
            COLUMNS = (
                CLAIM_ID 
                    DESCRIPTION = 'Unique claim identifier',
                CLAIM_NUMBER 
                    DESCRIPTION = 'Human-readable claim reference number',
                POLICY_NUMBER 
                    DESCRIPTION = 'Associated policy number',
                LINE_OF_BUSINESS 
                    DESCRIPTION = 'Insurance line: Commercial Property, General Liability, Workers Compensation, Commercial Auto, Business Owners Policy'
                    SYNONYMS = ('LOB', 'business line', 'product line'),
                COVERAGE_TYPE 
                    DESCRIPTION = 'Type of coverage: Property Damage, Bodily Injury, Medical Payments, Collision, Comprehensive, Umbrella',
                CLAIMANT_NAME 
                    DESCRIPTION = 'Name of the claimant or insured party',
                CLAIMANT_TYPE 
                    DESCRIPTION = 'Individual, Business, or Third Party',
                CLAIMANT_INDUSTRY 
                    DESCRIPTION = 'Industry sector of the claimant business',
                DATE_OF_LOSS 
                    DESCRIPTION = 'Date when the loss/incident occurred',
                DATE_REPORTED 
                    DESCRIPTION = 'Date when the claim was reported',
                CLAIM_STATUS 
                    DESCRIPTION = 'Current status: OPEN, UNDER_INVESTIGATION, APPROVED, PAID, CLOSED, DENIED'
                    SYNONYMS = ('status', 'claim state'),
                LOSS_TYPE 
                    DESCRIPTION = 'Category of loss: Property Damage - Fire/Water/Wind, Bodily Injury, Vehicle Collision, Theft, Workers Comp, Liability',
                LOSS_LOCATION_STATE 
                    DESCRIPTION = 'US state where the loss occurred (2-letter code)'
                    SYNONYMS = ('state', 'location'),
                LOSS_LOCATION_CITY 
                    DESCRIPTION = 'City where the loss occurred',
                ESTIMATED_AMOUNT 
                    DESCRIPTION = 'Estimated total claim value in USD',
                PAID_AMOUNT 
                    DESCRIPTION = 'Amount paid out on the claim in USD',
                RESERVED_AMOUNT 
                    DESCRIPTION = 'Reserved amount for future payments in USD',
                TOTAL_INCURRED 
                    DESCRIPTION = 'Total incurred = paid + reserved in USD',
                SEVERITY 
                    DESCRIPTION = 'Claim severity: HIGH, MEDIUM, LOW',
                FRAUD_INDICATOR 
                    DESCRIPTION = 'Fraud flag: NONE, SUSPICIOUS, CONFIRMED',
                WEATHER_RELATED 
                    DESCRIPTION = 'Whether the claim is weather-related (TRUE/FALSE)',
                LITIGATION_FLAG 
                    DESCRIPTION = 'Whether an attorney is involved (TRUE/FALSE)',
                DAYS_TO_REPORT 
                    DESCRIPTION = 'Days between loss date and report date',
                AI_COMPLEXITY_CLASS 
                    DESCRIPTION = 'AI-classified complexity: Simple, Moderate, Complex',
                RISK_SCORE 
                    DESCRIPTION = 'Computed risk score from 0-100 based on fraud, litigation, severity, and AI signals',
                ADJUSTER_ID 
                    DESCRIPTION = 'Assigned claims adjuster ID',
                TOTAL_NOTES 
                    DESCRIPTION = 'Number of adjuster notes on this claim'
            )
    )
    METRICS = (
        METRIC total_claims
            EXPRESSION = 'COUNT(claims.CLAIM_ID)'
            DESCRIPTION = 'Total number of claims',
        METRIC total_incurred_amount
            EXPRESSION = 'SUM(claims.TOTAL_INCURRED)'
            DESCRIPTION = 'Total incurred amount across all claims (paid + reserved) in USD',
        METRIC average_claim_amount
            EXPRESSION = 'AVG(claims.ESTIMATED_AMOUNT)'
            DESCRIPTION = 'Average estimated claim amount in USD',
        METRIC total_paid
            EXPRESSION = 'SUM(claims.PAID_AMOUNT)'
            DESCRIPTION = 'Total amount paid out in USD',
        METRIC fraud_rate
            EXPRESSION = 'AVG(CASE WHEN claims.FRAUD_INDICATOR != ''NONE'' THEN 1.0 ELSE 0.0 END)'
            DESCRIPTION = 'Percentage of claims with fraud indicators',
        METRIC avg_days_to_report
            EXPRESSION = 'AVG(claims.DAYS_TO_REPORT)'
            DESCRIPTION = 'Average days between loss and reporting',
        METRIC litigation_rate
            EXPRESSION = 'AVG(CASE WHEN claims.LITIGATION_FLAG = TRUE THEN 1.0 ELSE 0.0 END)'
            DESCRIPTION = 'Percentage of claims involving litigation',
        METRIC avg_risk_score
            EXPRESSION = 'AVG(claims.RISK_SCORE)'
            DESCRIPTION = 'Average risk score across claims',
        METRIC closure_rate
            EXPRESSION = 'AVG(CASE WHEN claims.CLAIM_STATUS = ''CLOSED'' THEN 1.0 ELSE 0.0 END)'
            DESCRIPTION = 'Percentage of claims that are closed',
        METRIC weather_claim_pct
            EXPRESSION = 'AVG(CASE WHEN claims.WEATHER_RELATED = TRUE THEN 1.0 ELSE 0.0 END)'
            DESCRIPTION = 'Percentage of claims that are weather-related'
    )
    FILTERS = (
        FILTER by_line_of_business
            EXPRESSION = 'claims.LINE_OF_BUSINESS'
            DESCRIPTION = 'Filter by insurance line of business',
        FILTER by_state
            EXPRESSION = 'claims.LOSS_LOCATION_STATE'
            DESCRIPTION = 'Filter by loss location state',
        FILTER by_severity
            EXPRESSION = 'claims.SEVERITY'
            DESCRIPTION = 'Filter by claim severity (HIGH, MEDIUM, LOW)',
        FILTER by_status
            EXPRESSION = 'claims.CLAIM_STATUS'
            DESCRIPTION = 'Filter by claim status',
        FILTER by_loss_type
            EXPRESSION = 'claims.LOSS_TYPE'
            DESCRIPTION = 'Filter by type of loss'
    );

--------------------------------------------------------------------
-- Verify Semantic View
--------------------------------------------------------------------
-- DESCRIBE SEMANTIC VIEW CLAIMS_ANALYTICS_SV;
