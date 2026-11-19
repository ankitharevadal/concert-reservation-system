# PES University - Department of Computer Science & Engineering
## Experiential Learning Level 3 - DBMS Mini-Project
### Relational Schema Specification & Normalization Proof
### Project: Concert and Live Event Management & Intelligent Seat Reservation System

---

## 1. Formal Relational Schema Definition

In the notation below:
- **`[PK]`**: Primary Key (Underlined in hard-copy)
- **`[FK]`**: Foreign Key (Dashed underlined in hard-copy)
- **`[UQ]`**: Unique Key constraint
- **`[CHK]`**: Check constraint

---

### Relation 1: `USER_PROFILES`
$$\text{USER\_PROFILES}(\underline{\text{user\_id}}, \text{full\_name}, \text{email}^{\text{UQ}}, \text{password\_hash}, \text{phone\_number}, \text{role}^{\text{CHK}}, \text{date\_of\_birth}^{\text{CHK}}, \text{created\_at})$$
* **Primary Key**: `user_id`
* **Alternate/Candidate Key**: `email`
* **Constraints**:
  - `role IN ('ADMIN', 'ORGANIZER', 'CUSTOMER')`
  - `date_of_birth <= CURRENT_DATE`
  - `full_name`, `email`, `password_hash`, `role`, `date_of_birth` are `NOT NULL`.

---

### Relation 2: `VENUES`
$$\text{VENUES}(\underline{\text{venue\_id}}, \text{venue\_name}, \text{street\_address}, \text{city}, \text{state}, \text{postal\_code}, \text{total\_capacity}^{\text{CHK}}, \text{contact\_email}, \text{created\_at})$$
* **Primary Key**: `venue_id`
* **Composite Address Breakdown**: `(street_address, city, state, postal_code)`
* **Constraints**:
  - `total_capacity > 0`
  - All attributes are `NOT NULL`.

---

### Relation 3: `ARTISTS`
$$\text{ARTISTS}(\underline{\text{artist\_id}}, \text{stage\_name}^{\text{UQ}}, \text{bio}, \text{country\_of\_origin}, \text{billing\_rate\_per\_hour}^{\text{CHK}}, \text{created\_at})$$
* **Primary Key**: `artist_id`
* **Candidate Key**: `stage_name`
* **Constraints**:
  - `billing_rate_per_hour >= 0.00`
  - `stage_name` is `NOT NULL` and `UNIQUE`.

---

### Relation 4: `ARTIST_GENRES` (Normalized Multi-valued Relation)
$$\text{ARTIST\_GENRES}(\underline{\text{artist\_id}^{\text{FK}}, \text{genre}})$$
* **Composite Primary Key**: `(artist_id, genre)`
* **Foreign Key**: `artist_id` references `ARTISTS(artist_id)` ON DELETE CASCADE.
* **Integrity**: Eliminates multi-valued repetition, enforcing 1NF.

---

### Relation 5: `CONCERT_EVENTS`
$$\text{CONCERT\_EVENTS}(\underline{\text{event\_id}}, \text{event\_title}, \text{event\_description}, \text{artist\_id}^{\text{FK}}, \text{venue\_id}^{\text{FK}}, \text{event\_date\_time}, \text{duration\_minutes}^{\text{CHK}}, \text{base\_ticket\_price}^{\text{CHK}}, \text{event\_status}^{\text{CHK}}, \text{created\_at})$$
* **Primary Key**: `event_id`
* **Foreign Keys**:
  - `artist_id` references `ARTISTS(artist_id)` ON DELETE RESTRICT
  - `venue_id` references `VENUES(venue_id)` ON DELETE RESTRICT
* **Constraints**:
  - `duration_minutes BETWEEN 30 AND 600`
  - `base_ticket_price > 0`
  - `event_status IN ('SCHEDULED', 'ONGOING', 'COMPLETED', 'CANCELLED')`

---

### Relation 6: `SEATS` (Weak Entity)
$$\text{SEATS}(\underline{\text{seat\_id}}, \text{venue\_id}^{\text{FK}}, \text{section\_name}^{\text{CHK}}, \text{seat\_row}, \text{seat\_number}^{\text{CHK}}, \text{price\_multiplier}^{\text{CHK}})$$
* **Primary Key**: `seat_id` (Surrogate integer key)
* **Natural Composite Unique Key**: `(venue_id, section_name, seat_row, seat_number)`
* **Foreign Key**: `venue_id` references `VENUES(venue_id)` ON DELETE CASCADE
* **Constraints**:
  - `section_name IN ('VIP_LOUNGE', 'GOLD_FRONT', 'SILVER_MIDDLE', 'BRONZE_BALCONY')`
  - `seat_number > 0`
  - `price_multiplier BETWEEN 1.00 AND 5.00`

---

### Relation 7: `BOOKINGS`
$$\text{BOOKINGS}(\underline{\text{booking\_id}}, \text{booking\_reference}^{\text{UQ}}, \text{user\_id}^{\text{FK}}, \text{event\_id}^{\text{FK}}, \text{booking\_timestamp}, \text{total\_amount}^{\text{CHK}}, \text{booking\_status}^{\text{CHK}}, \text{payment\_method}^{\text{CHK}})$$
* **Primary Key**: `booking_id`
* **Candidate Key**: `booking_reference`
* **Foreign Keys**:
  - `user_id` references `USER_PROFILES(user_id)` ON DELETE CASCADE
  - `event_id` references `CONCERT_EVENTS(event_id)` ON DELETE RESTRICT
