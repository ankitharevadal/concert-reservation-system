# 📊 ER & Relational Schema Specification
## DBMS Mini-Project Defense Specification

---

## 🏛️ 1. Entity Classification

### A. Strong Entities
Strong entities exist independently in the schema and possess their own primary keys:
1. **`USER_PROFILES`**:
   - Primary Key: `user_id`
   - Unique: `email`
   - Role: Represents customers, event organizers, and administrators.
2. **`VENUES`**:
   - Primary Key: `venue_id`
   - Attributes: Name, address components, capacity, contact info.
3. **`ARTISTS`**:
   - Primary Key: `artist_id`
   - Unique: `stage_name`
   - Attributes: Bio, country of origin, billing rate per hour.
4. **`CONCERT_EVENTS`**:
   - Primary Key: `event_id`
   - Attributes: Title, date/time, duration, base price, status.
5. **`BOOKINGS`**:
   - Primary Key: `booking_id`
   - Unique: `booking_reference`
   - Attributes: Timestamp, total amount, payment method, booking status.

### B. Weak Entities & Identifying Relationships
1. **`SEATS` (Weak Entity)**:
   - **Parent Entity**: `VENUES`
   - **Identifying Relationship**: A seat cannot exist without an arena/venue. Seat "Row A, Seat 1" is meaningless without knowing *which venue* it belongs to.
   - **Composite Key / Identifying Key**: `(venue_id, section_name, seat_row, seat_number)`
   - **Constraint**: `FOREIGN KEY (venue_id) REFERENCES venues(venue_id) ON DELETE CASCADE`
2. **`TICKET_INSTANCES` (Associative Weak Entity)**:
   - **Parent Entities**: `BOOKINGS` and `CONCERT_EVENTS`
   - **Identifying Logic**: A ticket instance represents the allocation of a specific seat for a specific concert event inside a confirmed booking transaction.
   - **Concurrency Constraint**: `CONSTRAINT unq_event_seat_booking UNIQUE (event_id, seat_id)` (prevents double-booking).

---

## 🏷️ 2. Attribute Classification

| Attribute Type | Column Name & Table | Reason / Formula |
| :--- | :--- | :--- |
| **Simple / Atomic** | `event_title` in `concert_events` | Cannot be further divided; atomic textual value. |
| **Composite** | `Address` in `venues` | Decomposed into 4 atomic fields: `street_address`, `city`, `state`, `postal_code`. |
| **Multi-Valued** | `genre` in `artists` | An artist performs in multiple genres. Normalized into table `artist_genres(artist_id, genre)` to eliminate multivalued repeating groups. |
| **Derived 1** | `age` in `user_profiles` | Calculated dynamically from `date_of_birth`: `EXTRACT(YEAR FROM age(CURRENT_DATE, date_of_birth))`. Never stored to avoid update anomalies. |
| **Derived 2** | `available_seats` in `concert_events` | Calculated as: `venue.total_capacity - (SELECT COUNT(*) FROM ticket_instances WHERE event_id = c.event_id AND status != 'CANCELLED')`. |
| **Derived 3** | `total_amount` in `bookings` | Calculated dynamically as: `SUM(allocated_price)` for all tickets within the booking. |

---

## 📐 3. Normalization Walkthrough (1NF to BCNF)

### 1NF (First Normal Form)
* Every column contains only atomic, non-divisible values.
* Multi-valued attribute `genres` is separated into `artist_genres(artist_id, genre)` with composite primary key `(artist_id, genre)`.
* Repeating groups of seats are normalized into independent rows in `seats`.

### 2NF (Second Normal Form)
* Must be in 1NF and contain NO partial dependencies on candidate keys.
* In all tables with composite keys:
  - `artist_genres(artist_id, genre)`: Both columns form the PK; there are no non-prime attributes to be partially dependent.
  - `seats(venue_id, section_name, seat_row, seat_number)`: `price_multiplier` depends on the seat's specific row and section, meaning it depends on the full composite key.

### 3NF (Third Normal Form)
* Must be in 2NF and contain NO transitive dependencies ($X \rightarrow Y$ and $Y \rightarrow Z$).
* In `concert_events`, artist details (such as `billing_rate_per_hour`) are NOT stored directly. Only `artist_id` (FK) is referenced. This prevents $event\_id \rightarrow artist\_id \rightarrow billing\_rate$.
* In `venues`, city and state are kept atomic without transitive venue dependencies.

### BCNF (Boyce-Codd Normal Form)
* For every non-trivial functional dependency $X \rightarrow Y$, the determinant $X$ MUST be a superkey.
* In every relation:
  - `user_profiles`: `user_id` is PK; `email` is UNIQUE (both superkeys).
  - `venues`: `venue_id` is PK.
  - `concert_events`: `event_id` is PK.
  - `bookings`: `booking_id` is PK; `booking_reference` is UNIQUE (both superkeys).
  - `ticket_instances`: `ticket_id` is PK; `barcode_hash` is UNIQUE; `(event_id, seat_id)` is UNIQUE (all determinants are superkeys).
* Hence, the entire relational schema satisfies **BCNF**.

