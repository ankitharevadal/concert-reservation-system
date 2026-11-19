# 🎯 PES University DBMS Mini-Project: 5-Minute Viva Defense Cheatsheet
## Project: Concert and Live Event Management & Intelligent Seat Reservation System

---

## ⏱️ PHASE 1: The 60-Second Opening Pitch (Say this directly to evaluator)

> "Good morning ma'am/sir. Our project is the **Concert & Live Event Management and Intelligent Seat Reservation System**.
> In live entertainment, systems like BookMyShow face massive concurrency spikes where thousands of fans race for the same seat. 
> To solve this, our system implements:
> 1. **Relational Core (PostgreSQL 3NF/BCNF)**: Strictly enforces ACID transactions, composite constraints, and cascade integrity.
> 2. **PL/SQL Stored Procedures**: Implements `sp_book_tickets_atomic` with row locking (`FOR UPDATE`) to eliminate double-booking race conditions.
> 3. **Dynamic Pricing Functions**: `fn_calculate_dynamic_pricing` updates seat rates in real-time based on venue occupancy thresholds.
> 4. **Triggers with Before/After Diff**: `trg_audit_seat_status_change` logs every seat lifecycle change into `seat_audit_logs`.
> 5. **NoSQL Document Layer (JSONB)**: Handles flexible artist technical riders and rich multi-tag fan reviews.
> 6. **Vector Search Engine**: Computes 5D cosine similarity embeddings matching user musical vibes to concert seats.
> 7. **Next.js Full-Stack App**: Has Role-Based Access Control (Admin vs Attendee) and an instant Evaluator Viva Showcase tab."

---

## 📋 PHASE 2: ER & Relational Schema Quick Defense (2 Minutes)

* **Strong Entities**: `USER_PROFILES`, `VENUES`, `ARTISTS`, `CONCERT_EVENTS`, `BOOKINGS`.
* **Weak Entities**: 
  - `SEATS` (Weak entity identified by its parent `VENUE`).
  - `TICKET_INSTANCES` (Associative weak entity dependent on `BOOKINGS` and `CONCERT_EVENTS`).
* **Attribute Types**:
  - **Derived Attributes**: 
    - `age` $\rightarrow$ calculated as `EXTRACT(YEAR FROM age(CURRENT_DATE, dob))`.
    - `available_seats` $\rightarrow$ calculated as `venue.total_capacity - COUNT(booked_tickets)`.
    - `total_booking_price` $\rightarrow$ calculated dynamically as sum of allocated tickets.
  - **Multi-Valued Attribute**: `Artist Genres` $\rightarrow$ normalized into `artist_genres(artist_id, genre)`.
  - **Composite Attribute**: `Address` $\rightarrow$ decomposed into `street_address`, `city`, `state`, `postal_code`.
* **Normalization**: The entire schema is strictly in **3NF and BCNF** because every determinant is a superkey.

---

## ⚡ PHASE 3: DDL & DML Commands (1 Minute)

* **All DDL Commands**: Located in file `database/01_ddl.sql`
* **If she asks to see CREATE TABLE for one**:
  - Open `database/01_ddl.sql` and show `ticket_instances` or `concert_events`!
  - Point out the constraints:
    - `CONSTRAINT unq_event_seat_booking UNIQUE (event_id, seat_id)` (Crucial constraint: prevents duplicate seat bookings!)
    - `CONSTRAINT chk_event_duration CHECK (duration_minutes >= 30 AND duration_minutes <= 600)`
    - `CONSTRAINT fk_ticket_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE`
* **All DML Commands**: Located in file `database/02_dml.sql` (Seed data for artists, venues, concerts, seats, and bookings).

---

## 🔍 PHASE 4: The 4 Advanced Queries (Joins, Nested, Correlated, Recursive CTE)

Located in `database/03_joins_nested_cte.sql`:
1. **4-Table Join with Left Outer Join**:
   - Joins `bookings`, `user_profiles`, `concert_events`, `artists`, `venues`, `ticket_instances`, and `seats` to display complete attendee tickets.
2. **Nested Subquery (HAVING + Aggregation)**:
   - Finds users whose total spending exceeds the overall system-wide average booking value.
3. **Correlated Subquery**:
   - `WHERE c1.base_ticket_price > (SELECT AVG(c2.base_ticket_price) FROM concert_events c2 WHERE c2.venue_id = c1.venue_id)`
   - Correlated because inner query filters on `c2.venue_id = c1.venue_id`.
