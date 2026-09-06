/* ============================================================================
   Layer 2 — Database Integrity & "Systems of Record" Audit (SQL)
   Daily Essentials — 50 Independent Audit Scripts
   Database: LewisStoresDb  |  Dialect: T-SQL (SQL Server)
   ============================================================================

   This version is written against the ACTUAL schema (LewisStoresDb CREATE
   TABLE script) AND has been updated against CONFIRMED discovery-query
   results run by the tester on 2026-08-24. Two of the original assumptions
   turned out to be wrong in ways that matter — see findings #1 and #3 below.

   CONFIRMED DISCOVERY RESULTS
   ----------------------------
   Orders.Status values in use: Cancelled, Confirmed, Delivered, Pending, Shipped
       -> 'Delivered' is used below as the terminal/"sale completed" status.
       -> Pending, Confirmed, Shipped are treated as "not yet fulfilled" for
          oversell checks.

   AuditLogs.EventType values in use (top 5 alphabetically — confirm the
   full list is captured, there may be more below "order.created"):
       auth.login.failed, auth.login.success, auth.register.success,
       order.cancelled, order.created
       -> Naming convention is clearly {domain}.{action}.{result}, e.g.
          "order.created", "auth.login.success".

   KNOWN SCHEMA RISK AREAS / CONFIRMED FINDINGS (worth calling out in your
   report on their own, independent of any specific test case):

   1. *** CONFIRMED: THERE IS NO STOCK-CHANGE AUDIT TRAIL. ***
      Querying AuditLogs for EventType LIKE '%Stock%' OR '%Product%' returned
      ZERO rows. Cross-referenced against the full EventType list, there is
      no product.*, stock.*, or inventory.* event logged anywhere. This means
      stock quantity changes (via PATCH /api/Products/{id}/stock) leave NO
      audit trail at all — not under a differently-named event, not logged
      at all. Group 1 below has been substantially rewritten to work within
      this constraint rather than assume history that doesn't exist. THIS
      GAP ITSELF SHOULD BE LOGGED AS A FINDING (recommend a "product.stock.
      updated" event be added, matching the existing naming convention).

   2. VAT is never persisted anywhere. [OrderItems] only stores UnitPrice,
      Quantity, and LineTotal — there is no Subtotal, VatRate, or VatAmount
      column, and no VatRates table exists. VAT is computed on the fly by
      the Pricing API and never written to the database. DB-level VAT
      auditing can therefore only recompute-and-compare using an ASSUMED
      rate (0.15 used below) — it cannot cross-check against a stored rate.

   3. *** CONFIRMED: [Orders].[Items] is FREE TEXT, NOT JSON. ***
      Actual sample values look like: "Luca Modular Sofa x1, Miren Coffee
      Table x1" — a comma-separated list of "{ProductTitle} x{Quantity}"
      pairs. It is NOT parseable JSON (OPENJSON/JSON_VALUE will fail against
      it), and critically it contains NO PRICE DATA at all — only product
      titles and quantities. This means the dual-storage $-total comparison
      originally planned (JSON total vs OrderItems total) is not possible;
      Group 2 below has been rewritten to compare item counts/titles/
      quantities using string parsing instead. This unstructured, price-less
      duplicate storage is itself worth flagging as a data-modeling risk.

   4. [Orders].[Date] is NVARCHAR(100) — free text, not a real date/datetime
      type. [CreatedAtUtc] is the reliable datetime column and is used for
      all date-range filtering below instead.

   5. [CartItems] has no UserId (or any FK to Users) — carts cannot be
      attributed to a specific user at the DB level as currently modeled.

   6. No CHECK constraints exist anywhere (StockQuantity, Price, Rating are
      all unconstrained at the DB layer) — all validation is app-side only,
      so negative/out-of-range values are fully possible in the raw data.

   ============================================================================
   DISCOVERY QUERIES — already run once; re-run if the data may have changed
   ============================================================================ */

-- Confirm real Order status values in use (used throughout Groups 1, 2, 4)
SELECT DISTINCT Status FROM Orders;

