# 🎓 PES University DBMS Viva Demonstration Suite
### Project: Concert & Live Event Management & Intelligent Arena Reservation System

---

## 📂 Quick-Access Demonstration Directory

Keep this folder open in your code editor (e.g. VS Code) during your viva. Every single requirement from the evaluation rubric has been isolated into its own dedicated, clean file:

| File | What to Use It For / When She Asks |
| :--- | :--- |
| **[`00_VIVA_MASTER_CHEATSHEET.md`](file:///c:/Users/vrush/.gemini/antigravity/scratch/concert-reservation-system/viva/00_VIVA_MASTER_CHEATSHEET.md)** | **The 5-Minute Defense Script**. Contains the 60-second pitch, entity classifications, normalization proof, and anticipated Q&A. |
| **[`01_ALL_DDL_COMMANDS_WITH_CONSTRAINTS.sql`](file:///c:/Users/vrush/.gemini/antigravity/scratch/concert-reservation-system/viva/01_ALL_DDL_COMMANDS_WITH_CONSTRAINTS.sql)** | **All DDL Commands & Constraints**. Complete `CREATE TABLE` statements for all 11 tables, 6 constraint types, indexes, and views. |
| **[`01_DDL_AND_CONSTRAINTS_CHEATSHEET.md`](file:///c:/Users/vrush/.gemini/antigravity/scratch/concert-reservation-system/viva/01_DDL_AND_CONSTRAINTS_CHEATSHEET.md)** | **DDL & Constraints Defense Guide**. Structured markdown reference with foreign key cascading rationale and domain checks. |
| **[`02_CODE_INVOCATION_POINTERS.md`](file:///c:/Users/vrush/.gemini/antigravity/scratch/concert-reservation-system/viva/01_CODE_INVOCATION_POINTERS.md)** | **"Show where the invocation is in your huge code!"** Exact file names and line numbers for all procedures, functions, triggers, and routes without searching. |
| **[`02_ER_AND_SCHEMA_SPECIFICATION.md`](file:///c:/Users/vrush/.gemini/antigravity/scratch/concert-reservation-system/viva/02_ER_AND_SCHEMA_SPECIFICATION.md)** | **ER Diagram & Schema Defense**. Strong vs Weak entities, Derived/Multi-valued/Composite attributes, 3NF & BCNF proof. |
| **[`03_TRIGGER_BEFORE_AFTER_DEMO.sql`](file:///c:/Users/vrush/.gemini/antigravity/scratch/concert-reservation-system/viva/03_TRIGGER_BEFORE_AFTER_DEMO.sql)** | **Trigger Before vs After Diff**. Step-by-step SQL script showing the ticket state before, the update, and the new audit log in `seat_audit_logs`. |
| **[`04_PLSQL_PROCEDURES_AND_FUNCTIONS.sql`](file:///c:/Users/vrush/.gemini/antigravity/scratch/concert-reservation-system/viva/04_PLSQL_PROCEDURES_AND_FUNCTIONS.sql)** | **PL/SQL Stored Function & Procedure**. `fn_calculate_dynamic_pricing` (occupancy surge) and `sp_book_tickets_atomic` (`FOR UPDATE` row lock). |
| **[`05_ADVANCED_QUERIES_DEMO.sql`](file:///c:/Users/vrush/.gemini/antigravity/scratch/concert-reservation-system/viva/05_ADVANCED_QUERIES_DEMO.sql)** | **The 4 Advanced Queries (4 Marks)**: Multi-table join with outer join, Nested with `HAVING`, Correlated subquery, and Recursive CTE. |
| **[`06_NOSQL_JSONB_QUERIES.sql`](file:///c:/Users/vrush/.gemini/antigravity/scratch/concert-reservation-system/viva/06_NOSQL_JSONB_QUERIES.sql)** | **NoSQL Queries**. JSONB containment search (`@>`) with GIN index, and in-place mutation (`jsonb_set`). |
| **[`07_VECTOR_COSINE_SIMILARITY.sql`](file:///c:/Users/vrush/.gemini/antigravity/scratch/concert-reservation-system/viva/07_VECTOR_COSINE_SIMILARITY.sql)** | **Vector Similarity Search**. 5D audio feature embedding matching using Cosine Similarity formula. |
| **[`08_RBAC_AND_SECURITY.sql`](file:///c:/Users/vrush/.gemini/antigravity/scratch/concert-reservation-system/viva/08_RBAC_AND_SECURITY.sql)** | **Database RBAC & RLS**. Organizer vs Attendee roles and Row-Level Security policies. |

---

## ⚡ Live Terminal Demonstrator

If the examiner asks you to execute queries or demonstrate triggers live from the command line:

```bash
npm run viva
```

This launches an interactive CLI menu that connects directly to the project database and executes tests with formatted ASCII tables.