4. **Recursive CTE (WITH RECURSIVE)**:
   - Generates the hierarchical 4-level seat tier pricing ladder (`BRONZE` $\rightarrow$ `SILVER` $\rightarrow$ `GOLD` $\rightarrow$ `VIP`) with dynamic multiplier escalation.

---

## 🛡️ PHASE 5: Trigger — Show Before vs After Diff!

* **Trigger File**: `database/04_plsql.sql` (Lines 11–60)
* **Trigger Name**: `trg_audit_seat_status_change`
* **Audit Table**: `seat_audit_logs`

### Step-by-Step Viva Execution:
1. **Show existing logs**:
   ```sql
   SELECT log_id, seat_id, action_type, old_status, new_status, change_timestamp 
   FROM seat_audit_logs ORDER BY log_id DESC LIMIT 2;
   ```
2. **Execute an UPDATE**:
   ```sql
   UPDATE ticket_instances SET status = 'CHECKED_IN' WHERE ticket_id = 1;
   ```
3. **Show the AFTER Diff**:
   ```sql
   SELECT log_id, seat_id, action_type, old_status, new_status, change_timestamp 
   FROM seat_audit_logs ORDER BY log_id DESC LIMIT 1;
   ```
   👉 **Point to evaluator**: *"Notice row 1: `old_status` was 'RESERVED', and `new_status` is now 'CHECKED_IN'. The trigger recorded this automatically without application intervention!"*

---

## 📍 PHASE 6: Stored Procedure & Function — Exact Code Locations!

Evaluator rule: *"Show where the invocation of that is in your code — you can't search for it at that time!"*

### 1. Stored Function: `fn_calculate_dynamic_pricing`
* **Definition Location**: `database/04_plsql.sql` (Lines 75–125)
* **Invocation Location in Backend Code**:
  - File: `src/app/api/pricing/route.ts` (Line 24)
  - Also called internally inside `sp_book_tickets_atomic` (Line 150)
* **What it does**: Computes dynamic surge pricing based on current venue occupancy rate (surge factor increases when $>50\%$ and $>75\%$ booked).

### 2. Stored Procedure: `sp_book_tickets_atomic`
* **Definition Location**: `database/04_plsql.sql` (Lines 135–185)
* **Invocation Location in Backend Code**:
  - File: `src/app/api/bookings/route.ts` (Line 42)
  - Next.js UI Frontend: Triggered when user clicks **"Confirm Reservation"** on the seat map.
* **What it does**: Atomically locks seat row (`FOR UPDATE`), prevents concurrent booking collisions, creates booking header and ticket instance in a single transaction.

---

## 🌐 PHASE 7: NoSQL Document Queries & Vector Similarity

Located in `database/05_nosql_vector.sql`:

### 1. NoSQL (JSONB Document Store):
* **CREATE**: Inserts nested JSON technical riders and fan reviews.
* **READ (Containment query)**:
  ```sql
  SELECT review_doc->>'reviewer', review_doc->>'comment'
  FROM event_feedback_nosql
  WHERE review_doc @> '{"vibe_tags": ["spiritual"]}';
  ```
* **UPDATE (jsonb_set)**:
  ```sql
  UPDATE event_feedback_nosql 
  SET review_doc = jsonb_set(review_doc, '{helpful_votes}', '35'::jsonb) 
  WHERE feedback_id = 1;
  ```
* **DELETE**:
  ```sql
  DELETE FROM event_feedback_nosql WHERE feedback_id = 999;
  ```

### 2. Vector Similarity Query (5D Audio Feature Space):
* Features: `[Energy, Acousticness, Danceability, Valence, Crowd Scale]`
* User query vector: `[0.30, 0.90, 0.35, 0.50, 0.30]` (Calm, intimate, acoustic vibe)
* Cosine Similarity calculation ranks **Prateek Kuhad: Silhouettes Under the Stars** at 0.992 similarity!

---

## 🔐 PHASE 8: Authentication & Database RBAC

Located in `database/06_rbac_roles.sql`:
* **Role 1**: `organizer_admin_role`
  - Has `SELECT, INSERT, UPDATE, DELETE` on concerts, venues, seats, and riders.
* **Role 2**: `attendee_customer_role`
  - Has `SELECT` on concerts and seats.
  - Can only `INSERT` into bookings.
  - Row Level Security (RLS) ensures attendees can only read their own bookings:
    `CREATE POLICY customer_view_own_bookings ON bookings FOR SELECT TO attendee_customer_role USING (user_id = CURRENT_SETTING('app.current_user_id', true)::INT);`