-- Confirm the FULL list of AuditLogs event types (only top 5 alphabetically
-- were captured in the initial discovery pass — remove TOP if you need all)
SELECT DISTINCT EventType FROM AuditLogs ORDER BY EventType;

-- Re-confirm there is still no stock/product-related audit event
-- (returned ZERO rows on 2026-08-24 — re-run periodically in case logging
-- is added later in development)
SELECT TOP 20 Id, TimestampUtc, EventType, UserId, Details
FROM AuditLogs
WHERE EventType LIKE '%Stock%' OR EventType LIKE '%Product%'
ORDER BY TimestampUtc DESC;

-- Orders.Items is confirmed FREE TEXT, e.g. "Luca Modular Sofa x1, Miren
-- Coffee Table x1" — not JSON, and contains no price data.
SELECT TOP 5 Id, Items FROM Orders;


/* ============================================================================
   GROUP 1 — STOCK RECONCILIATION (15 scripts, P0)
   Focus: Discrepancies between API reports and underlying table counts.

   *** IMPORTANT: rewritten after confirming there is NO stock-change audit
   trail anywhere in this database (see header notes above). The original
   test plan (SQL-REC-001 to 015) assumed a StockAdjustment log existed to
   reconcile against — it doesn't. Rather than write 15 queries against
   data that isn't there, each script below has been substituted with the
   closest feasible check using only [Products], [OrderItems], and [Orders]
   — or, where no substitute is meaningful, replaced with a query that
   documents the gap itself as the finding. This substitution should be
   called out explicitly in your test report: several of these are "N/A —
   blocked by missing audit infrastructure" rather than pass/fail checks.
   ============================================================================ */

-- SQL-REC-001: [SUBSTITUTED] No prior-state to compare against — current
-- StockQuantity cannot be reconciled against "the last logged value" because
-- no such log exists. This query instead reports current stock as a
-- baseline snapshot, which is the most that's verifiable without an audit
-- trail. Flag in report: true reconciliation is not possible as currently
-- built.
SELECT Id, Sku, StockQuantity AS CurrentStock
FROM Products
ORDER BY Sku;

-- SQL-REC-002: Products with negative stock stored directly in the table
-- (no CHECK constraint exists to prevent this at the DB layer). Unaffected
-- by the audit-trail gap — still fully valid as written.
SELECT Id, Sku, StockQuantity
FROM Products
WHERE StockQuantity < 0;

-- SQL-REC-003: [N/A] "Products with no stock-adjustment audit entries" is
-- vacuously true for EVERY product, since no such entries exist for ANY
-- product. Running the literal original query would return the entire
-- Products table and provide no diagnostic value. This IS the finding:
SELECT COUNT(*) AS TotalProducts,
       0 AS ProductsWithLoggedStockHistory,
       'No product has any logged stock-adjustment history — audit trail does not exist' AS Finding
FROM Products;

-- SQL-REC-004: [N/A] Cannot check for duplicate audit log entries when no
-- audit log entries of this type exist. Kept as a template for when/if
-- product.stock.updated-style logging is added:
-- SELECT JSON_VALUE(Details, '$.ProductId') AS ProductId,
--        JSON_VALUE(Details, '$.NewStockQuantity') AS NewStockQuantity,
--        TimestampUtc, COUNT(*) AS DuplicateCount
-- FROM AuditLogs
-- WHERE EventType = 'product.stock.updated'  -- once this event type exists
-- GROUP BY JSON_VALUE(Details, '$.ProductId'), JSON_VALUE(Details, '$.NewStockQuantity'), TimestampUtc
-- HAVING COUNT(*) > 1;
SELECT 'N/A - no stock-adjustment audit events exist to check for duplicates' AS Result;

-- SQL-REC-005: [N/A] Continuity check requires a sequence of logged values
-- to compare consecutively — impossible with zero logged entries. Same
-- template-for-future note as REC-004 applies once logging is added.
SELECT 'N/A - no stock-adjustment audit trail exists to check continuity against' AS Result;

