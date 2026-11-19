# 🎵 Concert & Live Event Management and Intelligent Seat Reservation System
### PES University - Department of Computer Science & Engineering
### Course: Database Management System (Aug - Dec 2026)
### Experiential Learning Level 3 - Mini-Project (Max Marks: 50)

---

## 📌 Project Overview
The **Concert and Live Event Management & Intelligent Seat Reservation System** is an enterprise-grade full-stack live entertainment ticketing platform. Built to solve high-concurrency stadium ticketing challenges, the platform combines:
* **Relational Core (PostgreSQL 3NF/BCNF)**: Enforcing strict ACID consistency, referential integrity, and composite constraints.
* **Concurrency Locking & Atomic Transactions**: Stored procedure `sp_book_tickets_atomic` with `FOR UPDATE` row-level locking preventing duplicate bookings.
* **Dynamic Surge Pricing Function**: `fn_calculate_dynamic_pricing` computing live price multipliers from real-time venue occupancy.
* **Database Trigger Audit Diff**: `trg_audit_seat_status_change` logging exact `BEFORE` and `AFTER` status mutations into `seat_audit_logs`.
* **NoSQL Document Store (JSONB)**: Semi-structured artist technical riders and multi-tag fan reviews supporting full document RUD.
* **Vector Database & Vibe Search**: 5-dimensional audio feature embedding space matching user musical preferences via Cosine Similarity.
* **Next.js Full-Stack Application**: Modern, responsive dark UI featuring interactive arena seat maps, live DB CRUD, and a dedicated **Evaluator Viva Showcase Panel**.

---

## 📊 PES University Evaluation Rubric Compliance (50/50 Marks)

| # | Evaluation Component | Max Marks | How We Implement It In Our Project |
|---|---|:---:|---|
| **1** | **ER Diagram** | **2** | Comprehensive ERD with Strong/Weak entities, derived, composite, multi-valued attributes, and participation. Available in `docs/ER_DIAGRAM.md`. |
| **2** | **Relational Schema** | **3** | Normalized schema with PK, FK, and integrity constraints. Normalization proof (1NF $\rightarrow$ 3NF/BCNF) in `docs/RELATIONAL_SCHEMA.md`. |
| **3** | **SQL DDL with Constraints** | **4** | Clean `database/01_ddl.sql` with `CHECK`, `UNIQUE`, `NOT NULL`, `DEFAULT`, `ON DELETE CASCADE`. |
| **4** | **NoSQL / Vector Database Creation** | **4** | PostgreSQL JSONB inverted GIN-indexed document store and vector embedding tables in `database/05_nosql_vector.sql`. |
| **5** | **Technology Justification** | **1** | Explicit rationale: Relational for transactional seat integrity; JSONB for flexible riders; Vector for semantic vibe search. |
| **6** | **DML Operations** | **4** | Clean `database/02_dml.sql` containing seed data for users, arenas, artists, concerts, seats, and bookings. |
| **7** | **Advanced Queries & Joins** | **4** | Clean `database/03_joins_nested_cte.sql`: 4-table join, nested `HAVING` query, correlated subquery, and recursive CTE. |
| **8** | **Advanced PL/SQL (Trigger, Procedure, Function)** | **6** | Clean `database/04_plsql.sql`: Stored procedure, dynamic pricing function, and audit trigger with before/after diff logging. |
| **9** | **NoSQL / Vector Feature RUD** | **7** | Live CRUD on JSON documents (`jsonb_set`, `@>`) and vector cosine similarity search in `database/05_nosql_vector.sql`. |
| **10** | **Next.js Interface** | **3** | High-performance interactive UI with arena seat maps, dark concert theme, and viva inspector tabs. |
| **11** | **Backend/API & DB Integration** | **2** | Next.js API Routes connecting directly to the embedded PostgreSQL engine with safe parameterized queries. |
| **12** | **Authentication & RBAC** | **4** | 2 distinct roles (`ADMIN/ORGANIZER` vs `CUSTOMER/ATTENDEE`) and database RBAC privileges in `database/06_rbac_roles.sql`. |
| **13** | **Documentation & Git** | **2** | GitHub-ready repository with modular directories, printable ERD, schemas, and defense cheatsheet. |
| **14** | **Originality & Viva Readiness** | **4** | Instant evaluator showcase UI displaying live trigger diffs and procedure execution with zero code searching required. |
| **TOTAL** | | **50** | **Max Marks Score** |

---

## 🗂️ Project File Structure

