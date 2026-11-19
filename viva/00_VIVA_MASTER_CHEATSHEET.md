# 🎓 DBMS Mini-Project: 5-Minute Viva Defense Master Cheatsheet
## Project: Concert & Live Event Management & Intelligent Arena Reservation System

---

## ⏱️ 1. The 60-Second Opening Pitch (Say this directly to the evaluator)

> "Good morning ma'am. Our project is the **Concert and Live Event Management & Intelligent Seat Reservation System**.
> 
> In real-world ticketing platforms like BookMyShow, high-demand concert sales create massive race conditions where thousands of concurrent fans try to grab the exact same seat at the same millisecond. 
> 
> To solve this with database-level guarantees, our system implements:
> 1. **A Normalized Relational Core (PostgreSQL 3NF/BCNF)** with strict composite keys and cascading integrity.
> 2. **An Atomic Stored Procedure** (`sp_book_tickets_atomic`) utilizing row-level locks (`FOR UPDATE`) to mathematically eliminate double-booking race conditions.
> 3. **A Dynamic Pricing Stored Function** (`fn_calculate_dynamic_pricing`) that dynamically surges seat prices based on real-time venue occupancy thresholds.
> 4. **An Audit Trigger** (`trg_audit_seat_status_change`) that automatically records the exact BEFORE vs AFTER state changes whenever a ticket status transitions.
> 5. **A NoSQL Document Layer (JSONB)** with GIN indexing for flexible artist technical riders and multi-tag fan reviews.
> 6. **A 5-Dimensional Vector Search Engine** computing Cosine Similarity to recommend optimal concert seats matched to attendee music preferences.
> 7. **Database Role-Based Access Control (RBAC)** enforcing Row-Level Security (RLS) separating Event Organizers from Ticket Attendees."

---

## 📋 2. Entity & Attribute Classification Table (Have this ready to show her)

| Classification | Database Entity / Attribute | Rationale / Explanation |
| :--- | :--- | :--- |
| **Strong Entities** | `user_profiles`, `venues`, `artists`, `concert_events`, `bookings` | Have their own independent primary keys; exist without depending on other entities. |
| **Weak Entity 1** | `seats` | Cannot exist without a parent `venue`. Weak entity identified via composite key `(venue_id, section_name, seat_row, seat_number)`. |
| **Weak Entity 2** | `ticket_instances` | Associative weak entity dependent on `bookings` and `concert_events`. |
| **Derived Attribute 1** | `age` | Computed dynamically from `date_of_birth` as `EXTRACT(YEAR FROM age(CURRENT_DATE, dob))`. Never redundantly stored. |
| **Derived Attribute 2** | `available_seats` | Dynamically calculated as `venue.total_capacity - COUNT(booked_tickets)`. |
| **Derived Attribute 3** | `total_amount` | Calculated as the aggregate sum of individual ticket allocated prices. |
| **Multi-Valued Attribute** | `artist_genres` | An artist performs multiple genres (e.g. Sufi, World Fusion). Normalized into child table `artist_genres(artist_id, genre)`. |
| **Composite Attribute** | `Address` | Decomposed into 4 atomic fields: `street_address`, `city`, `state`, `postal_code` in table `venues`. |

---

## 📋 3. DDL Commands & Constraints Defense (Show her `viva/01_ALL_DDL_COMMANDS_WITH_CONSTRAINTS.sql`)

* **All DDL Commands**: Located in file `viva/01_ALL_DDL_COMMANDS_WITH_CONSTRAINTS.sql` (and `database/01_ddl.sql`).
* **If she asks to see CREATE TABLE for any entity**:
  - Open `viva/01_ALL_DDL_COMMANDS_WITH_CONSTRAINTS.sql` or run `npm run viva` -> Option 8!
  - Point out the 6 types of constraints:
    1. **Primary Keys**: Single column (`user_id`, `venue_id`, `event_id`, `booking_id`) and Composite (`PRIMARY KEY (artist_id, genre)`).
    2. **Foreign Keys with Cascade Rules**:
       - `ON DELETE CASCADE`: Used for child relations (`seats`, `ticket_instances`, `artist_genres`) where child records cannot exist without parent.
       - `ON DELETE RESTRICT`: Used on `concert_events(artist_id)` and `bookings(event_id)` to prevent accidental deletion of scheduled shows with bookings!
    3. **Concurrency Uniqueness Lock**:
       - `CONSTRAINT unq_event_seat_booking UNIQUE (event_id, seat_id)` in `ticket_instances`. Guarantees zero duplicate seat reservations under race conditions!
    4. **Domain Check Constraints**:
       - `CHECK (duration_minutes BETWEEN 30 AND 600)`
       - `CHECK (base_ticket_price > 0)`
       - `CHECK (price_multiplier BETWEEN 1.00 AND 5.00)`
       - `CHECK (date_of_birth <= CURRENT_DATE)`
       - `CHECK (role IN ('ADMIN', 'ORGANIZER', 'CUSTOMER'))`
    5. **Indexes (B-tree & GIN)**: B-tree on FKs; GIN index on `event_feedback_nosql(review_doc)` for NoSQL containment.
    6. **Views**: `v_event_occupancy_summary` and `v_attendee_confirmed_tickets`.