-- SQL-REC-006: [SUBSTITUTED] True reconciliation (opening + received - sold
-- = closing) needs an opening balance and received-quantity history, neither
-- of which is logged. What CAN be verified: whether OrderItems.Quantity sold
-- for Delivered orders is internally consistent (i.e. sold quantities are
-- all positive and attributable to real products) — a much weaker check,
-- but the strongest one the current schema supports.
SELECT p.Id, p.Sku, p.StockQuantity AS CurrentStock, ISNULL(sold.TotalSold, 0) AS TotalUnitsSoldEver
FROM Products p
LEFT JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS TotalSold
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.Status = 'Delivered'
    GROUP BY oi.ProductId
) sold ON sold.ProductId = p.Id
ORDER BY TotalUnitsSoldEver DESC;

-- SQL-REC-007: [N/A] "Adjustments with no attributable user" requires
-- adjustment records to exist in the first place.
SELECT 'N/A - no stock-adjustment audit events exist to check attribution on' AS Result;

-- SQL-REC-008: Oversell detection — pending order quantity exceeds available
-- stock. Fully valid as written; does not depend on the missing audit trail.
SELECT p.Id, p.Sku, p.StockQuantity, pending.PendingQty
FROM Products p
JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS PendingQty
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.Status IN ('Pending', 'Confirmed', 'Shipped')
    GROUP BY oi.ProductId
) pending ON pending.ProductId = p.Id
WHERE pending.PendingQty > p.StockQuantity;

-- SQL-REC-009: [N/A] No logged stock values to check for negative entries in.
SELECT 'N/A - no stock-adjustment audit events exist to inspect for negative logged values' AS Result;

-- SQL-REC-010: [SUBSTITUTED] "Never adjusted despite sales" can't reference
-- adjustment history, but CAN still flag something useful: products with
-- confirmed sales activity where StockQuantity was never decremented at all
-- (i.e. current stock looks untouched/implausible relative to sales volume —
-- e.g. still sitting at a suspiciously round initial-looking number despite
-- high sales). This is a heuristic, not a definitive check.
SELECT p.Id, p.Sku, p.StockQuantity, sold.TotalSold
FROM Products p
JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS TotalSold
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.Status = 'Delivered'
    GROUP BY oi.ProductId
) sold ON sold.ProductId = p.Id
WHERE sold.TotalSold > 20  -- meaningful sales volume
  AND p.StockQuantity % 10 = 0; -- heuristic: suspiciously round current stock

-- SQL-REC-011: [N/A] No audit log entries of this type exist to be orphaned.
SELECT 'N/A - no stock-adjustment audit events exist to check for orphaned references' AS Result;

-- SQL-REC-012: [SUBSTITUTED] Cannot compute "total received" without a
-- logged history of stock increases. What's reportable instead: total sold
-- vs. current total stock on hand, as a partial (one-sided) reconciliation.
SELECT
    (SELECT SUM(oi.Quantity)
     FROM OrderItems oi JOIN Orders o ON o.Id = oi.OrderId
     WHERE o.Status = 'Delivered') AS TotalUnitsSoldEver,
    (SELECT SUM(StockQuantity) FROM Products) AS CurrentTotalStockOnHand,
    'TotalReceived cannot be computed - no stock-increase audit trail exists' AS Note;

-- SQL-REC-013: [N/A] No logged maximum stock value exists to compare against.
SELECT 'N/A - no stock-adjustment audit events exist to derive a historical maximum from' AS Result;

-- SQL-REC-014: Schema-level check — confirm no CHECK constraint enforces
-- non-negative StockQuantity (a design gap, not a data anomaly). An empty
-- result set confirms the gap noted at the top of this file. Unaffected by
-- the audit-trail gap — still fully valid as written.
SELECT cc.name AS ConstraintName, cc.definition
FROM sys.check_constraints cc
JOIN sys.tables t ON t.object_id = cc.parent_object_id
WHERE t.name = 'Products' AND cc.definition LIKE '%StockQuantity%';

-- SQL-REC-015: [SUBSTITUTED] Full daily reconciliation summary reduced to
-- what's actually derivable: today's units sold per product (from Orders/
-- OrderItems, using CreatedAtUtc) alongside current closing stock. No
-- "opening stock" or "adjustments today" columns, since neither is logged.
DECLARE @ReportDate DATE = CAST(GETUTCDATE() AS DATE);