```
concert-reservation-system/
├── database/                    # Modular PostgreSQL SQL Scripts
│   ├── 01_ddl.sql               # Table definitions, PK/FK, CHECK constraints
│   ├── 02_dml.sql               # Realistic concert and arena seed data
│   ├── 03_joins_nested_cte.sql  # 4-Table Join, Nested query, Correlated query, Recursive CTE
│   ├── 04_plsql.sql             # Stored Procedure, Stored Function, Triggers & Audit tables
│   ├── 05_nosql_vector.sql      # NoSQL JSONB RUD & Vector Cosine Similarity Search
│   └── 06_rbac_roles.sql        # Database roles (admin vs attendee) and GRANT statements
├── docs/                        # Printable Hard-Copy Documentation & Viva Guides
│   ├── ER_DIAGRAM.md            # Entity-Relationship diagram & attribute classification
│   ├── RELATIONAL_SCHEMA.md     # Relational schema with keys & normalization proofs
│   └── VIVA_PRESENTATION_CHEATSHEET.md # 5-minute defense script & code line reference
├── src/
│   ├── app/
│   │   ├── api/                 # Next.js Backend API Routes
│   │   │   ├── advanced-queries/# Runs the 4 advanced SQL queries live
│   │   │   ├── bookings/        # Invokes stored procedure sp_book_tickets_atomic
│   │   │   ├── events/          # DML CRUD (Insert, Read, Delete concerts)
│   │   │   ├── nosql/           # NoSQL JSON document RUD operations
│   │   │   ├── pricing/         # Invokes stored function fn_calculate_dynamic_pricing
│   │   │   ├── seats/           # Arena seat grid status provider
│   │   │   ├── triggers/        # Executes trigger diff proof (BEFORE vs AFTER)
│   │   │   └── vector-search/   # 5D Vector cosine similarity recommendation
│   │   ├── globals.css          # Tailwind CSS styling & animations
│   │   ├── layout.tsx           # Dark concert theme wrapper & metadata
│   │   └── page.tsx             # Main Interactive Dashboard & Evaluator Showcase
│   └── lib/
│       └── db.ts                # Embedded PostgreSQL (PGlite) engine singleton & auto-seeder
├── package.json
├── tsconfig.json
├── tailwind.config.js
└── next.config.js
```

---

## 🚀 Quick Start Guide

### 1. Prerequisites
* **Node.js** (v18.0.0 or higher)
* **npm** or **pnpm**

### 2. Installation & Running
```bash
# Clone the repository
git clone <your-repo-url>
cd concert-reservation-system

# Install dependencies
npm install

# Start development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser. The embedded database automatically initializes all tables, triggers, and seed data on first boot!

---

## 🎯 Viva Defense Quick References (For Evaluator Questions)

### 1. Trigger Demonstration (Before vs After Diff)
* **Trigger Name**: `trg_audit_seat_status_change` on `ticket_instances`
* **Audit Table**: `seat_audit_logs`
* **How to Show in Viva**:
  1. Open the **"Viva: Trigger (Before/After Diff)"** tab on the UI.
  2. Select Ticket #1, pick status `CHECKED_IN`, and click **"Fire Trigger & Prove Diff"**.
  3. The UI displays the red **[BEFORE]** box (`status: 'RESERVED'`), the green **[AFTER]** box (`status: 'CHECKED_IN'`), and the newly generated audit log row with exact timestamp!

### 2. Stored Procedure & Function Invocation Pointers
* **Stored Function**: `fn_calculate_dynamic_pricing`
  * Defined in: `database/04_plsql.sql` line 75.
  * **Invoked in Code**: `src/app/api/pricing/route.ts` line 24.
* **Stored Procedure**: `sp_book_tickets_atomic`
  * Defined in: `database/04_plsql.sql` line 135.
  * **Invoked in Code**: `src/app/api/bookings/route.ts` line 42 (executed when clicking "Confirm Seat Reservation").

### 3. Advanced Queries Execution
* Open the **"Viva: 4 Advanced Queries & CTE"** tab to execute:
  1. **4-Table Join with Left Outer Join**
  2. **Nested Subquery** (`HAVING` with `AVG`)
  3. **Correlated Subquery** (comparing concert price to venue average)
  4. **Recursive CTE** (dynamic 4-tier seat escalation ladder)

---

## 👥 Contributors
* **Student Name**: PES University Computer Science & Engineering
* **Course**: Database Management System (UE24CS351A)
* **Academic Term**: Aug - Dec 2026
