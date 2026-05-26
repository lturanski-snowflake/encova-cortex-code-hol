# Cortex Code Hands-On Lab: AI-Powered Medallion Architecture

**Encova × Snowflake** | Duration: ~60 minutes

---

## What You'll Build

Using **Cortex Code** as your AI pair programmer, you'll build a complete Medallion Architecture pipeline:

1. **Bronze Layer** — Dynamic Table parsing raw claims data (simulated S3 ingest)
2. **Silver Layer** — AI-enriched transformations using Cortex AI Functions (Sentiment, Classification, Extraction)
3. **Gold Layer** — Aggregated business metrics and risk scoring
4. **Semantic View** — Natural language interface over your Gold layer
5. **Cortex Agent** — Conversational analytics for business users

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  S3 Landing Zone (RAW_DATA schema)                           │
│  Claims, Policies, Claimants, Notes                          │
└─────────────────────────┬───────────────────────────────────┘
                          ↓  Dynamic Table (1 min lag)
┌─────────────────────────────────────────────────────────────┐
│  BRONZE: CLAIMS_BRONZE                                       │
│  Parsed, validated, timestamped                              │
└─────────────────────────┬───────────────────────────────────┘
                          ↓  Dynamic Table (5 min lag) + Cortex AI
┌─────────────────────────────────────────────────────────────┐
│  SILVER: CLAIMS_SILVER + CLAIM_NOTES_SILVER                  │
│  Joined, enriched with AI Sentiment/Classification/Extraction│
└─────────────────────────┬───────────────────────────────────┘
                          ↓  Dynamic Table (10 min lag)
┌─────────────────────────────────────────────────────────────┐
│  GOLD: CLAIMS_GOLD + CLAIMS_METRICS_MONTHLY                  │
│  Risk scores, aggregated KPIs, denormalized summaries        │
└─────────────────────────┬───────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  ANALYTICS: Semantic View → Cortex Agent                     │
│  Natural language querying for business users                │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

- [x] Snowflake account access with `ATTENDEE_ROLE` granted
- [x] Your schema already created (e.g., `TRAINING_USER1`)
- [x] Source data loaded in `RAW_DATA` schema
- [x] Cortex Code available (Snowsight or VS Code CLI)

---

## Getting Started

### 1. Get the Lab Files

Choose one of these options to get the repo into your workspace:

**Option A — Connect Git repo (recommended for VS Code CLI):**
```bash
git clone <repo-url>
cd encova-cortex-code-lab
cortex
```

**Option B — Upload folder in Snowsight:**
1. In Snowsight, open **Cortex Code** from the left nav
2. Click the **+** (attach) button in the chat input area
3. Select **Upload Folder** and choose this lab folder
4. All files (prompts, skills, SQL) will be available in your workspace

### 2. Open Cortex Code

- **Snowsight:** Click the Cortex Code chat icon in the left nav
- **VS Code CLI:** Run `cortex` in terminal

### 3. Set Your Context

> **IMPORTANT:** Switch to `ATTENDEE_ROLE` before starting.

```sql
USE ROLE ATTENDEE_ROLE;
USE DATABASE ENCOVA_TRAINING;
USE SCHEMA TRAINING_<USERNAME>;
USE WAREHOUSE ENCOVA_TRAINING_WH;
```

### 4. Load Skills

Skills teach Cortex Code your project's specifics:

| Skill | When to Use | File Path |
|-------|-------------|-----------|
| `encova-context` | Environment, schemas, table details | `.cortex/skills/encova-context/SKILL.md` |
| `medallion-pipeline` | Pipeline patterns, AI functions, Dynamic Tables | `.cortex/skills/medallion-pipeline/SKILL.md` |

### 5. Pre-Flight Check

```sql
SELECT 'RAW_DATA' AS SCHEMA_NAME, COUNT(*) AS TABLE_COUNT
FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'RAW_DATA';
```

Should return 5 tables. If any checks fail, ask the lab instructor.

---

## Lab Guide

All prompts are in **[`prompts/lab_guide.md`](prompts/lab_guide.md)** — open it and follow along.