SELECT
    p.Id, p.Sku,
    ISNULL(day_sold.UnitsSold, 0) AS UnitsSoldToday,
    p.StockQuantity AS CurrentClosingStock
FROM Products p
LEFT JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS UnitsSold
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE CAST(o.CreatedAtUtc AS DATE) = @ReportDate AND o.Status = 'Delivered'
    GROUP BY oi.ProductId
) day_sold ON day_sold.ProductId = p.Id;



/* ============================================================================
   GROUP 2 — PRICING AUDIT (15 scripts, P0)
   Focus: Multi-table JOINs over order, product, and tax records vs.
   billing rules.

   NOTE: No VatRate/Subtotal/VatAmount columns exist anywhere in this schema.
   VAT is computed live by the API and never persisted. Scripts that need a
   VAT figure use an ASSUMED rate of 0.15 (matching the sample response seen
   earlier from POST /api/Pricing/validate) — confirm this is still correct
   with the dev team, and treat variances from these specific scripts as
   provisional findings pending that confirmation, not confirmed defects.
   ============================================================================ */

DECLARE @AssumedVatRate DECIMAL(5,4) = 0.15;

-- SQL-PRC-AUD-001: Charged price vs. current catalog price
-- Expected to differ for historical orders after a price change — reviewed
-- here mainly to catch anomalies on very recent orders.
SELECT oi.OrderId, oi.ProductId, oi.UnitPrice AS ChargedPrice, p.Price AS CurrentCatalogPrice, o.CreatedAtUtc
FROM OrderItems oi
JOIN Products p ON p.Id = oi.ProductId
JOIN Orders o ON o.Id = oi.OrderId
WHERE oi.UnitPrice <> p.Price
ORDER BY o.CreatedAtUtc DESC;

-- SQL-PRC-AUD-002: Line-level arithmetic — Quantity * UnitPrice should equal LineTotal
-- (this holds regardless of the VAT question, since LineTotal is whatever
-- the app decided to persist for that line)
SELECT Id, OrderId, ProductId, Quantity, UnitPrice, LineTotal,
       ROUND(Quantity * UnitPrice, 2) AS RecalculatedLineTotal
FROM OrderItems
WHERE ROUND(LineTotal, 2) <> ROUND(Quantity * UnitPrice, 2);

-- SQL-PRC-AUD-003: VAT-inclusive hypothesis check
-- Tests whether LineTotal = Quantity * UnitPrice * (1 + assumed VAT rate).
-- If PRC-AUD-002 above passes cleanly (LineTotal is VAT-exclusive) this one
-- is expected to show variance across the board — that's diagnostic, not
-- necessarily a defect. Use both results together to determine which model
-- your LineTotal actually follows.
SELECT Id, OrderId, ProductId, Quantity, UnitPrice, LineTotal,
       ROUND(Quantity * UnitPrice * (1 + @AssumedVatRate), 2) AS RecalculatedVatInclusiveTotal
FROM OrderItems
WHERE ROUND(LineTotal, 2) <> ROUND(Quantity * UnitPrice * (1 + @AssumedVatRate), 2);

-- SQL-PRC-AUD-004: Implied VAT rate consistency check
-- Since no VatRates table exists, back-solve the rate implied by each line
-- (LineTotal / (Quantity*UnitPrice) - 1) and flag lines whose implied rate
-- deviates from the catalog-wide norm — a proxy for "is VAT applied
-- consistently" without a stored rate to check against directly.
SELECT Id, OrderId, ProductId,
       ROUND((LineTotal / NULLIF(Quantity * UnitPrice, 0)) - 1, 4) AS ImpliedVatRate
FROM OrderItems
WHERE ABS(ROUND((LineTotal / NULLIF(Quantity * UnitPrice, 0)) - 1, 4) - @AssumedVatRate) > 0.005;

-- SQL-PRC-AUD-005: Order-level rollup integrity — Orders.Total vs SUM(OrderItems.LineTotal)
SELECT o.Id, o.Total AS StoredTotal, SUM(oi.LineTotal) AS ComputedTotal
FROM Orders o
JOIN OrderItems oi ON oi.OrderId = o.Id
GROUP BY o.Id, o.Total
HAVING ROUND(o.Total, 2) <> ROUND(SUM(oi.LineTotal), 2);

