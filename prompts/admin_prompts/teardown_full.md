# Admin: Full Teardown

**Run by:** Luke (SE) after the lab session  
**Role required:** ACCOUNTADMIN

---

### CoCo Prompt

```
Read the file attendees.txt in this workspace. For EACH name, run as ACCOUNTADMIN:

1. DROP DATABASE IF EXISTS TRAINING_<NAME> CASCADE;

Then run:
- DROP DATABASE IF EXISTS ENCOVA_TRAINING CASCADE;
- DROP WAREHOUSE IF EXISTS ENCOVA_TRAINING_WH;
- DROP ROLE IF EXISTS ATTENDEE_ROLE;

Confirm everything has been cleaned up.
```

---

### What This Does

1. Drops all per-attendee databases (and all objects inside them)
2. Drops the shared database, warehouse, and role
3. Leaves the account clean for next use
