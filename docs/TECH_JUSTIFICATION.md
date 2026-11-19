# PES University - Department of Computer Science & Engineering
## Experiential Learning Level 3 - DBMS Mini-Project
### Technology Justification Document (Rubric Item 5 - 1 Mark)
### Project: Concert and Live Event Management & Intelligent Seat Reservation System

---

## 1. Relational Database Engine: PostgreSQL
### Why Relational?
* **ACID Transactions**: In high-demand ticketing systems (e.g. Coldplay at DY Patil), hundreds of concurrent requests compete for the same seat. Relational databases enforce strict atomicity and isolation (`SERIALIZABLE` or `FOR UPDATE` row-level locks) preventing duplicate bookings.
* **Complex Referential Integrity**: Relational constraints (`FOREIGN KEY ... ON DELETE CASCADE`, `UNIQUE(event_id, seat_id)`) guarantee that orphaned tickets or double-reservations are physically impossible at the database engine level.
* **Strong Typing & Constraints**: Check constraints (`CHECK(price_multiplier BETWEEN 1.0 AND 5.0)`) prevent financial calculation bugs.

---

## 2. NoSQL Document Layer: PostgreSQL JSONB / Document Store
### Why NoSQL for Technical Riders & Fan Reviews?
* **Schema Flexibility**: An artist's backstage technical rider varies radically (an orchestra needs 50 instrument mics and green room temperature controls; an EDM DJ needs CDJs and laser power specs). A rigid relational schema would require dozens of sparse, mostly-empty columns.
* **Inverted GIN Indexing**: PostgreSQL JSONB with Generalized Inverted Index (GIN) allows rapid containment searches (`@> '{"vibe_tags": ["spiritual"]}'`) over unstructured arrays without full-table scans.
* **Atomic In-Place Updates**: Operators like `jsonb_set` permit localized modifications (e.g., upvoting helpful review count) without rewriting the entire document.

---

## 3. Vector Database: 5D Audio Feature Embedding Space
### Why Vector Embeddings for Live Event Discovery?
* **Semantic Discovery vs Keyword Matching**: Traditional SQL `LIKE '%rock%'` fails when a fan searches for *"calm cozy evening under the stars"* or *"high-energy festival beats"*.
* **Cosine Similarity Ranking**: By projecting both user mood preferences and concert characteristics into a 5-dimensional audio feature vector ($\text{Energy}, \text{Acousticness}, \text{Danceability}, \text{Valence}, \text{Crowd Scale}$), the system calculates exact geometric cosine distances:
  $$\text{Cosine Similarity} = \frac{\mathbf{u} \cdot \mathbf{v}}{\|\mathbf{u}\| \|\mathbf{v}\|}$$
  This ranks the closest musical matches in milliseconds and recommends the optimal seat tier.

---

## 4. Full-Stack Web Framework: Next.js (React 18 + Node.js)
### Why Next.js?
* **Unified Full-Stack Architecture**: Eliminates CORS misconfigurations and proxy latency by co-locating backend API Routes (`/api/bookings`, `/api/pricing`, `/api/triggers`) with high-performance React UI components.
* **Client-Side React Reactivity**: Powers instant seat selection, real-time dynamic pricing recalculation, and interactive SVG arena maps without full-page browser reloads.
* **Direct Database Integration**: Connects securely to the database pool with parameterized queries, preventing SQL injection.
