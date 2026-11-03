# If your CSV columns differ from this kit

Some dataset names are shared by several files on Kaggle. Steps when the header row of your CSV is different:

## Manual method (no Python needed, 10 minutes)
1. Open `01_staging_load.sql`. Edit the `CREATE TABLE stg_...` list so it has exactly your header names in the same order (all `VARCHAR(255)`).
2. In `02_star_schema.sql`, `03_snowflake_schema.sql`, `01_oltp_operations.sql`, `02_olap_operations.sql`: use Find/Replace to rename column names that exist in both files (`` s.`Old Name` `` -> `` s.`New Name` ``).
3. Delete the columns your file does not have (from the dimension INSERT ... SELECT, from the fact INSERT ... SELECT and from the DDL).
4. Run again.

## Generator method (needs Python 3)
1. Open `tools/spec.py`, find your dataset block, edit the `cols=[...]` list (`C('Header', 'kind', 'description')`; kinds: s=text, i=int, d=decimal, f=float, date, time, yn=yes/no).
2. Edit `dims=[...]`, `measures=[...]`, `snow={...}` accordingly (dimension attributes must be column headers from `cols`).
3. Run `python tools/build_kit.py out_folder` - the full folder tree is rebuilt with your columns.

## Design rule of thumb for an unknown dataset
* **Fact table** = the transaction rows: keys + numeric measures (quantity, price, amount, profit ...).
* **Dimensions** = descriptive columns grouped by topic: product / customer / location / time / payment / channel.
* **Snowflake** = split a dimension into sub-dimensions (city -> country, product -> category, date -> month -> quarter -> year).
