# PES University - Department of Computer Science & Engineering
## Experiential Learning Level 3 - DBMS Mini-Project
### Project Title: Concert and Live Event Management & Intelligent Seat Reservation System

---

## 1. Executive Summary & Architecture Overview
The **Concert and Live Event Management & Intelligent Seat Reservation System** models a high-throughput, mission-critical event management ecosystem. It supports multiple live concert venues, multi-genre performers, multi-tier seating topologies, dynamic surge pricing, atomic seat reservations to eliminate concurrency conflicts, and an intelligent recommendation engine.

---

## 2. ER Diagram Specification & Entity Classification

```mermaid
erDiagram
    USER ||--o{ BOOKING : "places (1:N)"
    VENUE ||--|{ SEAT : "contains (1:N, identifying)"
    VENUE ||--o{ CONCERT_EVENT : "hosts (1:N)"
    ARTIST ||--o{ CONCERT_EVENT : "performs in (1:N)"
    ARTIST ||--|{ ARTIST_GENRE : "has (1:N, multivalued)"
    CONCERT_EVENT ||--o{ BOOKING : "booked for (1:N)"
    BOOKING ||--|{ TICKET_INSTANCE : "allocates (1:N)"
    SEAT ||--o{ TICKET_INSTANCE : "reserved as (1:N)"
    CONCERT_EVENT ||--o{ EVENT_RIDER_NOSQL : "specifies (1:N)"
    TICKET_INSTANCE ||--o{ SEAT_AUDIT_LOG : "triggers audit (1:N)"

    USER {
        int user_id PK
        string full_name
        string email UK
        string password_hash
        string phone_number
        string role "ADMIN | ORGANIZER | CUSTOMER"
        date date_of_birth
        int derived_age "DERIVED: age(CURRENT_DATE, dob)"
        timestamp created_at
    }

    VENUE {
        int venue_id PK
        string venue_name
        string street_address "COMPOSITE: street"
        string city "COMPOSITE: city"
        string state "COMPOSITE: state"
        string postal_code "COMPOSITE: postal"
        int total_capacity
        string contact_email
    }

    ARTIST {
        int artist_id PK
        string stage_name UK
        text bio
        string country_of_origin
        numeric billing_rate_per_hour
    }

    ARTIST_GENRE {
        int artist_id PK,FK
        string genre PK "MULTI-VALUED ATTRIBUTE"
    }

    CONCERT_EVENT {
        int event_id PK
        string event_title
        text event_description
        int artist_id FK
        int venue_id FK
        timestamp event_date_time
        int duration_minutes
        numeric base_ticket_price
        string event_status
        int derived_available_seats "DERIVED: capacity - booked"
    }

    SEAT {
        int seat_id PK
        int venue_id FK "WEAK ENTITY (identified by Venue)"
        string section_name "VIP | GOLD | SILVER | BRONZE"
        string seat_row "PARTIAL KEY"
        int seat_number "PARTIAL KEY"
        numeric price_multiplier
    }

    BOOKING {
        int booking_id PK
        string booking_reference UK
        int user_id FK
        int event_id FK
        timestamp booking_timestamp
        numeric total_amount "DERIVED: sum(ticket prices)"
        string booking_status
        string payment_method
    }

    TICKET_INSTANCE {
        int ticket_id PK
        int booking_id FK
        int event_id FK
        int seat_id FK
        numeric allocated_price
        string barcode_hash UK
        string status "RESERVED | CHECKED_IN | CANCELLED"
    }

    SEAT_AUDIT_LOG {
        int log_id PK
        int ticket_id FK
        int event_id
        int seat_id
        string action_type
        string old_status
        string new_status
        numeric old_price
        numeric new_price
        string changed_by
        timestamp change_timestamp
    }

    EVENT_RIDER_NOSQL {
        int document_id PK
        int event_id FK
        string document_type
        jsonb metadata_json "UNSTRUCTURED NoSQL DOC"
    }
```

---

