# 📋 Complete DDL & Constraints Cheatsheet (For Teacher Evaluation)
## Project: Concert & Live Event Management & Intelligent Arena Reservation System

---

## 🏛️ 1. Master Entity & DDL Table Summary

| Table Name | Entity Classification | Primary Key | Foreign Keys & Actions | Key Constraints |
| :--- | :--- | :--- | :--- | :--- |
| **`user_profiles`** | Strong Entity | `user_id` (SERIAL) | None | `UNIQUE (email)`, `CHECK (role IN ('ADMIN', 'ORGANIZER', 'CUSTOMER'))`, `CHECK (date_of_birth <= CURRENT_DATE)` |
| **`venues`** | Strong Entity | `venue_id` (SERIAL) | None | `CHECK (total_capacity > 0)`, Decomposed composite address (`street_address`, `city`, `state`, `postal_code`) |
| **`artists`** | Strong Entity | `artist_id` (SERIAL) | None | `UNIQUE (stage_name)`, `CHECK (billing_rate_per_hour >= 0.00)` |
| **`artist_genres`** | Normalized Multi-Valued Attribute | `(artist_id, genre)` | `artist_id -> artists(artist_id) ON DELETE CASCADE` | Composite Primary Key |
| **`concert_events`** | Strong Entity | `event_id` (SERIAL) | `artist_id -> artists ON DELETE RESTRICT`, `venue_id -> venues ON DELETE RESTRICT` | `CHECK (duration_minutes BETWEEN 30 AND 600)`, `CHECK (base_ticket_price > 0)`, `CHECK (event_status IN (...))` |
| **`seats`** | Weak Entity | `seat_id` (SERIAL) | `venue_id -> venues(venue_id) ON DELETE CASCADE` | `UNIQUE (venue_id, section_name, seat_row, seat_number)`, `CHECK (section_name IN (...))`, `CHECK (price_multiplier BETWEEN 1.00 AND 5.00)` |
| **`bookings`** | Strong Entity | `booking_id` (SERIAL) | `user_id -> user_profiles ON DELETE CASCADE`, `event_id -> concert_events ON DELETE RESTRICT` | `UNIQUE (booking_reference)`, `CHECK (total_amount >= 0.00)`, `CHECK (booking_status IN (...))` |
| **`ticket_instances`** | Weak Associative Entity | `ticket_id` (SERIAL) | `booking_id -> bookings ON DELETE CASCADE`, `event_id -> concert_events ON DELETE RESTRICT`, `seat_id -> seats ON DELETE RESTRICT` | **`UNIQUE (event_id, seat_id)`** (Prevents double bookings!), `UNIQUE (barcode_hash)`, `CHECK (allocated_price > 0)` |
| **`seat_audit_logs`** | Audit Trail Table | `log_id` (SERIAL) | None (loose linkage to preserve deleted logs) | Target for Database Trigger `trg_audit_seat_status_change` |
| **`event_feedback_nosql`** | NoSQL Document Store | `feedback_id` (SERIAL) | `event_id -> concert_events ON DELETE CASCADE`, `user_id -> user_profiles ON DELETE CASCADE` | Stores PostgreSQL `JSONB` with GIN Index |
| **`concert_vector_embeddings`** | Vector Embedding Store | `embedding_id` (SERIAL) | `event_id -> concert_events ON DELETE CASCADE` | 5D float vector array `FLOAT8[]` for Cosine Similarity search |

---

## 🔒 2. The 6 Types of SQL Constraints (Have this ready to speak to her!)

### 1. Primary Key Constraints:
* Single-column: `user_id`, `event_id`, `venue_id`, `booking_id`, `ticket_id`.
* Composite Primary Key: `artist_genres(artist_id, genre)` — normalizes multi-valued artist genres.

### 2. Foreign Key Constraints with Integrity Actions:
* **`ON DELETE CASCADE`**: Used when child records have no independent reason to exist if the parent is deleted:
  - If a `venue` is deleted, its `seats` are deleted (`ON DELETE CASCADE`).
  - If a `booking` is deleted, its `ticket_instances` are deleted (`ON DELETE CASCADE`).
  - If an `artist` is deleted, their `artist_genres` are deleted (`ON DELETE CASCADE`).
* **`ON DELETE RESTRICT`**: Used to prevent critical business errors:
  - `concert_events` references `artists(artist_id) ON DELETE RESTRICT`: Prevents an artist from being deleted if they have active scheduled concerts!
  - `bookings` references `concert_events(event_id) ON DELETE RESTRICT`: Prevents deleting a concert if fans have already purchased bookings!

### 3. Unique Constraints (Candidate Keys & Concurrency Protection):
* `UNIQUE (email)` in `user_profiles`.
* `UNIQUE (stage_name)` in `artists`.
* `UNIQUE (booking_reference)` in `bookings`.
* `UNIQUE (barcode_hash)` in `ticket_instances`.
* **`UNIQUE (event_id, seat_id)` in `ticket_instances`**:
  - 👉 **Point out to her**: *"This is our core concurrency defense constraint. Even if 100 threads bypass application checks, the database engine will reject any attempt to insert a duplicate (event_id, seat_id) with an immediate uniqueness violation!"*

### 4. Domain Check Constraints (`CHECK`):
* `CHECK (role IN ('ADMIN', 'ORGANIZER', 'CUSTOMER'))`
* `CHECK (date_of_birth <= CURRENT_DATE)`
* `CHECK (total_capacity > 0)`
* `CHECK (duration_minutes >= 30 AND duration_minutes <= 600)`
* `CHECK (base_ticket_price > 0)`
* `CHECK (price_multiplier >= 1.00 AND price_multiplier <= 5.00)`
* `CHECK (section_name IN ('VIP_LOUNGE', 'GOLD_FRONT', 'SILVER_MIDDLE', 'BRONZE_BALCONY'))`

### 5. Not Null Constraints:
* Enforced on all non-optional business fields (`event_title`, `allocated_price`, `event_date_time`, etc.).

### 6. Default Constraints:
* `DEFAULT CURRENT_TIMESTAMP` for timestamps.
* `DEFAULT 'CUSTOMER'` for user roles.
* `DEFAULT 'SCHEDULED'` for events.
* `DEFAULT 1.00` for seat tier multipliers.

---

## ⚡ 3. Indexes & Views DDL

### Indexes:
* **Foreign Key B-Tree Indexes**: `idx_concert_venue`, `idx_concert_artist`, `idx_booking_user`, `idx_ticket_event_seat`.
* **GIN Inverted Index**: `idx_gin_review_doc ON event_feedback_nosql USING gin (review_doc)` for O(1) nested JSONB tag searches.

### Views:
* **`v_event_occupancy_summary`**: Aggregates capacity, booked tickets, remaining seats, and occupancy percentage.
* **`v_attendee_confirmed_tickets`**: Multi-table security view joining attendee profiles, venues, seats, and barcode passes.