| Module | Time | What You'll Do |
|--------|------|----------------|
| 0: Setup | 5 min | Context, skills, pre-flight |
| 1: Bronze Layer | 10 min | Explore data → Create Bronze Dynamic Table |
| 2: Silver Layer | 15 min | AI enrichment → Sentiment, Classification, Extraction |
| 3: Gold Layer | 10 min | Aggregations → Risk scoring → Business metrics |
| 4: Semantic View + Agent | 10 min | Natural language interface → Query conversationally |
| 5: Cortex Code Demo | 10 min | Live demo of AI-driven development |

---

## Key Concepts

### Medallion Architecture
- **Bronze:** Raw data, lightly validated. Fast refresh (1 min).
- **Silver:** Enriched with joins and AI. Moderate refresh (5 min).
- **Gold:** Aggregated for analytics. Slower refresh (10 min - 1 hr).

### Cortex AI Functions (Used in Silver Layer)
- `SENTIMENT(text)` — Returns -1.0 to 1.0 sentiment score
- `CLASSIFY_TEXT(text, categories)` — Auto-categorizes text
- `EXTRACT_ANSWER(text, question)` — Pulls structured data from text

### Dynamic Tables vs Traditional ETL
- **No orchestration needed** — Snowflake manages refresh automatically
- **Declarative** — Define WHAT you want, not HOW to get there
- **Incremental** — Only processes changed data
- **Observable** — Built-in lineage and monitoring

### Skills
- Not every prompt needs a skill — use them for domain context
- `$encova-context` for environment and schema awareness
- `$medallion-pipeline` for pipeline patterns and AI function syntax

---

## Teardown

See the teardown section at the end of `prompts/lab_guide.md`. Everything is commented out — uncomment what you want to clean up.

---

## File Reference

```
HoL/
├── README.md                                    ← You are here
├── admin_setup_guide.md                         ← Admin setup (not for attendees)
├── prompts/
│   ├── lab_guide.md                             ← All prompts (Modules 0-5)
│   └── module_prompts/                          ← Individual prompt files
│       ├── 0_setup/
│       ├── 1_bronze_ingestion/
│       ├── 2_silver_transforms/
│       ├── 3_gold_layer/
│       ├── 4_semantic_view_agent/
│       ├── 5_cortex_code_demo/
│       └── 6_teardown/
├── .cortex/skills/
│   ├── encova-context/SKILL.md                  ← $encova-context
│   └── medallion-pipeline/SKILL.md              ← $medallion-pipeline
├── sql/
│   ├── 00_verify_grants.sql                     ← Pre-flight grant checker
│   ├── 01_admin_environment_setup.sql           ← Admin asset (pre-lab)
│   ├── 02_admin_sample_data.sql                 ← Admin asset (pre-lab)
│   ├── 03_bronze_ingestion.sql                  ← Reference: Module 1
│   ├── 04_silver_transforms.sql                 ← Reference: Module 2
│   ├── 05_gold_layer.sql                        ← Reference: Module 3
│   ├── 06_semantic_view.sql                     ← Reference: Module 4
│   ├── 07_cortex_agent.sql                      ← Reference: Module 4
│   └── 08_teardown.sql                          ← Cleanup
```

---

## Resources

| Resource | Link |
|----------|------|
| Cortex Code | https://docs.snowflake.com/en/user-guide/cortex-code |
| Cortex Code Skills | https://github.com/Snowflake-Labs/cortex-code-skills |
| Dynamic Tables | https://docs.snowflake.com/en/user-guide/dynamic-tables-about |
| Cortex AI Functions | https://docs.snowflake.com/en/user-guide/snowflake-cortex/llm-functions |
| Semantic Views | https://docs.snowflake.com/en/user-guide/views-semantic |
| Cortex Agents | https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agent |
| Streams | https://docs.snowflake.com/en/user-guide/streams |
| External Stages | https://docs.snowflake.com/en/user-guide/data-load-s3-config |

---

## Questions?

- **Luke Turanski** — luke.turanski@snowflake.com (Snowflake SE)
