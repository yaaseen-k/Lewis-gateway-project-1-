# Lewis-Gateway — Project 1

**Quality Engineering Test Strategy, Audit Findings & Recommendations**

Muhammad Uzair Salaam | Mogamat Yaaseen Karriem
redAcademy Quality Engineering • Cohort 2027A
Jira Board Link:
https://redacademy-team-pl7gdg14.atlassian.net/jira/software/projects/P1/boards/35?filter=&groupBy=none&atlOrigin=eyJpIjoiYWEyNGUyM2Y0ZWY1NGRlZDliMTJkZGJjN2M5YjE0NDIiLCJwIjoiaiJ9

---

## Overview

Lewis-Gateway is an e-commerce platform backed by a SQL Server database (`LewisStoresDb`). This project independently verifies that the platform is trustworthy at two levels:

1. **Layer 1 — API**: functional and negative testing of the stock, pricing, and credit endpoints, driven through Postman.
2. **Layer 2 — Database**: a systems-of-record integrity audit run directly against `LewisStoresDb` via T-SQL, checking whether the data underneath actually supports what the API reports.

A third component, a Cypress end-to-end suite, provides a recorded "happy path" walkthrough of the live storefront for the accompanying demo video.

**~100 total validation checks** across both layers (50 API + 50 database), all logged with Test ID, Description, Expected Result, Actual Result, and Pass/Fail status.

Our approach was **discovery-first**: the real Swagger contract, live database schema, and actual `Orders.Status` / `AuditLogs` event-type values were confirmed via live queries before any test was written — several assumptions made from the Swagger docs alone turned out to be wrong.

---

## Repository Structure

```
.
├── Postman_Tests/                              # API layer — Postman request/test collections
│   ├── API-PRC-001 to 020 (Pricing & VAT validation)
│   ├── API-STK-001 to 015 (Stock adjustments)
│   └── API-CRD-001 to 015 (Credit & debt governance)
├── SQL_Validation_Queries/                      # Database layer — T-SQL audit scripts
│   ├── SQL-REC-001 to 015 (Stock reconciliation)
│   ├── SQL-PRC-AUD-001 to 015 (Pricing audit)
│   ├── SQL-HYG-001 to 010 (Data hygiene & constraints)
│   └── SQL-BI-001 to 010 (Business intelligence reports)
├── cypress/
│   └── e2e/
│       └── lewis_happy_path2.cy.js              # Recorded happy-path demo spec
├── cypress.config.js
├── Lewis-Gateway_SQL_Test_Case_Log.xlsx         # Full 50-case DB audit log + summary
├── Project_1_report_yaaseen_and_uzair.xlsx      # Combined project report
├── Presentaion-Lewis-Gateway-Project1.pptx      # Findings & recommendations deck
├── package.json
└── README.md
```

---

## Layer 1 — API Testing (Postman)

| Suite | Range | Count | Endpoint(s) under test |
|---|---|---|---|
| Stock Adjustments | API-STK-001 to 015 | 15 | `PATCH /api/Products/{id}/stock` |
| VAT & Pricing Validation | API-PRC-001 to 020 | 20 | `POST /api/Pricing/validate` |
| Credit & Debt Governance | API-CRD-001 to 015 | 15 | `POST /api/Credit`, `POST /api/Orders` |

Assertions are written as Postman `afterResponse` JavaScript, validating status codes, the `ProblemDetails` error shape, and response payload correctness (arithmetic, rounding, precision).

**Key finding (API-01, Medium/High):** `POST /api/Pricing/validate` returns currency values unrounded, beyond 2 decimal places — e.g. `"vatAmount": 14.9985, "total": 114.9885` — which isn't a valid, displayable currency amount and risks incorrect invoice totals and accounting-reconciliation mismatches. **Recommendation:** round `Subtotal`, `VatAmount`, and `Total` to 2 decimal places before serialization.

---

## Layer 2 — Database Audit (T-SQL)

Run directly against `LewisStoresDb` (SQL Server / T-SQL dialect).

| Focus Area | Range | Count | Priority | Result |
|---|---|---|---|---|
| Stock Reconciliation | SQL-REC-001 to 015 | 15 | P0 | 5 Pass / 8 Fail / 2 N/A |
| Pricing Audit | SQL-PRC-AUD-001 to 015 | 15 | P0 | 10 Pass / 5 Fail |
| Data Hygiene & Constraints | SQL-HYG-001 to 010 | 10 | P1 | 9 Pass / 1 Fail |
| Business Intelligence Reports | SQL-BI-001 to 010 | 10 | P2 | 8 Pass / 2 N/A |
| **Total** | | **50** | | **32 Pass / 14 Fail / 4 N/A** |