-- SQL-PRC-AUD-006: [REVISED] Dual-storage integrity — Orders.Items (free
-- text) quantities vs OrderItems (rows) quantities.
-- CONFIRMED: Orders.Items is plain text like "Luca Modular Sofa x1, Miren
-- Coffee Table x1" — NOT JSON, and contains NO PRICE DATA at all. A dollar
-- total comparison (the original design) is therefore impossible; this
-- compares total UNIT QUANTITY implied by the text against OrderItems
-- instead. Parsing is heuristic (splits on ', ' and reads the trailing
-- 'x<digits>' pattern) — spot-check a handful of results manually before
-- treating any flagged row as a confirmed defect, since product titles
-- containing unusual punctuation could break the parse.
WITH Split AS (
    SELECT o.Id AS OrderId, LTRIM(RTRIM(s.value)) AS ItemText
    FROM Orders o
    CROSS APPLY STRING_SPLIT(o.Items, ',') s
),
Parsed AS (
    SELECT OrderId, ItemText,
           CASE WHEN CHARINDEX('x ', REVERSE(ItemText)) > 0
                THEN LEN(ItemText) - CHARINDEX('x ', REVERSE(ItemText)) - 1
                ELSE NULL END AS SplitPos
    FROM Split
),
ParsedQty AS (
    SELECT OrderId,
           TRY_CAST(SUBSTRING(ItemText, SplitPos + 3, 20) AS INT) AS Qty
    FROM Parsed
    WHERE SplitPos IS NOT NULL
)
SELECT
    o.Id AS OrderId,
    ISNULL(txt.TextDerivedQty, 0) AS TextDerivedQty,
    ISNULL(row_sum.RowDerivedQty, 0) AS RowDerivedQty
FROM Orders o
LEFT JOIN (SELECT OrderId, SUM(Qty) AS TextDerivedQty FROM ParsedQty GROUP BY OrderId) txt ON txt.OrderId = o.Id
LEFT JOIN (SELECT OrderId, SUM(Quantity) AS RowDerivedQty FROM OrderItems GROUP BY OrderId) row_sum ON row_sum.OrderId = o.Id
WHERE ISNULL(txt.TextDerivedQty, 0) <> ISNULL(row_sum.RowDerivedQty, 0);

-- SQL-PRC-AUD-007: [REVISED] Dual-storage item-count integrity — number of
-- distinct line entries in the Items text vs. OrderItems row count.
-- Uses a simple comma count rather than full parsing, since only the COUNT
-- of entries is needed here (not their content).
SELECT
    o.Id AS OrderId,
    (LEN(o.Items) - LEN(REPLACE(o.Items, ',', '')) + 1) AS TextItemCount,
    (SELECT COUNT(*) FROM OrderItems oi WHERE oi.OrderId = o.Id) AS RowItemCount
FROM Orders o
WHERE (LEN(o.Items) - LEN(REPLACE(o.Items, ',', '')) + 1) <> (SELECT COUNT(*) FROM OrderItems oi WHERE oi.OrderId = o.Id);

-- SQL-PRC-AUD-008: Zero or negative unit prices billed
SELECT * FROM OrderItems WHERE UnitPrice <= 0;

-- SQL-PRC-AUD-009: Zero, negative, or implausibly large quantities billed
SELECT * FROM OrderItems WHERE Quantity <= 0 OR Quantity > 10000;

-- SQL-PRC-AUD-010: Orders billed with a nonzero Total but no corresponding OrderItems rows
-- (an "empty order charged money" integrity failure)
SELECT o.Id, o.Total
FROM Orders o
WHERE o.Total > 0
  AND NOT EXISTS (SELECT 1 FROM OrderItems oi WHERE oi.OrderId = o.Id);

