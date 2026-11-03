# Exam-day runbook (read this first)

## 0. Before you start (5 min)
* Check the software: MySQL Workbench / mysql client, Power BI Desktop, Tableau Public, draw.io (desktop or app.diagrams.net).
* Locate the dataset folder in **Music** and open the CSV once in a text editor: **compare the header row with the column table in the dataset README**. If it differs read `If_Your_Columns_Differ.md`.
* Copy the matching dataset folder from this kit to your working area.

## 1. Start MySQL
**Windows (cmd):**
```
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p --local-infile=1
```
**Linux:**
```
mysql -u root -p --local-infile=1
```
If you cannot start the client with that flag: in Workbench edit the connection > *Advanced* > *Others* and add `OPT_LOCAL_INFILE=1`, or import the CSV with the **Table Data Import Wizard** instead of `LOAD DATA`.

## 2. Experiment 1 (about 25 min)
1. Edit the path in `01_staging_load.sql` (YOUR_USER, folder, file name). Windows paths use forward slashes: `C:/Users/student/Music/Retail/file.csv`.
2. Run `01` -> `02` -> `03` -> `04` (SOURCE command or the Workbench lightning button).
3. Open `star_schema.drawio` and `snowflake_schema.drawio` in draw.io, tidy the layout, export PNG for the file.

## 3. Experiment 2 (about 20 min)
Run `01_oltp_operations.sql` then `02_olap_operations.sql`. Take screenshots of each numbered section's result.

## 4. Experiment 4 (about 30 min)
Power BI: paste `01_power_query_transform.m`, add measures from `02_dax_measures.dax`, build visuals from `04_...md`.
Tableau Public: follow `03_tableau_public_steps.md`.

## 5. Common errors
| Error | Fix |
|---|---|
| `The used command is not allowed with this MySQL version` (LOAD DATA LOCAL) | start the client with `--local-infile=1` and run `SET GLOBAL local_infile=1;` |
| `Unknown column 'X'` | your CSV header differs - rename columns in the staging table or edit the SQL (Find/Replace the column name) |
| `Incorrect date value` / all dates NULL | your date format differs: change the format string in `STR_TO_DATE(..., '%m/%d/%Y')` (`%d/%m/%Y`, `%Y-%m-%d`, ...) |
| `Data too long for column` | enlarge the VARCHAR in the DDL |
| Windows: `File not found` | use forward slashes, no quotes inside the path, and check the folder name |
| Query shows `GROUPING` / `OVER` syntax error | MySQL older than 8.0 - use `WITH ROLLUP` without `GROUPING()` and skip window functions |
| Dates come as `1/5/2019` but result is wrong | `%m/%d/%Y` = month first, `%d/%m/%Y` = day first |
| Import wizard ends with 0 rows | the CSV uses `;` as separator: open it in a text editor and check |

## 6. What to submit/show
SQL scripts, screenshots of the schema diagrams and of query outputs, Power BI/Tableau file, and 3-5 insight sentences.