Each test case in the log is tagged where relevant:
- `[REVISED]` — rewritten after a discovery finding invalidated the original design
- `[SUBSTITUTED]` — original intent couldn't be met (e.g. missing audit trail); replaced with the closest feasible check
- `[N/A - BLOCKED]` — cannot be executed at all; no underlying data exists to test against
- `[SCHEMA CHECK]` — tests the schema/constraints themselves rather than the data

### Critical findings

1. **No stock-change audit trail exists.** `AuditLogs.EventType` only contains `auth.*` and `order.*` events — zero product/stock/inventory events. Stock changes via `PATCH /api/Products/{id}/stock` leave no trace anywhere, blocking 8 of the 15 stock-reconciliation cases outright.
2. **`Orders.Items` is unstructured, price-less free text** (e.g. `"Luca Modular Sofa x1, Miren Coffee Table x1"`), duplicating what `OrderItems` already stores in normalized rows, with no way to cross-check totals between the two representations.
3. **VAT is never persisted anywhere in the schema** — no `Subtotal`/`VatRate`/`VatAmount` columns, no `VatRates` table. All VAT checks recompute using an assumed 15% rate pending dev-team confirmation.
4. **`Orders.Date` is stored as free-text `NVARCHAR(100)`**, not a real date/datetime type.
5. **No `CHECK` constraints exist anywhere in the schema** — `StockQuantity`, `Price`, and `Rating` are all unconstrained at the DB layer; validation is app-side only.

### Defect log (severity summary)

| ID | Layer | Finding | Severity |
|---|---|---|---|
| DB-01 | Database | No stock/inventory audit trail exists in `AuditLogs` | **Critical** |
| DB-02 | Database | No `CHECK` constraints on `StockQuantity`, `Price`, or `Rating` | High |
| DB-03 | Database | VAT is never persisted anywhere in the schema | High |
| API-01 | API | VAT and total amounts returned unrounded (4 decimal places) | Medium |
| DB-04 | Database | `Orders.Items` free text duplicates the `OrderItems` table | Medium |
| DB-05 | Database | `CartItems` table has no `UserId` column | Medium |
| DB-06 | Database | `Orders.Date` stored as free text, not a real date type | Low |

Full detail, SQL, expected/actual results for all 50 database cases are in `Lewis-Gateway_SQL_Test_Case_Log.xlsx`.

---

## Recorded Demo (Cypress)

`cypress/e2e/lewis_happy_path2.cy.js` is a **narratable demo spec**, not a full regression suite — assertions are kept light-touch so the video reads as a smooth walkthrough. It covers, end to end, as a logged-in customer:

1. Land on the homepage
2. Log in with a seeded test account
3. Browse the product catalog
4. Open a specific product
5. Add it to the cart
6. Proceed to checkout
7. Fill in delivery details
8. Fill in payment details and place the order
9. Confirm the order lands in Order History

The full recorded demo (in the deck) also chains this UI flow into a Postman check against the order just created, and a VSCode/T-SQL query confirming the database reflects it — tying all three layers together on one real transaction.

### Running the Cypress spec

```bash
npm install
npx cypress open      # interactive
npx cypress run       # headless
```

The spec expects the app running locally at `http://localhost:3000` (see `BASE_URL` in the spec) and a seeded customer account (`test.customer@lewisstores.local`).

---

## Recommendations

- Add a `product.stock.updated` audit event, matching the existing `auth.*` / `order.*` naming convention.
- Add `CHECK` constraints for `StockQuantity ≥ 0`, `Price ≥ 0`, and `Rating` between 0 and 5.
- Persist a VAT breakdown (`Subtotal`, `VatRate`, `VatAmount`) on `OrderItems` for compliance auditing.
- Round all currency values to 2 decimal places before returning them from the Pricing API.
- Resolve the `Orders.Items` / `OrderItems` duplication — treat `OrderItems` as the single source of truth.

---

## Deliverables

- `Presentaion-Lewis-Gateway-Project1.pptx` — full findings and recommendations deck
- `Lewis-Gateway_SQL_Test_Case_Log.xlsx` — 50-case database audit log with summary sheet
- `Project_1_report_yaaseen_and_uzair.xlsx` — combined project report
- `Postman_Tests/` — importable Postman collection (request bodies + JS assertions) for all 50 API cases
- Recorded happy-path demo video (referenced in the deck)
