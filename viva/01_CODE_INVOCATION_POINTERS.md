# 📍 Code Invocation Pointers (Quick Reference Map)
> **Evaluator Requirement**: *"Show where the invocation of that is in your HUGE code. You can't search for it at that time."*
> **Purpose**: Keep this file open on a second monitor or tab during the viva. When she asks where something is invoked, immediately open the file and jump to the exact line!

---

## 🗺️ Master Code Navigation Summary Table

| Component | SQL Definition File | SQL Lines | Invocation File (Application Code) | Invocation Line | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Stored Procedure** (`sp_book_tickets_atomic`) | `database/04_plsql.sql` | Lines 135–185 | `src/app/api/bookings/route.ts` | **Line 42** | Atomic ticket booking with `FOR UPDATE` concurrency lock |
| **Stored Function** (`fn_calculate_dynamic_pricing`) | `database/04_plsql.sql` | Lines 75–125 | `src/app/api/pricing/route.ts` | **Line 24** | Real-time dynamic pricing based on venue occupancy |
| **Audit Trigger** (`trg_audit_seat_status_change`) | `database/04_plsql.sql` | Lines 11–60 | `src/app/api/triggers/route.ts` | **Line 72** | Automatic audit log generation on ticket status change |
| **Advanced SQL Queries** (Join, Nested, Correlated, CTE) | `database/03_joins_nested_cte.sql` | Lines 1–110 | `src/app/api/advanced-queries/route.ts` | **Lines 14–72** | Multi-table joins, subqueries, and recursive CTE |
| **NoSQL JSONB Queries** (`@>`, `jsonb_set`) | `database/05_nosql_vector.sql` | Lines 15–70 | `src/app/api/nosql/route.ts` | **Lines 28–65** | Containment search and in-place document updates |
| **Vector Cosine Similarity Search** | `database/05_nosql_vector.sql` | Lines 90–145 | `src/app/api/vector-search/route.ts` | **Lines 25–48** | 5D audio feature embedding similarity ranking |
| **RBAC & Row Level Security (RLS)** | `database/06_rbac_roles.sql` | Lines 1–85 | `src/app/api/auth/route.ts` | **Lines 12–35** | Role switching & session level isolation |

---

## 🔍 Detailed Code Snippets & Explanations

### 1. Stored Procedure: `sp_book_tickets_atomic`
* **SQL Definition** (`database/04_plsql.sql`):
  ```sql
  CREATE OR REPLACE PROCEDURE sp_book_tickets_atomic(
      p_user_id INT,
      p_event_id INT,
      p_seat_ids INT[],
      p_payment_method VARCHAR,
      OUT p_booking_reference VARCHAR,
      OUT p_total_amount NUMERIC
  ) ...
  ```
* **Invocation in Backend Code** (`src/app/api/bookings/route.ts` - Line 42):
  ```typescript
  // Invokes stored procedure with atomic row locking (FOR UPDATE)
  const result = await db.query(
    `CALL sp_book_tickets_atomic($1, $2, $3, $4, NULL, NULL);`,
    [userId, eventId, seatIds, paymentMethod]
  );
  ```
* **Triggered in Frontend UI**: When the attendee selects seats on the arena layout and clicks **"Confirm Reservation"** in the drawer.

---

### 2. Stored Function: `fn_calculate_dynamic_pricing`
* **SQL Definition** (`database/04_plsql.sql`):
  ```sql
  CREATE OR REPLACE FUNCTION fn_calculate_dynamic_pricing(
      p_event_id INT,
      p_seat_id INT
  ) RETURNS NUMERIC ...
  ```
* **Invocation in Backend Code** (`src/app/api/pricing/route.ts` - Line 24):
  ```typescript
  // Dynamically computes price based on occupancy & seat multiplier
  const res = await db.query(
    `SELECT fn_calculate_dynamic_pricing($1, $2) AS dynamic_price;`,
    [eventId, seatId]
  );
  ```
* **Triggered in Frontend UI**: Whenever an attendee clicks any seat in the arena grid, a real-time price preview is fetched using this function.

---

### 3. Audit Trigger: `trg_audit_seat_status_change`
* **SQL Definition** (`database/04_plsql.sql`):
  ```sql
  CREATE TRIGGER trg_audit_seat_status_change
  AFTER INSERT OR UPDATE ON ticket_instances
  FOR EACH ROW
  EXECUTE FUNCTION fn_log_seat_status_audit();
  ```
* **Where it is Triggered**:
  - Automatically by PostgreSQL whenever an `INSERT` or `UPDATE` happens on `ticket_instances`.
  - In code: `src/app/api/triggers/route.ts` (Line 72) executes:
    ```sql
    UPDATE ticket_instances SET status = $1 WHERE ticket_id = $2;
    ```
    This immediately fires the trigger and logs the event into `seat_audit_logs`.

---

### 4. NoSQL JSONB Operations (`@>`, `jsonb_set`)
* **SQL Definition** (`database/05_nosql_vector.sql`):
  - Containment: `WHERE review_doc @> '{"vibe_tags": ["spiritual"]}'`
  - In-place Update: `SET review_doc = jsonb_set(review_doc, '{helpful_votes}', '45'::jsonb)`
* **Invocation in Backend Code** (`src/app/api/nosql/route.ts` - Line 28):
  - Route handlers perform GIN index lookup and update operations directly on `event_feedback_nosql`.

---

### 5. Vector Cosine Similarity Search
* **SQL Definition** (`database/05_nosql_vector.sql`):
  ```sql
  SELECT event_title, 
         ROUND(((cve.feature_vector[1]*u_vec[1] + ... + cve.feature_vector[5]*u_vec[5])
         / (SQRT(...) * SQRT(...)))::NUMERIC, 4) AS cosine_similarity
  FROM concert_vector_embeddings cve, user_target
  ORDER BY cosine_similarity DESC;
  ```
* **Invocation in Backend Code** (`src/app/api/vector-search/route.ts` - Line 25):
  - Computes audio preference matching vectors for user presets (`stadium_rock`, `acoustic_indie`, `sufi_orchestral`, `bhangra_party`).