-- SQL-PRC-AUD-011: Quantity * UnitPrice mismatch with stored LineTotal (tamper/rounding check)
-- Duplicate of PRC-AUD-002 kept as a distinct named test case per the test
-- plan; consider consolidating in your final suite if redundant.
SELECT Id, OrderId, ProductId, Quantity, UnitPrice, LineTotal,
       ROUND(Quantity * UnitPrice, 2) AS RecalculatedSubtotal
FROM OrderItems
WHERE ROUND(LineTotal, 2) <> ROUND(Quantity * UnitPrice, 2);

-- SQL-PRC-AUD-012: Orders billed against products currently marked inactive
SELECT oi.OrderId, oi.ProductId, p.IsActive, o.CreatedAtUtc
FROM OrderItems oi
JOIN Orders o ON o.Id = oi.OrderId
JOIN Products p ON p.Id = oi.ProductId
WHERE p.IsActive = 0;
-- NOTE: this only reflects CURRENT IsActive state, since there's no
-- ProductDeactivatedAt column to compare against the order date precisely.

-- SQL-PRC-AUD-013: Duplicate line items within the same order (possible double-billing)
SELECT OrderId, ProductId, COUNT(*) AS LineCount
FROM OrderItems
GROUP BY OrderId, ProductId
HAVING COUNT(*) > 1;

-- SQL-PRC-AUD-014: Discount tag vs. actual charged price reconciliation
-- Products tagged as discounted should show UnitPrice < OldPrice on the order line.
SELECT oi.OrderId, oi.ProductId, p.Tag, p.OldPrice, oi.UnitPrice
FROM OrderItems oi
JOIN Products p ON p.Id = oi.ProductId
WHERE (p.Tag LIKE '%Sale%' OR p.Tag LIKE '%Discount%')
  AND p.OldPrice IS NOT NULL
  AND oi.UnitPrice >= p.OldPrice;

-- SQL-PRC-AUD-015: Full order-level audit sweep for the last 30 days
-- Flags any order where Orders.Total fails to reconcile with the sum of its
-- OrderItems within a one-cent tolerance.
DECLARE @StartDate DATETIME2 = DATEADD(DAY, -30, GETUTCDATE());

SELECT o.Id AS OrderId, o.CreatedAtUtc,
       o.Total, SUM(oi.LineTotal) AS ComputedTotal,
       ABS(o.Total - SUM(oi.LineTotal)) AS Variance
FROM Orders o
JOIN OrderItems oi ON oi.OrderId = o.Id
WHERE o.CreatedAtUtc >= @StartDate
GROUP BY o.Id, o.CreatedAtUtc, o.Total
HAVING ABS(o.Total - SUM(oi.LineTotal)) > 0.01;


/* ============================================================================
   GROUP 3 — DATA HYGIENE & CONSTRAINTS (10 scripts, P1)
   Focus: Duplicate SKUs, negative costs, broken text fields.
   ============================================================================ */

-- SQL-HYG-001: Duplicate SKUs
-- Sku has a UNIQUE constraint in this schema, so this should always return
-- zero rows under normal operation — included as a constraint-verification
-- sanity check rather than an expected finding.
SELECT Sku, COUNT(*) AS Occurrences
FROM Products
GROUP BY Sku
HAVING COUNT(*) > 1;

-- SQL-HYG-002: Empty-string SKU
-- Sku is NOT NULL, but an empty string would still satisfy that constraint.
SELECT Id, Title, Sku
FROM Products
WHERE LTRIM(RTRIM(Sku)) = '';

-- SQL-HYG-003: Negative price fields (no CHECK constraint prevents this)
SELECT Id, Sku, Price, OldPrice
FROM Products
WHERE Price < 0 OR OldPrice < 0;

-- SQL-HYG-004: Illogical discount — OldPrice lower than current Price
SELECT Id, Sku, Price, OldPrice
FROM Products
WHERE OldPrice IS NOT NULL AND OldPrice < Price;

-- SQL-HYG-005: Empty-string Title (Title is NOT NULL but not non-empty-checked)
SELECT Id, Sku, Title
FROM Products
WHERE LTRIM(RTRIM(Title)) = '';

-- SQL-HYG-006: Broken/suspicious description text
SELECT Id, Sku, Description
FROM Products
WHERE Description IS NULL
   OR LTRIM(RTRIM(Description)) = ''
   OR Description LIKE '%<script%'
   OR Description LIKE '%<%>%'
   OR LEN(Description) > 4000;