## 3. Explicit Classification of Attributes & Entities (For Viva Evaluation)

### A. Entity Types
1. **Strong Entities**:
   - `USER_PROFILES`: Exists independently; possesses independent primary key `user_id`.
   - `VENUES`: Independent physical arena; primary key `venue_id`.
   - `ARTISTS`: Independent performer entity; primary key `artist_id`.
   - `CONCERT_EVENTS`: Scheduled live show; primary key `event_id`.
   - `BOOKINGS`: Commercial transaction header; primary key `booking_id`.

2. **Weak Entities**:
   - `SEATS`: Cannot exist in isolation without a parent `VENUE`. Its existence depends on the identifying relationship with `VENUE`. Partial discriminator: `(section_name, seat_row, seat_number)` scoped within `venue_id`.
   - `TICKET_INSTANCES`: Weak/associative entity dependent on `BOOKINGS` and `CONCERT_EVENTS`. Represents the tangible seat ticket allocated for a particular event.

---

### B. Attribute Types
1. **Key Attributes**:
   - Primary Keys: `user_id`, `venue_id`, `artist_id`, `event_id`, `seat_id`, `booking_id`, `ticket_id`.
   - Candidate / Alternate Unique Keys: `email` (User), `stage_name` (Artist), `booking_reference` (Booking), `barcode_hash` (Ticket Instance).

2. **Composite Attributes**:
   - `Venue_Address`: Decomposed into four atomic attributes:
     - `street_address`
     - `city`
     - `state`
     - `postal_code`

3. **Multi-Valued Attributes**:
   - `Artist_Genres`: An artist often belongs to multiple musical genres (e.g., A.R. Rahman $\rightarrow$ Sufi, World Fusion, Soundtrack). Normalized into the dependent relation `ARTIST_GENRES(artist_id, genre)`.

4. **Derived Attributes**:
   - `User Age`: Derived dynamically from `date_of_birth` as:
     $$\text{Age} = \text{EXTRACT(YEAR FROM age(CURRENT\_DATE, date\_of\_birth))}$$
   - `Available Seats Count`: Derived dynamically for any event as:
     $$\text{Available Seats} = \text{Venue Total Capacity} - \text{COUNT(Active Ticket Instances)}$$
   - `Booking Total Amount`: Derived dynamically as:
     $$\text{Total Amount} = \sum \text{Allocated Ticket Price}$$

---

## 4. Relationship Types & Cardinality Ratios

| Relationship | Participating Entities | Cardinality | Participation | Description |
|---|---|:---:|:---:|---|
| **Hosts** | `VENUES` $\rightarrow$ `CONCERT_EVENTS` | **1 : N** | Venue (Partial), Event (Total) | One venue can host multiple concerts; each concert must be held at exactly one venue. |
| **Performs** | `ARTISTS` $\rightarrow$ `CONCERT_EVENTS` | **1 : N** | Artist (Partial), Event (Total) | One artist performs in multiple concerts; each concert has a headliner artist. |
| **Contains** | `VENUES` $\rightarrow$ `SEATS` | **1 : N** | Venue (Total), Seat (Total) | Identifying relationship; a venue contains physical seat rows and sections. |
| **Places** | `USERS` $\rightarrow$ `BOOKINGS` | **1 : N** | User (Partial), Booking (Total) | A customer can make multiple bookings; each booking belongs to one user. |
| **Pertains To** | `CONCERT_EVENTS` $\rightarrow$ `BOOKINGS` | **1 : N** | Event (Partial), Booking (Total) | A concert receives many bookings. |
| **Allocates** | `BOOKINGS` $\rightarrow$ `TICKET_INSTANCES` | **1 : N** | Booking (Total), Ticket (Total) | A booking contains one or more allocated seat tickets. |
| **Occupies** | `SEATS` $\rightarrow$ `TICKET_INSTANCES` | **1 : N** | Seat (Partial), Ticket (Total) | A seat is reserved across different concert events over time. |