* **Constraints**:
  - `total_amount >= 0.00`
  - `booking_status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'REFUNDED')`
  - `payment_method IN ('UPI', 'CREDIT_CARD', 'DEBIT_CARD', 'NET_BANKING')`

---

### Relation 8: `TICKET_INSTANCES` (Associative Ticket Allocation)
$$\text{TICKET\_INSTANCES}(\underline{\text{ticket\_id}}, \text{booking\_id}^{\text{FK}}, \text{event\_id}^{\text{FK}}, \text{seat\_id}^{\text{FK}}, \text{allocated\_price}^{\text{CHK}}, \text{barcode\_hash}^{\text{UQ}}, \text{status}^{\text{CHK}}, \text{created\_at})$$
* **Primary Key**: `ticket_id`
* **Candidate Key**: `barcode_hash`
* **Business Concurrency Key**: `UNIQUE(event_id, seat_id)` $\rightarrow$ **Guarantees that a seat cannot be double-booked for the same concert event!**
* **Foreign Keys**:
  - `booking_id` references `BOOKINGS(booking_id)` ON DELETE CASCADE
  - `event_id` references `CONCERT_EVENTS(event_id)` ON DELETE RESTRICT
  - `seat_id` references `SEATS(seat_id)` ON DELETE RESTRICT
* **Constraints**:
  - `allocated_price > 0`
  - `status IN ('RESERVED', 'CHECKED_IN', 'CANCELLED')`

---

### Relation 9: `SEAT_AUDIT_LOGS` (Trigger Target)
$$\text{SEAT\_AUDIT\_LOGS}(\underline{\text{log\_id}}, \text{ticket\_id}^{\text{FK}}, \text{event\_id}, \text{seat\_id}, \text{action\_type}, \text{old\_status}, \text{new\_status}, \text{old\_price}, \text{new\_price}, \text{changed\_by}, \text{change\_timestamp})$$
* **Primary Key**: `log_id`
* **Purpose**: Populated dynamically by trigger `trg_audit_seat_status_change` to trace seat transitions.

---

### Relation 10: `EVENT_RIDERS_NOSQL` (Document Store)
$$\text{EVENT\_RIDERS\_NOSQL}(\underline{\text{document\_id}}, \text{event\_id}^{\text{FK}}, \text{document\_type}, \text{metadata\_json}, \text{created\_at})$$
* **Primary Key**: `document_id`
* **Foreign Key**: `event_id` references `CONCERT_EVENTS(event_id)` ON DELETE CASCADE
* **Purpose**: Semi-structured JSONB document store indexed via GIN.

---

## 2. Normalization Analysis & Proof

### A. First Normal Form (1NF) Compliance
* **Condition**: Every attribute value must be atomic (no repeating groups, sets, or nested relations).
* **Proof**: 
  - The multi-valued attribute `Artist_Genres` is decomposed into an independent table `ARTIST_GENRES(artist_id, genre)`.
  - Composite attribute `Address` is decomposed into atomic components (`street_address`, `city`, `state`, `postal_code`).
  - No comma-separated strings or nested arrays exist in the relational tables.

### B. Second Normal Form (2NF) Compliance
* **Condition**: Must be in 1NF, and every non-prime attribute must be fully functionally dependent on the entire candidate key (no partial functional dependencies).
* **Proof**:
  - For tables with single-attribute primary keys (`user_id`, `venue_id`, `artist_id`, `event_id`, `booking_id`), partial dependency is mathematically impossible.
  - In `ARTIST_GENRES(artist_id, genre)`, both attributes form the composite primary key; there are no non-prime attributes.
  - In `SEATS`, the primary key is `seat_id`. The natural key `(venue_id, section_name, seat_row, seat_number)` determines `price_multiplier`, with no partial dependency on a subset of the key.

### C. Third Normal Form (3NF) Compliance
* **Condition**: Must be in 2NF, and no non-prime attribute should be transitively dependent on any candidate key ($X \rightarrow Y$ must satisfy: $X$ is a superkey, or $Y$ is a prime attribute).
* **Proof**:
  - In `CONCERT_EVENTS`, `venue_id` is a foreign key. The event table does NOT store `venue_name` or `total_capacity` (which would cause transitive dependency `event_id -> venue_id -> total_capacity`).
  - In `BOOKINGS`, `user_id` is stored, but customer name and email are kept strictly in `USER_PROFILES`.
  - Derived attributes such as `age` and `available_seats` are computed on-the-fly and never statically duplicated.

### D. Boyce-Codd Normal Form (BCNF) Compliance
* **Condition**: For every non-trivial functional dependency $X \rightarrow Y$, $X$ must be a superkey.
* **Proof**:
  - In all relations, the left-hand side of every functional dependency is a candidate key (`user_id`, `email`, `booking_id`, `booking_reference`, `ticket_id`, `barcode_hash`).
  - Therefore, the schema is strictly in **BCNF**.