-- SQL-HYG-007: Orphaned CategoryId references
-- FK_Products_Categories should prevent this under normal operation —
-- included as a constraint-verification sanity check.
SELECT p.Id, p.Sku, p.CategoryId
FROM Products p
LEFT JOIN Categories c ON c.Id = p.CategoryId
WHERE c.Id IS NULL;

-- SQL-HYG-008: Rating outside a valid 0–5 bound (no CHECK constraint enforces this)
SELECT Id, Sku, Rating
FROM Products
WHERE Rating < 0 OR Rating > 5;

-- SQL-HYG-009: Orders.Date values that fail to parse as a real date
-- Date is stored as free-text NVARCHAR(100) rather than a proper date type —
-- this surfaces any values that would break date-based reporting.
SELECT Id, [Date]
FROM Orders
WHERE TRY_CONVERT(datetime2, [Date]) IS NULL;

-- SQL-HYG-010: Stale cart pricing
-- CartItems.Price is a point-in-time snapshot with no link back to live
-- Products.Price — flags carts holding prices that have since drifted from
-- the current catalog (checkout would charge the stale price if unrefreshed).
SELECT ci.InternalId, ci.Id AS ProductId, ci.Title, ci.Price AS CartPrice, p.Price AS CurrentPrice
FROM CartItems ci
JOIN Products p ON p.Id = ci.Id
WHERE ci.Price <> p.Price;


/* ============================================================================
   GROUP 4 — BUSINESS INTELLIGENCE REPORTS (10 scripts, P2)
   Focus: High-performing inventory matrices and dead stock entries.

   NOTE: 'Delivered' is used as the assumed terminal Orders.Status value
   throughout this group — confirm against the discovery query at the top
   of this file and adjust if your actual value differs (e.g. 'Delivered',
   'Fulfilled', 'Paid').
   ============================================================================ */

-- SQL-BI-001: Top 10 best-selling products by units sold
SELECT TOP 10 p.Sku, p.Title, SUM(oi.Quantity) AS UnitsSold
FROM OrderItems oi
JOIN Products p ON p.Id = oi.ProductId
JOIN Orders o ON o.Id = oi.OrderId
WHERE o.Status = 'Delivered'
GROUP BY p.Sku, p.Title
ORDER BY UnitsSold DESC;

-- SQL-BI-002: Top 10 products by total revenue generated
SELECT TOP 10 p.Sku, p.Title, SUM(oi.LineTotal) AS TotalRevenue
FROM OrderItems oi
JOIN Products p ON p.Id = oi.ProductId
JOIN Orders o ON o.Id = oi.OrderId
WHERE o.Status = 'Delivered'
GROUP BY p.Sku, p.Title
ORDER BY TotalRevenue DESC;

-- SQL-BI-003: Dead stock report — in stock but no sales in the last 90 days
SELECT p.Id, p.Sku, p.Title, p.StockQuantity
FROM Products p
WHERE p.StockQuantity > 0
  AND p.Id NOT IN (
      SELECT oi.ProductId
      FROM OrderItems oi
      JOIN Orders o ON o.Id = oi.OrderId
      WHERE o.CreatedAtUtc >= DATEADD(DAY, -90, GETUTCDATE())
        AND o.Status = 'Delivered'
  );

-- SQL-BI-004: Inventory turnover ratio per category
SELECT p.CategoryId, p.Category,
       SUM(oi.Quantity) AS UnitsSold,
       AVG(p.StockQuantity) AS AvgStockHeld,
       CAST(SUM(oi.Quantity) AS FLOAT) / NULLIF(AVG(p.StockQuantity), 0) AS TurnoverRatio
FROM Products p
LEFT JOIN OrderItems oi ON oi.ProductId = p.Id
LEFT JOIN Orders o ON o.Id = oi.OrderId AND o.Status = 'Delivered'
GROUP BY p.CategoryId, p.Category
ORDER BY TurnoverRatio DESC;

