# Admin: Load Skills

**Run by:** Luke (SE) before the lab (or at the very start)  
**Purpose:** Pre-load the CoCo skills so attendees don't need to do it manually

---

### Option A: Pre-load via Git Repo (recommended)

If the lab repo is connected as a Git Repository in Snowsight, skills in `.cortex/skills/` are auto-discovered. No action needed.

### Option B: Upload to Workspace

1. Open Cortex Code in Snowsight
2. Click the **+** (attach) button
3. Upload the entire project folder (or just `.cortex/skills/`)
4. Skills will be available to all users sharing the workspace

### Option C: Manual Skill Verification

Paste this into CoCo to confirm skills are loaded:

```
List all available skills in this workspace. I should see:
- encova-context (environment, schemas, table details)
- medallion-pipeline (pipeline patterns, AI functions, Dynamic Tables)

If either is missing, read the files at:
- .cortex/skills/encova-context/SKILL.md
- .cortex/skills/medallion-pipeline/SKILL.md
```

---

### Skills Reference

| Skill | File Path | Purpose |
|-------|-----------|---------|
| `encova-context` | `.cortex/skills/encova-context/SKILL.md` | Company context, environment, table schemas, conventions |
| `medallion-pipeline` | `.cortex/skills/medallion-pipeline/SKILL.md` | Pipeline patterns, Dynamic Table templates, AI function syntax |
