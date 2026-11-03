# Experiment 2 - OLAP and OLTP operations : Financials

**Aim:** implement OLTP and OLAP operations using SQL queries and data-warehouse concepts.

## Files

| File | Schema it runs on | Content |
|---|---|---|
| `01_oltp_operations.sql` | `dmbi_financials_stg` (table `oltp_financials`) | CRUD, ACID transactions, COMMIT/ROLLBACK, SAVEPOINT, locking, trigger, EXPLAIN |
| `02_olap_operations.sql` | `dmbi_financials_star` (star schema from Experiment 1) | roll-up, drill-down, slice, dice, pivot, cube, window functions, KPI ratio, summary table |

**Run Experiment 1 (steps 1 and 2) first.** Requires MySQL 8.0+.

## OLTP vs OLAP

| | OLTP | OLAP |
|---|---|---|
| Purpose | run the business (record sales) | analyse the business (decisions) |
| Operations | INSERT / UPDATE / DELETE / SELECT one row | big SELECT with GROUP BY over millions of rows |
| Data model | normalised, many tables, indexed by primary key | star/snowflake (fact + dimensions), denormalised |
| Data | current, detailed | historical, summarised |
| Users | clerks, apps | analysts, managers |
| Speed goal | milliseconds per transaction | acceptable seconds for complex queries |
| Integrity | ACID transactions | read-mostly, loaded by ETL |

## OLAP operations in `02_olap_operations.sql`

| Operation | Meaning | Where |
|---|---|---|
| Roll-up | go from detail to summary (climb a hierarchy) | `WITH ROLLUP` |
| Drill-down | go from summary to detail | 3-level queries |
| Slice | fix one dimension to one value | `WHERE d_segment.`segment` = @top_a` |
| Dice | restrict several dimensions (sub-cube) | `IN (top 2/3)` filters |
| Pivot | rotate rows into columns | dynamic `CASE` pivot |
| Cube | all combinations of dimensions | `UNION ALL` of grouping sets |
| Window functions | rank, % of total, running total | `RANK() OVER`, `SUM() OVER` |
| Aggregate table | pre-computed summary for speed | `CREATE TABLE agg_...` |

Measure used: **Sales** (`sales`). Dimensions used: **segment**, **country**, **product**.

## Tip for the viva
OLTP query: `EXPLAIN` shows `const` (index lookup, 1 row). OLAP query: full scan + grouping. That is exactly why a separate star schema exists for analysis.