---

## ⚡ 4. Normalization Defense (Why 3NF and BCNF?)

* **1NF**: Every column contains atomic (indivisible) values. No repeating groups (e.g., `artist_genres` separated into its own table).
* **2NF**: It is in 1NF, and there are NO partial functional dependencies. In composite key tables like `artist_genres(artist_id, genre)` and `seats(venue_id, section, row, num)`, every non-prime attribute is fully dependent on the whole candidate key.
* **3NF**: It is in 2NF, and there are NO transitive dependencies ($X \rightarrow Y$ and $Y \rightarrow Z$). Non-key attributes depend ONLY on superkeys.
* **BCNF**: For every non-trivial functional dependency $X \rightarrow Y$, $X$ is a superkey.

---

## 🔍 4. The 4 Advanced Queries Walkthrough

Show her file: `viva/05_ADVANCED_QUERIES_DEMO.sql`:
1. **Multi-Table Join with Outer Join**: Joins 7 tables (`bookings`, `user_profiles`, `concert_events`, `artists`, `venues`, `ticket_instances`, `seats`) with a `LEFT JOIN` on feedback to view full attendee itineraries.
2. **Nested Subquery (HAVING + Aggregation)**: Filters high-value attendees whose total spend is strictly greater than the platform-wide average booking value.
3. **Correlated Subquery**: Identifies premier concert events whose base ticket price exceeds the average ticket price for events held at *that specific venue* (`WHERE c2.venue_id = c1.venue_id`).
4. **Recursive CTE (`WITH RECURSIVE`)**: Models the hierarchical 4-tier seat pricing ladder (`BRONZE` $\rightarrow$ `SILVER` $\rightarrow$ `GOLD` $\rightarrow$ `VIP`), dynamically calculating compound price escalation.

---

## 🛡️ 5. Trigger: Exact BEFORE vs AFTER Demonstration

Show her file: `viva/03_TRIGGER_BEFORE_AFTER_DEMO.sql` or run `npm run viva` -> Option 1:
* **Trigger Name**: `trg_audit_seat_status_change`
* **Target Table**: `ticket_instances`
* **Audit Table**: `seat_audit_logs`
* **How to demonstrate**:
  1. Show existing ticket #1: Status is `'RESERVED'`.
  2. Execute: `UPDATE ticket_instances SET status = 'CHECKED_IN' WHERE ticket_id = 1;`
  3. Query `seat_audit_logs`: Point to the new row where `old_status = 'RESERVED'` and `new_status = 'CHECKED_IN'`, timestamped by the database automatically.

---

## 📍 6. Stored Procedure & Function Invocation Pointers

Show her file: `viva/01_CODE_INVOCATION_POINTERS.md`:
* **Stored Function**: `fn_calculate_dynamic_pricing`
  - SQL Definition: `database/04_plsql.sql` (Line 75)
  - Backend API Call: `src/app/api/pricing/route.ts` (Line 24)
  - Also called internally inside `sp_book_tickets_atomic` (Line 150)
* **Stored Procedure**: `sp_book_tickets_atomic`
  - SQL Definition: `database/04_plsql.sql` (Line 135)
  - Backend API Call: `src/app/api/bookings/route.ts` (Line 42)
  - Frontend Invocation: Triggered when user confirms reservation in the seat selection drawer.

---

## 🌐 7. NoSQL & Vector Search Rationale

* **Why NoSQL (JSONB) in PostgreSQL?**
  - Flexible schema for artist technical riders (sound equipment, lighting configurations) and fan reviews with dynamic multi-tag vibes.
  - Query with `@>` (containment) using GIN inverted indexing.
  - In-place mutation with `jsonb_set()`.
* **Why Vector Cosine Similarity?**
  - High-dimensional acoustic matching: Maps 5 audio dimensions: `[Energy, Acousticness, Danceability, Valence, Stadium Scale]`.
  - Calculates $\cos(\theta) = \frac{A \cdot B}{\|A\| \|B\|}$ to rank concerts by attendee musical taste.

