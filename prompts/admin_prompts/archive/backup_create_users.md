# Admin: Create Per-Attendee Users (Backup Plan)

**Run by:** Luke (SE) — only if the shared-user approach doesn't work  
**Role required:** ACCOUNTADMIN  
**Prerequisite:** `attendees.txt` is populated with one first name per line (uppercase)

---

### When to Use

Use this if:
- The account requires individual logins (SSO/MFA policy)
- Attendees need separate audit trails
- Shared user causes session conflicts

---

### CoCo Prompt

```
Read the file attendees.txt in this workspace. It contains one attendee first name 
per line (uppercase). Generate a SQL file called sql/01d_create_users.sql that I 
can run directly. The file should start with USE ROLE ACCOUNTADMIN; and then for 
EACH name include:

1. CREATE USER IF NOT EXISTS ENCOVA_<NAME>
     PASSWORD = 'EncovaCoCo2025!'
     DEFAULT_ROLE = ATTENDEE_ROLE
     DEFAULT_WAREHOUSE = ENCOVA_TRAINING_WH
     DEFAULT_NAMESPACE = TRAINING_<NAME>.BRONZE
     MUST_CHANGE_PASSWORD = FALSE
     COMMENT = 'HoL attendee — <NAME>';

2. GRANT ROLE ATTENDEE_ROLE TO USER ENCOVA_<NAME>;

Write the complete file — do NOT execute it.
```

---

### Credentials to Distribute

| Attendee | Username | Password | Database |
|----------|----------|----------|----------|
| (per name) | `ENCOVA_<NAME>` | `EncovaCoCo2025!` | `TRAINING_<NAME>` |

> **Note:** Change the password above before running in production.

---

### Teardown Addition

If you created per-attendee users, add this to teardown:

```
Read attendees.txt. For EACH name, run as ACCOUNTADMIN:
DROP USER IF EXISTS ENCOVA_<NAME>;
```