-- SQL-BI-005: Overstock risk — high stock, low sell-through in the last 90 days
SELECT p.Id, p.Sku, p.Title, p.StockQuantity, ISNULL(sold.UnitsSold, 0) AS UnitsSoldLast90Days
FROM Products p
LEFT JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS UnitsSold
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.CreatedAtUtc >= DATEADD(DAY, -90, GETUTCDATE()) AND o.Status = 'Delivered'
    GROUP BY oi.ProductId
) sold ON sold.ProductId = p.Id
WHERE p.StockQuantity > 50   -- adjust to your business definition of "high stock"
  AND ISNULL(sold.UnitsSold, 0) < 5; -- adjust threshold for "low sell-through"

-- SQL-BI-006: Category-level revenue contribution
SELECT p.CategoryId, p.Category, SUM(oi.LineTotal) AS TotalRevenue
FROM OrderItems oi
JOIN Products p ON p.Id = oi.ProductId
JOIN Orders o ON o.Id = oi.OrderId
WHERE o.Status = 'Delivered'
GROUP BY p.CategoryId, p.Category
ORDER BY TotalRevenue DESC;

-- SQL-BI-007: Products nearing stockout, weighted by recent sales velocity
SELECT p.Id, p.Sku, p.Title, p.StockQuantity,
       ISNULL(velocity.UnitsSoldLast30Days, 0) AS UnitsSoldLast30Days,
       CASE WHEN ISNULL(velocity.UnitsSoldLast30Days, 0) > 0
            THEN p.StockQuantity / (velocity.UnitsSoldLast30Days / 30.0)
            ELSE NULL END AS EstimatedDaysOfStockLeft
FROM Products p
LEFT JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS UnitsSoldLast30Days
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.CreatedAtUtc >= DATEADD(DAY, -30, GETUTCDATE()) AND o.Status = 'Delivered'
    GROUP BY oi.ProductId
) velocity ON velocity.ProductId = p.Id
WHERE p.StockQuantity < 20 -- adjust reorder threshold as needed
ORDER BY EstimatedDaysOfStockLeft ASC;

-- SQL-BI-008: Average order value, trended by month
SELECT
    FORMAT(CreatedAtUtc, 'yyyy-MM') AS OrderMonth,
    COUNT(*) AS OrderCount,
    AVG(Total) AS AvgOrderValue
FROM Orders
WHERE Status = 'Delivered'
GROUP BY FORMAT(CreatedAtUtc, 'yyyy-MM')
ORDER BY OrderMonth;

-- SQL-BI-009: "Best Seller" tag validation against actual sales rank
WITH Ranked AS (
    SELECT p.Id, p.Sku, p.Tag, SUM(oi.Quantity) AS UnitsSold,
           RANK() OVER (ORDER BY SUM(oi.Quantity) DESC) AS SalesRank
    FROM Products p
    LEFT JOIN OrderItems oi ON oi.ProductId = p.Id
    LEFT JOIN Orders o ON o.Id = oi.OrderId AND o.Status = 'Delivered'
    GROUP BY p.Id, p.Sku, p.Tag
)
SELECT * FROM Ranked
WHERE Tag = 'Best Seller' AND SalesRank > 20; -- adjust "top N" threshold as needed

-- SQL-BI-010: Rating vs. sales volume correlation report
SELECT p.Id, p.Sku, p.Title, p.Rating, ISNULL(sold.UnitsSold, 0) AS UnitsSold,
       CASE
           WHEN p.Rating >= 4.5 AND ISNULL(sold.UnitsSold, 0) < 10 THEN 'High Rating / Low Sales'
           WHEN p.Rating <= 3.0 AND ISNULL(sold.UnitsSold, 0) > 50 THEN 'Low Rating / High Sales'
           ELSE 'Normal'
       END AS Flag
FROM Products p
LEFT JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS UnitsSold
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.Status = 'Delivered'
    GROUP BY oi.ProductId
) sold ON sold.ProductId = p.Id
WHERE (p.Rating >= 4.5 AND ISNULL(sold.UnitsSold, 0) < 10)
   OR (p.Rating <= 3.0 AND ISNULL(sold.UnitsSold, 0) > 50);
