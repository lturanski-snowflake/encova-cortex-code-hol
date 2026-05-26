/*
    Encova × Snowflake Cortex Code Hands-On Lab
    Module 4 Reference: Cortex Agent
    
    Pattern: Semantic View → Cortex Agent → Natural Language Interface
    
    The agent allows business users (adjusters, managers, execs) to
    ask questions about claims data without writing SQL.
    
    This is also accessible via Cortex Code, Copilot, and external AI tools.
*/

--------------------------------------------------------------------
-- Create Cortex Agent (YAML specification format)
--------------------------------------------------------------------
CREATE OR REPLACE AGENT CLAIMS_ANALYTICS_AGENT
    COMMENT = 'Natural language claims analytics agent for Encova'
    SPECIFICATION = $$
    models:
      orchestration: auto

    instructions:
      response: >
        You are a claims analytics assistant for Encova Insurance.
        Help adjusters, managers, and executives understand claims data.
        Provide specific numbers, format currency with $ and commas,
        percentages to 1 decimal place. When discussing trends, highlight
        notable outliers or concerns. Always mention the time period and
        any filters applied.
      sample_questions:
        - question: "What is the total claims volume and incurred amount by line of business?"
        - question: "Which states have the highest fraud rate and average risk score?"
        - question: "How does claim severity correlate with average days to report? Are high severity claims reported faster?"
        - question: "What percentage of claims are weather-related and how does their average amount compare to non-weather claims?"
        - question: "Show me the distribution of AI-classified complexity and average claim amount for each level."

    tools:
      - tool_spec:
          type: analyst
          name: CLAIMS_ANALYTICS_SV

    tool_resources:
      CLAIMS_ANALYTICS_SV:
        semantic_view: CLAIMS_ANALYTICS_SV
    $$;

--------------------------------------------------------------------
-- Test the Agent
--------------------------------------------------------------------

-- Query 1: High-level summary
-- SELECT SNOWFLAKE.CORTEX.AGENT(
--     'CLAIMS_ANALYTICS_AGENT',
--     'What is the total claims volume and incurred amount by line of business?'
-- );

-- Query 2: Risk analysis
-- SELECT SNOWFLAKE.CORTEX.AGENT(
--     'CLAIMS_ANALYTICS_AGENT',
--     'Which states have the highest fraud rate and average risk score?'
-- );

-- Query 3: Severity and reporting speed
-- SELECT SNOWFLAKE.CORTEX.AGENT(
--     'CLAIMS_ANALYTICS_AGENT',
--     'How does claim severity correlate with average days to report?'
-- );

-- Query 4: Weather impact
-- SELECT SNOWFLAKE.CORTEX.AGENT(
--     'CLAIMS_ANALYTICS_AGENT',
--     'What percentage of claims are weather-related and what is their average amount vs non-weather claims?'
-- );

-- Query 5: Complexity analysis
-- SELECT SNOWFLAKE.CORTEX.AGENT(
--     'CLAIMS_ANALYTICS_AGENT',
--     'Show me the distribution of AI-classified complexity and average claim amount for each level.'
-- );
