#!/usr/bin/env python3
"""
DMBI Lab ESE kit generator.
Reads spec.py (dataset column specs) and writes the whole folder tree:
    python build_kit.py <output_folder>
Edit spec.py if your CSV header differs, then re-run (needs only Python 3, no packages).
"""
import os
import re
import sys
import shutil
import zipfile
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from spec import DATASETS, slug  # noqa: E402

KIT = 'DMBI_Lab_ESE_Kit'
NUM = ('i', 'bi', 'd', 'f')
BS = chr(92)
E1, E2, E4 = 'Experiment_1_Star_Snowflake', 'Experiment_2_OLAP_OLTP', 'Experiment_4_ETL_Visualization'
CONF = {'A': 'A - columns verified online', 'B': 'B - partly verified / several files share this name',
        'C': 'C - NOT verified online (best guess) - check your header first'}

MAIN = {'ecommerce_sales': 'Total Net Revenue', 'financials': 'Total Sales', 'retail_sales': 'Total Total Amount',
        'super_market': 'Total Total', 'sales_transaction': 'Total Sales Amount',
        'retail_transactions': 'Total Total_Cost', 'inventory_stock': 'Total Units Sold',
        'online_orders': 'Total Total Revenue'}


# ----------------------------------------------------------------------------- file helpers
def w(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(text.rstrip('\n') + '\n')


def cm(ds):
    return {c['h']: c for c in ds['cols']}


def DB(ds):
    return 'dmbi_' + ds['key']


def STG(ds):
    return 'stg_' + ds['key']


def banner(title, lines=()):
    out = ['-- ' + '=' * 72, '-- ' + title]
    out += ['-- ' + l for l in lines]
    out.append('-- ' + '=' * 72)
    return '\n'.join(out) + '\n'


# ----------------------------------------------------------------------------- SQL expression helpers
def clean(h):
    return ("NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`%s`),'$',''),',',''),'(','-'),')',''),'')" % h)


def num_expr(h, k):
    c = clean(h)
    if k == 'd':
        return 'CAST(%s AS DECIMAL(18,2))' % c
    if k == 'f':
        return 'CAST(%s AS DECIMAL(18,4))' % c
    return 'CAST(CAST(%s AS DECIMAL(20,2)) AS SIGNED)' % c


def date_expr(ds):
    d = ds['date']
    if d.get('expr'):
        return d['expr'].format(a='s')
    return "DATE(STR_TO_DATE(TRIM(s.`%s`), '%s'))" % (d['col'], d['fmt'])


def val_expr(ds, h):
    c = cm(ds)[h]
    k = c['k']
    if k in NUM:
        return num_expr(h, k)
    if k == 'date':
        return date_expr(ds)
    if k == 'time':
        return "TIME(STR_TO_DATE(TRIM(s.`%s`), '%s'))" % (h, ds['time']['fmt'])
    if k == 'yn':
        return "CASE WHEN UPPER(TRIM(s.`%s`)) IN ('YES','Y','TRUE','1') THEN 1 ELSE 0 END" % h
    return "NULLIF(TRIM(s.`%s`), '')" % h


def resolve(ds, expr):
    cmap = cm(ds)
    return re.sub(r"s\.`([^`]+)`",
                  lambda m: ('(%s)' % val_expr(ds, m.group(1))) if m.group(1) in cmap else m.group(0), expr)


def dtype(c):
    k = c['k']
    return {'s': 'VARCHAR(%d)' % (c.get('n') or 100), 'i': 'INT', 'bi': 'BIGINT', 'd': 'DECIMAL(18,2)',
            'f': 'DECIMAL(18,4)', 'date': 'DATE', 'time': 'TIME', 'yn': 'TINYINT'}[k]


def attr_info(ds, a):
    if isinstance(a, tuple):
        return a[0], a[1], resolve(ds, a[2])
    c = cm(ds)[a]
    return c['f'], dtype(c), val_expr(ds, a)


def dim_key(name):
    return name[4:] + '_key'


def alias(dimname):
    return 'd_' + dimname[4:]


# ----------------------------------------------------------------------------- model
def build_star(ds):
    dims = []
    for d in ds['dims']:
        cols = []
        for a in d['attrs']:
            n, t, e = attr_info(ds, a)
            cols.append(dict(name=n, type=t, expr=e))
        dims.append(dict(name=d['name'], pk=dim_key(d['name']), cols=cols, fks=[], subs=[],
                         uniq=[c['name'] for c in cols]))
    return dims


def build_snow(ds):
    star = build_star(ds)
    out = []
    snow = ds.get('snow', {})
    for d in star:
        sl = snow.get(d['name'])
        if not sl:
            out.append(d)
            continue
        moved = set()
        subs = []
        for sp in sl:
            if 'attrs' in sp:
                subcols = [c for c in d['cols'] if c['name'] in sp['attrs']]
                assert len(subcols) == len(sp['attrs']), (ds['key'], sp)
                moved.update(sp['attrs'])
                sub = dict(name=sp['sub'], pk=dim_key(sp['sub']), cols=subcols, fks=[], subs=[],
                           uniq=[c['name'] for c in subcols])
            else:
                src = [c for c in d['cols'] if c['name'] == sp['frm']][0]
                nm, typ = sp['new']
                whens = ' '.join("WHEN '%s' THEN '%s'" % (k, v) for k, v in sp['mapping'].items())
                ex = "CASE %s %s ELSE 'Other' END" % (src['expr'], whens)
                sub = dict(name=sp['sub'], pk=dim_key(sp['sub']), cols=[dict(name=nm, type=typ, expr=ex)],
                           fks=[], subs=[], uniq=[nm])
            subs.append(sub)
        own = [c for c in d['cols'] if c['name'] not in moved]
        fkcols = [dict(name=s['pk'], type='INT', expr=None) for s in subs]
        parent = dict(name=d['name'], pk=d['pk'], cols=own + fkcols,
                      fks=[(s['pk'], s['name'], s['pk']) for s in subs], subs=subs,
                      uniq=[c['name'] for c in own] + [s['pk'] for s in subs], own=own)
        out.append(parent)
    return out


DATE_STAR = dict(name='dim_date', pk='date_key', pk_type='INT', auto=False,
                 cols=[dict(name='full_date', type='DATE'), dict(name='day_of_month', type='TINYINT'),
                       dict(name='day_name', type='VARCHAR(10)'), dict(name='is_weekend', type='TINYINT'),
                       dict(name='month_num', type='TINYINT'), dict(name='month_name', type='VARCHAR(10)'),
                       dict(name='quarter_num', type='TINYINT'), dict(name='year_num', type='SMALLINT')],
                 fks=[], uniq=['full_date'])
DATE_SNOW = [
    dict(name='dim_year', pk='year_key', pk_type='INT', auto=False, cols=[dict(name='year_num', type='SMALLINT')],
         fks=[], uniq=['year_num']),
    dict(name='dim_quarter', pk='quarter_key', pk_type='INT', auto=False,
         cols=[dict(name='quarter_num', type='TINYINT'), dict(name='year_key', type='INT')],
         fks=[('year_key', 'dim_year', 'year_key')], uniq=['quarter_num', 'year_key']),
    dict(name='dim_month', pk='month_key', pk_type='INT', auto=False,
         cols=[dict(name='month_num', type='TINYINT'), dict(name='month_name', type='VARCHAR(10)'),
               dict(name='quarter_key', type='INT')],
         fks=[('quarter_key', 'dim_quarter', 'quarter_key')], uniq=['month_num', 'quarter_key']),
    dict(name='dim_date', pk='date_key', pk_type='INT', auto=False,
         cols=[dict(name='full_date', type='DATE'), dict(name='day_of_month', type='TINYINT'),
               dict(name='day_name', type='VARCHAR(10)'), dict(name='is_weekend', type='TINYINT'),
               dict(name='month_key', type='INT')],
         fks=[('month_key', 'dim_month', 'month_key')], uniq=['full_date']),
]


def ddl(t):
    L = ['  `%s` %s NOT NULL%s' % (t['pk'], t.get('pk_type', 'INT'), ' AUTO_INCREMENT' if t.get('auto', True) else '')]
    for c in t['cols']:
        L.append('  `%s` %s NULL' % (c['name'], c['type']))
    L.append('  PRIMARY KEY (`%s`)' % t['pk'])
    if t.get('uniq'):
        L.append('  UNIQUE KEY `uq_%s` (%s)' % (t['name'], ', '.join('`%s`' % u for u in t['uniq'])))
    for (col, rt, rc) in t.get('fks', []):
        L.append('  CONSTRAINT `fk_%s_%s` FOREIGN KEY (`%s`) REFERENCES `%s` (`%s`)' % (t['name'], col, col, rt, rc))
    return 'CREATE TABLE `%s` (\n%s\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;\n' % (t['name'], ',\n'.join(L))


def fact_items(ds, dims):
    """list of (name, type, expr, dimref)"""
    it = []
    if ds.get('date'):
        it.append(('date_key', 'INT',
                   "CAST(DATE_FORMAT(%s, '%%Y%%m%%d') AS UNSIGNED)" % date_expr(ds), None))
    for d in dims:
        it.append((d['pk'], 'INT', None, d))
    cmap = cm(ds)
    for h in ds['degenerate']:
        c = cmap[h]
        it.append((c['f'], dtype(c), val_expr(ds, h), None))
    if ds.get('time'):
        c = cmap[ds['time']['col']]
        it.append(('sale_time', 'TIME', val_expr(ds, ds['time']['col']), None))
    for h in ds['measures']:
        c = cmap[h]
        it.append((c['f'], dtype(c), val_expr(ds, h), None))
    for (n, t, e) in ds['fact_derived']:
        it.append((n, t, resolve(ds, e), None))
    return it


def fact_table(ds, dims):
    t = dict(name=ds['fact'], pk=ds['fact'] + '_key', pk_type='BIGINT', cols=[], fks=[], uniq=None)
    for (n, ty, e, d) in fact_items(ds, dims):
        t['cols'].append(dict(name=n, type=ty))
        if d is not None:
            t['fks'].append((n, d['name'], d['pk']))
        if n == 'date_key':
            t['fks'].append(('date_key', 'dim_date', 'date_key'))
    return t


def src(ds):
    return '`%s`.`%s` s' % (DB(ds) + '_stg', STG(ds))


def join_on(d, cols_exprs, extra=''):
    parts = ['%s.`%s` <=> %s' % (d['alias'], n, e) for (n, e) in cols_exprs]
    return ' AND '.join(parts) + extra


def dim_etl(ds, d, snow=False):
    """INSERT for one dimension (star dim, or snowflake parent/sub)"""
    if snow and d.get('subs'):
        names = [c['name'] for c in d['own']] + [s['pk'] for s in d['subs']]
        sel = [c['expr'] for c in d['own']] + ['x%d.`%s`' % (i + 1, s['pk']) for i, s in enumerate(d['subs'])]
        joins = []
        for i, s in enumerate(d['subs']):
            cond = ' AND '.join('x%d.`%s` <=> %s' % (i + 1, c['name'], c['expr']) for c in s['cols'])
            joins.append('LEFT JOIN `%s` x%d ON %s' % (s['name'], i + 1, cond))
        return ('INSERT INTO `%s` (%s)\nSELECT DISTINCT\n  %s\nFROM %s\n%s;\n' %
                (d['name'], ', '.join('`%s`' % n for n in names), ',\n  '.join(sel), src(ds), '\n'.join(joins)))
    names = [c['name'] for c in d['cols']]
    return ('INSERT INTO `%s` (%s)\nSELECT DISTINCT\n  %s\nFROM %s;\n' %
            (d['name'], ', '.join('`%s`' % n for n in names), ',\n  '.join(c['expr'] for c in d['cols']), src(ds)))


def fact_etl(ds, dims, snow):
    items = fact_items(ds, dims)
    sel, joins = [], []
    sub_i = 0
    for i, d in enumerate(dims):
        d['alias'] = 'd%d' % (i + 1)
    for (n, ty, e, d) in items:
        if d is None:
            sel.append(e)
        else:
            sel.append('%s.`%s`' % (d['alias'], d['pk']))
    for d in dims:
        conds = []
        if snow and d.get('subs'):
            for s in d['subs']:
                sub_i += 1
                sa = 'x%d' % sub_i
                cond = ' AND '.join('%s.`%s` <=> %s' % (sa, c['name'], c['expr']) for c in s['cols'])
                joins.append('LEFT JOIN `%s` %s ON %s' % (s['name'], sa, cond))
                conds.append('%s.`%s` <=> %s.`%s`' % (d['alias'], s['pk'], sa, s['pk']))
            own = d['own']
        else:
            own = d['cols']
        conds = ['%s.`%s` <=> %s' % (d['alias'], c['name'], c['expr']) for c in own] + conds
        joins.append('LEFT JOIN `%s` %s ON %s' % (d['name'], d['alias'], '\n       AND '.join(conds)))
    return ('INSERT INTO `%s` (%s)\nSELECT\n  %s\nFROM %s\n%s;\n' %
            (ds['fact'], ', '.join('`%s`' % it[0] for it in items), ',\n  '.join(sel), src(ds), '\n'.join(joins)))


DATE_SRC = "(SELECT %s AS d FROM %s) x"


def date_etl_star(ds):
    ds_src = DATE_SRC % (date_expr(ds), src(ds))
    return ("INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_num, month_name, quarter_num, year_num)\n"
            "SELECT DISTINCT CAST(DATE_FORMAT(d, '%%Y%%m%%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),\n"
            "       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), MONTH(d), MONTHNAME(d), QUARTER(d), YEAR(d)\n"
            "FROM %s\nWHERE d IS NOT NULL;\n") % ds_src


def date_etl_snow(ds):
    s = DATE_SRC % (date_expr(ds), src(ds))
    return (
        "INSERT INTO `dim_year` (year_key, year_num)\nSELECT DISTINCT YEAR(d), YEAR(d) FROM %s WHERE d IS NOT NULL;\n\n"
        "INSERT INTO `dim_quarter` (quarter_key, quarter_num, year_key)\nSELECT DISTINCT YEAR(d) * 10 + QUARTER(d), QUARTER(d), YEAR(d) FROM %s WHERE d IS NOT NULL;\n\n"
        "INSERT INTO `dim_month` (month_key, month_num, month_name, quarter_key)\nSELECT DISTINCT YEAR(d) * 100 + MONTH(d), MONTH(d), MONTHNAME(d), YEAR(d) * 10 + QUARTER(d) FROM %s WHERE d IS NOT NULL;\n\n"
        "INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_key)\n"
        "SELECT DISTINCT CAST(DATE_FORMAT(d, '%%Y%%m%%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),\n"
        "       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), YEAR(d) * 100 + MONTH(d)\nFROM %s WHERE d IS NOT NULL;\n") % (s, s, s, s)


def count_block(names):
    return ('SELECT ' + ' UNION ALL SELECT '.join("'%s' AS table_name, COUNT(*) AS row_count FROM `%s`" % (n, n) for n in names) + ';\n')


# ----------------------------------------------------------------------------- SQL files
def staging_sql(ds):
    stg = DB(ds) + '_stg'
    tn = STG(ds)
    last = ds['cols'][-1]['h']
    L = [banner('EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [%s]' % ds['title'],
                ['Creates schema `%s` and loads the raw CSV (all columns as text).' % stg,
                 'Cleaning / typing is done later in the ETL of the star and snowflake scripts.',
                 'EDIT the file path in the LOAD DATA line before running.'])]
    L.append('CREATE DATABASE IF NOT EXISTS `%s` DEFAULT CHARACTER SET utf8mb4;\nUSE `%s`;\n' % (stg, stg))
    cols = ',\n'.join('  `%s` VARCHAR(%d) NULL' % (c['h'], max(255, c.get('n') or 0)) for c in ds['cols'])
    L.append('DROP TABLE IF EXISTS `%s`;\nCREATE TABLE `%s` (\n%s\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;\n' % (tn, tn, cols))
    L.append("""-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/%s/%s'
INTO TABLE `%s`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/%s/%s' INTO TABLE `%s`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\\n' IGNORE 1 LINES;
""" % (ds['folder_music'], ds['csv'], tn, ds['folder_music'], ds['csv'], tn))
    L.append("""-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `%s` SET `%s` = REPLACE(`%s`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;
""" % (tn, last, last))
    L.append('-- ---- CHECK THE LOAD -------------------------------------------------------\n'
             'SELECT COUNT(*) AS rows_loaded FROM `%s`;\nSELECT * FROM `%s` LIMIT 5;\n' % (tn, tn))
    prof = ',\n  '.join("SUM(`%s` IS NULL OR TRIM(`%s`) = '') AS `blank_%s`" % (c['h'], c['h'], slug(c['h'])) for c in ds['cols'])
    L.append('-- ---- DATA PROFILE: blank/missing values per column -------------------------\n'
             'SELECT COUNT(*) AS total_rows,\n  %s\nFROM `%s`;\n' % (prof, tn))
    return '\n'.join(L)


def star_sql(ds):
    db = DB(ds) + '_star'
    dims = build_star(ds)
    fact = fact_table(ds, dims)
    hasdate = bool(ds.get('date'))
    L = [banner('EXPERIMENT 1 - STEP 2 : STAR SCHEMA  [%s]' % ds['title'],
                ['Fact  : %s   (grain: %s)' % (ds['fact'], ds['grain']),
                 'Dims  : ' + ', '.join((['dim_date'] if hasdate else []) + [d['name'] for d in dims]),
                 'Run 01_staging_load.sql first. Requires MySQL 8.0+.'])]
    L.append('CREATE DATABASE IF NOT EXISTS `%s` DEFAULT CHARACTER SET utf8mb4;\nUSE `%s`;\n' % (db, db))
    names = [ds['fact']] + [d['name'] for d in dims] + (['dim_date'] if hasdate else [])
    L.append('SET FOREIGN_KEY_CHECKS = 0;\n' + ''.join('DROP TABLE IF EXISTS `%s`;\n' % n for n in names) + 'SET FOREIGN_KEY_CHECKS = 1;\n')
    L.append('-- ---- PART A : DDL (dimension tables, then the fact table) -------------------\n')
    if hasdate:
        L.append(ddl(DATE_STAR))
    for d in dims:
        L.append(ddl(d))
    L.append(ddl(fact))
    L.append('-- ---- PART B : ETL (staging -> dimensions -> fact) -------------------------\n')
    L.append('-- NULL-safe equality (<=>) is used in the joins so rows with blanks are not lost.\n')
    if hasdate:
        L.append('-- dim_date: one row per distinct calendar date found in the data\n' + date_etl_star(ds))
    for d in dims:
        L.append('-- %s\n%s' % (d['name'], dim_etl(ds, d)))
    L.append('-- %s : one row per source row, foreign keys looked up from the dimensions\n%s' % (ds['fact'], fact_etl(ds, dims, False)))
    L.append('-- ---- PART C : QUICK CHECK -------------------------------------------------\n' +
             count_block(names + []))
    return '\n'.join(L)


def snow_sql(ds):
    db = DB(ds) + '_snow'
    dims = build_snow(ds)
    fact = fact_table(ds, dims)
    hasdate = bool(ds.get('date'))
    subs = [s for d in dims for s in d.get('subs', [])]
    tables = (list(reversed([t['name'] for t in DATE_SNOW])) if hasdate else []) + [s['name'] for s in subs] + [d['name'] for d in dims]
    L = [banner('EXPERIMENT 1 - STEP 3 : SNOWFLAKE SCHEMA  [%s]' % ds['title'],
                ['Same fact table as the star schema; dimensions are NORMALISED into sub-dimensions.',
                 'Sub-dimensions here: ' + (', '.join(s['name'] for s in subs) or '(none)') +
                 ('; date chain dim_date > dim_month > dim_quarter > dim_year' if hasdate else ''),
                 'Run 01_staging_load.sql first. Requires MySQL 8.0+.'])]
    L.append('CREATE DATABASE IF NOT EXISTS `%s` DEFAULT CHARACTER SET utf8mb4;\nUSE `%s`;\n' % (db, db))
    L.append('SET FOREIGN_KEY_CHECKS = 0;\n' + ''.join('DROP TABLE IF EXISTS `%s`;\n' % n for n in [ds['fact']] + tables) + 'SET FOREIGN_KEY_CHECKS = 1;\n')
    L.append('-- ---- PART A : DDL (outer-most sub-dimensions first) ---------------------------\n')
    if hasdate:
        for t in DATE_SNOW:
            L.append(ddl(t))
    for s in subs:
        L.append(ddl(s))
    for d in dims:
        L.append(ddl(d))
    L.append(ddl(fact))
    L.append('-- ---- PART B : ETL ------------------------------------------------------------\n')
    if hasdate:
        L.append('-- date hierarchy: year > quarter > month > date\n' + date_etl_snow(ds))
    for s in subs:
        L.append('-- %s\n%s' % (s['name'], dim_etl(ds, s)))
    for d in dims:
        L.append('-- %s\n%s' % (d['name'], dim_etl(ds, d, snow=True)))
    L.append('-- %s\n%s' % (ds['fact'], fact_etl(ds, dims, True)))
    L.append('-- ---- PART C : QUICK CHECK ------------------------------------------------------\n' +
             count_block([ds['fact']] + tables))
    return '\n'.join(L)


# --- OLAP helpers
def a_col(t):
    return t


def from_joins(ds, dimnames):
    out = ['FROM `%s` f' % ds['fact']]
    seen = []
    for dn in dimnames:
        if dn in seen:
            continue
        seen.append(dn)
        if dn == 'dim_date':
            out.append('LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`')
        else:
            k = dim_key(dn)
            out.append('LEFT JOIN `%s` %s ON f.`%s` = %s.`%s`' % (dn, alias(dn), k, alias(dn), k))
    return '\n'.join(out)


def ref(t):
    return '%s.`%s`' % (alias(t[0]), t[1])


def verify_sql(ds):
    star, snow = DB(ds) + '_star', DB(ds) + '_snow'
    o = ds['olap']
    m = o['m'][0]
    dims_s = build_snow(ds)
    L = [banner('EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [%s]' % ds['title'],
                ['Proves that staging, star and snowflake hold the same data.', 'Then shows how queries differ (joins).'])]
    L.append('-- 1. ROW COUNTS must match: staging = star fact = snowflake fact\n'
             "SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `%s_stg`.`%s`\n"
             "UNION ALL SELECT 'star fact', COUNT(*) FROM `%s`.`%s`\n"
             "UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `%s`.`%s`;\n" % (DB(ds), STG(ds), star, ds['fact'], snow, ds['fact']))
    L.append('-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas\n'
             "SELECT 'star' AS schema_, SUM(`%s`) AS total_%s FROM `%s`.`%s`\n"
             "UNION ALL SELECT 'snowflake', SUM(`%s`) FROM `%s`.`%s`;\n" % (m, m, star, ds['fact'], m, snow, ds['fact']))
    t_a = o['a']
    # star query
    L.append('-- 3. STAR query : fact + ONE join to the dimension\nUSE `%s`;\n'
             'SELECT %s AS %s, SUM(f.`%s`) AS total\n%s\nGROUP BY %s\nORDER BY total DESC\nLIMIT 10;\n' %
             (star, ref(t_a), t_a[1], m, from_joins(ds, [t_a[0]]), ref(t_a)))
    # snowflake query
    sub = None
    for d in dims_s:
        for s in d.get('subs', []):
            sub = (d, s)
            break
        if sub:
            break
    if sub:
        d, s = sub
        sc = s['cols'][0]['name']
        L.append('-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension\nUSE `%s`;\n'
                 'SELECT s1.`%s` AS %s, SUM(f.`%s`) AS total\nFROM `%s` f\nJOIN `%s` p ON f.`%s` = p.`%s`\nJOIN `%s` s1 ON p.`%s` = s1.`%s`\n'
                 'GROUP BY s1.`%s`\nORDER BY total DESC\nLIMIT 10;\n' %
                 (snow, sc, sc, m, ds['fact'], d['name'], d['pk'], d['pk'], s['name'], s['pk'], s['pk'], sc))
    else:
        L.append('-- 4. SNOWFLAKE query : time hierarchy needs 3 extra joins (date > month > quarter > year)\nUSE `%s`;\n'
                 'SELECT y.year_num, q.quarter_num, SUM(f.`%s`) AS total\nFROM `%s` f\nJOIN dim_date d ON f.date_key = d.date_key\n'
                 'JOIN dim_month mo ON d.month_key = mo.month_key\nJOIN dim_quarter q ON mo.quarter_key = q.quarter_key\n'
                 'JOIN dim_year y ON q.year_key = y.year_key\nGROUP BY y.year_num, q.quarter_num\nORDER BY y.year_num, q.quarter_num;\n' % (snow, m, ds['fact']))
    L.append("-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)\n"
             "SELECT table_schema, table_name, table_rows FROM information_schema.tables\n"
             "WHERE table_schema IN ('%s', '%s') ORDER BY table_schema, table_name;\n\n"
             "SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name\n"
             "FROM information_schema.key_column_usage\n"
             "WHERE table_schema IN ('%s', '%s') AND referenced_table_name IS NOT NULL\n"
             "ORDER BY table_schema, table_name;\n" % (star, snow, star, snow))
    return '\n'.join(L)


# ----------------------------------------------------------------------------- Experiment 2
def oltp_sql(ds):
    stg = DB(ds) + '_stg'
    ot = 'oltp_' + ds['key']
    cols = ds['cols']
    dcols = [c for c in cols]
    defs = ['  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT']
    names, exprs = [], []
    for c in dcols:
        t = dtype(c)
        defs.append('  `%s` %s NULL' % (c['f'], t))
        names.append(c['f'])
        exprs.append(val_expr(ds, c['h']))
    defs.append('  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP')
    defs.append('  PRIMARY KEY (`oltp_id`)')
    cmap = cm(ds)
    # business key + update column
    bk = cmap[ds['degenerate'][0]]['f'] if ds['degenerate'] and cmap[ds['degenerate'][0]]['k'] != 's' else None
    if ds['degenerate']:
        bk = cmap[ds['degenerate'][0]]['f']
    else:
        bk = [c for c in cols if c['k'] == 's' and c['use']][0]['f']
    um = [cmap[h] for h in ds['measures'] if cmap[h]['k'] in ('d', 'f', 'i') and cmap[h]['f'] != ds['olap']['m'][0]]
    um = (um or [cmap[h] for h in ds['measures'] if cmap[h]['k'] in ('d', 'f', 'i')])[0]['f']
    firstcat = [c for c in cols if c['k'] == 's' and c['use'] and c['f'] != bk][0]['f']
    colist = ', '.join('`%s`' % n for n in names)
    L = [banner('EXPERIMENT 2 - PART A : OLTP OPERATIONS  [%s]' % ds['title'],
                ['OLTP = many small, fast read/write transactions on a normalised, indexed table.',
                 'We build a typed OLTP table `%s` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.' % ot,
                 'Run Experiment 1 step 1 (staging) first.'])]
    L.append('USE `%s`;\n' % stg)
    L.append('DROP TABLE IF EXISTS `%s_audit`;\nDROP TABLE IF EXISTS `%s`;\nCREATE TABLE `%s` (\n%s\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;\n' % (ot, ot, ot, ',\n'.join(defs)))
    L.append('INSERT INTO `%s` (%s)\nSELECT\n  %s\nFROM `%s` s;\n' % (ot, colist, ',\n  '.join(exprs), STG(ds)))
    L.append('CREATE INDEX `idx_%s_bk` ON `%s` (`%s`);\nSELECT COUNT(*) AS oltp_rows FROM `%s`;\n' % (ds['key'], ot, bk, ot))
    L.append('-- ---- 1. READ : point lookups (primary key and business key) -----------------\n'
             'SELECT * FROM `%s` WHERE oltp_id = 1;\n'
             'SELECT * FROM `%s` WHERE `%s` = (SELECT `%s` FROM `%s` WHERE oltp_id = 1) LIMIT 10;\n' % (ot, ot, bk, bk, ot))
    L.append('-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------\n'
             'INSERT INTO `%s` (%s)\nSELECT %s FROM `%s` WHERE oltp_id = 1;\nSET @new_id = LAST_INSERT_ID();\nSELECT * FROM `%s` WHERE oltp_id = @new_id;\n' % (ot, colist, colist, ot, ot))
    L.append('-- ---- 3. UPDATE : change one column of that record ----------------------------\n'
             'UPDATE `%s` SET `%s` = `%s` * 1.10 WHERE oltp_id = @new_id;\nSELECT oltp_id, `%s`, last_modified FROM `%s` WHERE oltp_id = @new_id;\n' % (ot, um, um, um, ot))
    L.append('-- ---- 4. DELETE : remove the record ---------------------------------------------\n'
             'DELETE FROM `%s` WHERE oltp_id = @new_id;\nSELECT COUNT(*) AS rows_after_delete FROM `%s`;\n' % (ot, ot))
    L.append('-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------\n'
             'START TRANSACTION;\n'
             'INSERT INTO `%s` (%s) SELECT %s FROM `%s` WHERE oltp_id = 1;\nSET @tx_id = LAST_INSERT_ID();\n'
             'UPDATE `%s` SET `%s` = `%s` + 1 WHERE oltp_id = @tx_id;\n'
             'SELECT oltp_id, `%s` FROM `%s` WHERE oltp_id = @tx_id;   -- visible inside the transaction\n'
             'COMMIT;\nSELECT COUNT(*) AS rows_after_commit FROM `%s`;\n' % (ot, colist, colist, ot, ot, um, um, um, ot, ot))
    L.append('-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------\n'
             'SELECT COUNT(*) AS before_tx FROM `%s`;\nSTART TRANSACTION;\nDELETE FROM `%s` WHERE oltp_id <= 10;\n'
             'SELECT COUNT(*) AS inside_tx FROM `%s`;\nROLLBACK;\nSELECT COUNT(*) AS after_rollback FROM `%s`;   -- same as before_tx\n' % (ot, ot, ot, ot))
    L.append('-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------\n'
             'START TRANSACTION;\nUPDATE `%s` SET `%s` = `%s` + 1 WHERE oltp_id = 1;\nSAVEPOINT after_first_update;\n'
             'UPDATE `%s` SET `%s` = `%s` + 1000 WHERE oltp_id = 2;\nROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update\n'
             'SELECT oltp_id, `%s` FROM `%s` WHERE oltp_id IN (1, 2);\nROLLBACK;                                   -- undo everything\n' % (ot, um, um, ot, um, um, um, ot))
    L.append('-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------\n'
             '-- Session 1:  START TRANSACTION; SELECT * FROM `%s` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)\n'
             '-- Session 2:  UPDATE `%s` SET `%s` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)\n' % (ot, ot, um))
    L.append('-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------\n'
             'DROP TABLE IF EXISTS `%s_audit`;\n'
             'CREATE TABLE `%s_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);\n'
             'DROP TRIGGER IF EXISTS `trg_%s_audit`;\nDELIMITER $$\n'
             'CREATE TRIGGER `trg_%s_audit` AFTER UPDATE ON `%s`\nFOR EACH ROW\nBEGIN\n'
             '  IF NOT (OLD.`%s` <=> NEW.`%s`) THEN\n    INSERT INTO `%s_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`%s`, NEW.`%s`);\n  END IF;\nEND$$\nDELIMITER ;\n'
             'UPDATE `%s` SET `%s` = `%s` + 5 WHERE oltp_id = 3;\nSELECT * FROM `%s_audit`;\nUPDATE `%s` SET `%s` = `%s` - 5 WHERE oltp_id = 3;   -- restore\n'
             % (ot, ot, ds['key'], ds['key'], ot, um, um, ot, um, um, ot, um, um, ot, ot, um, um))
    L.append('-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------\n'
             'EXPLAIN SELECT * FROM `%s` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row\n'
             'EXPLAIN SELECT `%s`, SUM(`%s`) FROM `%s` GROUP BY `%s`;    -- full table scan + temp table\n' % (ot, firstcat, um, ot, firstcat))
    return '\n'.join(L)


def olap_sql(ds):
    star = DB(ds) + '_star'
    o = ds['olap']
    f = ds['fact']
    m, ml = o['m']
    m2, m2l = o['m2']
    A, B, Cc = o['a'], o['b'], o['c']
    hasdate = bool(ds.get('date'))
    fj = lambda dims: from_joins(ds, dims)  # noqa: E731
    L = [banner('EXPERIMENT 2 - PART B : OLAP OPERATIONS ON THE STAR SCHEMA  [%s]' % ds['title'],
                ['OLAP = few, heavy, read-only analytical queries on a denormalised star schema (fact + dimensions).',
                 'Measure: %s (`%s`)   Dimensions: %s, %s, %s' % (ml, m, A[1], B[1], Cc[1]),
                 'Requires MySQL 8.0+ (GROUPING(), CTEs, window functions). Run Experiment 1 star script first.'])]
    L.append('USE `%s`;\nSET SESSION group_concat_max_len = 1000000;\n' % star)
    L.append('-- ---- 1. BASE AGGREGATE : the fact table summarised through one dimension ------\n'
             'SELECT %s AS %s, SUM(f.`%s`) AS `%s`, SUM(f.`%s`) AS `%s`, COUNT(*) AS fact_rows\n%s\nGROUP BY %s\nORDER BY 2 DESC;\n' %
             (ref(A), A[1], m, ml, m2, m2l, fj([A[0]]), ref(A)))
    if hasdate:
        L.append('-- ---- 2. ROLL-UP (time hierarchy): day > month > quarter > year > ALL ---------------\n'
                 '-- WITH ROLLUP adds sub-total and grand-total rows; GROUPING() labels them.\n'
                 "SELECT IF(GROUPING(d_date.year_num), 'ALL YEARS', d_date.year_num)       AS year_,\n"
                 "       IF(GROUPING(d_date.quarter_num), 'ALL QUARTERS', d_date.quarter_num) AS quarter_,\n"
                 "       IF(GROUPING(d_date.month_num), 'ALL MONTHS', d_date.month_num)    AS month_,\n"
                 '       SUM(f.`%s`) AS `%s`\n%s\nGROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num WITH ROLLUP;\n' %
                 (m, ml, fj(['dim_date'])))
    L.append('-- ---- %s. ROLL-UP (dimension hierarchy): %s > %s > ALL --------------------------------\n'
             "SELECT IF(GROUPING(%s), 'ALL', %s) AS %s_,\n       IF(GROUPING(%s), 'ALL', %s) AS %s_,\n       SUM(f.`%s`) AS `%s`\n%s\n"
             'GROUP BY %s, %s WITH ROLLUP;\n' %
             ('3' if hasdate else '2', A[1], B[1], ref(A), ref(A), A[1], ref(B), ref(B), B[1], m, ml, fj([A[0], B[0]]), ref(A), ref(B)))
    L.append('-- ---- helper variables : the best member of each dimension (so no hard-coded values) ----\n'
             'SET @top_a = (SELECT %s %s GROUP BY %s ORDER BY SUM(f.`%s`) DESC LIMIT 1);\n'
             'SET @top_b = (SELECT %s %s GROUP BY %s ORDER BY SUM(f.`%s`) DESC LIMIT 1);\n'
             'SELECT @top_a AS top_%s, @top_b AS top_%s;\n' %
             (ref(A), fj([A[0]]), ref(A), m, ref(B), fj([B[0]]), ref(B), m, A[1], B[1]))
    L.append('-- ---- 4. DRILL-DOWN : go from summary to detail ---------------------------------------\n'
             '-- Level 1 : by %s\n'
             'SELECT %s AS %s, SUM(f.`%s`) AS `%s`\n%s\nGROUP BY %s ORDER BY 2 DESC;\n'
             '-- Level 2 : drill into the top %s, split by %s\n'
             'SELECT %s AS %s, %s AS %s, SUM(f.`%s`) AS `%s`\n%s\nWHERE %s = @top_a\nGROUP BY %s, %s ORDER BY 3 DESC;\n'
             '-- Level 3 : drill further into the top %s, split by %s\n'
             'SELECT %s AS %s, %s AS %s, %s AS %s, SUM(f.`%s`) AS `%s`\n%s\nWHERE %s = @top_a AND %s = @top_b\nGROUP BY %s, %s, %s ORDER BY 4 DESC LIMIT 20;\n' %
             (A[1], ref(A), A[1], m, ml, fj([A[0]]), ref(A),
              A[1], B[1], ref(A), A[1], ref(B), B[1], m, ml, fj([A[0], B[0]]), ref(A), ref(A), ref(B),
              B[1], Cc[1], ref(A), A[1], ref(B), B[1], ref(Cc), Cc[1], m, ml, fj([A[0], B[0], Cc[0]]), ref(A), ref(B), ref(A), ref(B), ref(Cc)))
    if hasdate:
        L.append('-- Time drill-down : year > quarter > month (for the latest year)\n'
                 'SET @last_year = (SELECT MAX(year_num) FROM dim_date);\n'
                 'SELECT d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name, SUM(f.`%s`) AS `%s`\n%s\nWHERE d_date.year_num = @last_year\n'
                 'GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name ORDER BY d_date.month_num;\n' % (m, ml, fj(['dim_date'])))
    L.append('-- ---- 5. SLICE : fix ONE dimension to a single value (a "slice" of the cube) ---------\n'
             'SELECT %s AS %s, SUM(f.`%s`) AS `%s`\n%s\nWHERE %s = @top_a            -- %s fixed to its best member\nGROUP BY %s ORDER BY 2 DESC;\n' %
             (ref(B), B[1], m, ml, fj([A[0], B[0]]), ref(A), A[1], ref(B)))
    if hasdate:
        L.append('-- Slice on time : only the latest year\nSELECT %s AS %s, SUM(f.`%s`) AS `%s`\n%s\nWHERE d_date.year_num = (SELECT MAX(year_num) FROM dim_date)\nGROUP BY %s ORDER BY 2 DESC;\n' %
                 (ref(A), A[1], m, ml, fj([A[0], 'dim_date']), ref(A)))

    def top_n(t, n):
        return ('(SELECT member FROM (SELECT %s AS member %s GROUP BY %s ORDER BY SUM(f.`%s`) DESC LIMIT %d) t_%s)' %
                (ref(t), fj([t[0]]).replace('\n', ' '), ref(t), m, n, t[1]))

    L.append('-- ---- 6. DICE : restrict SEVERAL dimensions at once (a sub-cube) ------------------------\n'
             'SELECT %s AS %s, %s AS %s, SUM(f.`%s`) AS `%s`\n%s\nWHERE %s IN %s\n  AND %s IN %s\nGROUP BY %s, %s ORDER BY 3 DESC;\n' %
             (ref(A), A[1], ref(B), B[1], m, ml, fj([A[0], B[0]]), ref(A), top_n(A, 2), ref(B), top_n(B, 3), ref(A), ref(B)))
    # pivot
    if hasdate:
        mem = ("(SELECT DISTINCT month_num, month_name FROM `dim_date`) x")
        cs = ("SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN d_date.month_num = ', month_num, ' THEN f.`%s` ELSE 0 END) AS `', month_name, '`') ORDER BY month_num SEPARATOR ', ') FROM %s);\n" % (m, mem))
        pdims = [A[0], 'dim_date']
        pcol = 'month'
    else:
        mem = ("(SELECT DISTINCT `%s` AS member FROM `%s` WHERE `%s` IS NOT NULL) x" % (B[1], B[0], B[1]))
        cs = ("SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN %s = ', QUOTE(member), ' THEN f.`%s` ELSE 0 END) AS `', member, '`') ORDER BY member SEPARATOR ', ') FROM %s);\n" % (ref(B), m, mem))
        pdims = [A[0], B[0]]
        pcol = B[1]
    joins_txt = fj(pdims).replace('\n', ' ')
    L.append('-- ---- 7. PIVOT : rotate %s into columns (MySQL has no PIVOT keyword -> dynamic SQL) ------\n%s'
             "SET @pivot_sql = CONCAT('SELECT %s AS `%s`, ', @pivot_cols, ', SUM(f.`%s`) AS `Total` %s GROUP BY %s ORDER BY `Total` DESC');\n"
             'PREPARE pivot_stmt FROM @pivot_sql;\nEXECUTE pivot_stmt;\nDEALLOCATE PREPARE pivot_stmt;\n' %
             (pcol, cs, ref(A), A[1], m, joins_txt, ref(A)))
    L.append('-- ---- 8. CUBE : every combination of (%s, %s) incl. sub-totals and grand total ----------\n'
             '-- (MySQL has no CUBE keyword: UNION ALL of the four grouping sets)\n'
             "SELECT CAST(%s AS CHAR) AS %s_, CAST(%s AS CHAR) AS %s_, SUM(f.`%s`) AS `%s`\n%s\nGROUP BY %s, %s\n"
             "UNION ALL\nSELECT CAST(%s AS CHAR), 'ALL', SUM(f.`%s`)\n%s\nGROUP BY %s\n"
             "UNION ALL\nSELECT 'ALL', CAST(%s AS CHAR), SUM(f.`%s`)\n%s\nGROUP BY %s\n"
             "UNION ALL\nSELECT 'ALL', 'ALL', SUM(f.`%s`)\n%s;\n" %
             (A[1], B[1], ref(A), A[1], ref(B), B[1], m, ml, fj([A[0], B[0]]), ref(A), ref(B),
              ref(A), m, fj([A[0]]), ref(A), ref(B), m, fj([B[0]]), ref(B), m, fj([])))
    L.append('-- ---- 9. WINDOW FUNCTIONS : rank, share of total, Pareto (cumulative %%) --------------------\n'
             'WITH by_member AS (\n  SELECT %s AS member, SUM(f.`%s`) AS total\n  %s\n  GROUP BY %s\n)\n'
             'SELECT member, total,\n       RANK() OVER (ORDER BY total DESC) AS rank_,\n'
             '       ROUND(100 * total / SUM(total) OVER (), 2) AS pct_of_total,\n'
             '       ROUND(100 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 2) AS cumulative_pct\n'
             'FROM by_member ORDER BY rank_;\n' % (ref(A), m, fj([A[0]]).replace('\n', '\n  '), ref(A)))
    if hasdate:
        L.append('-- Running total and month-over-month change\n'
                 'WITH monthly AS (\n  SELECT d_date.year_num AS yr, d_date.month_num AS mon, SUM(f.`%s`) AS total\n  %s\n  GROUP BY d_date.year_num, d_date.month_num\n)\n'
                 'SELECT yr, mon, total,\n       SUM(total) OVER (PARTITION BY yr ORDER BY mon) AS year_to_date,\n'
                 '       LAG(total) OVER (ORDER BY yr, mon) AS previous_month,\n'
                 '       ROUND(100 * (total - LAG(total) OVER (ORDER BY yr, mon)) / NULLIF(LAG(total) OVER (ORDER BY yr, mon), 0), 2) AS mom_change_pct\n'
                 'FROM monthly ORDER BY yr, mon;\n' % (m, fj(['dim_date']).replace('\n', '\n  ')))
    if o.get('ratio'):
        lab, num, den = o['ratio']
        L.append('-- ---- 10. KPI RATIO per %s : %s -------------------------------------------------\n'
                 'SELECT %s AS %s, ROUND(%s / NULLIF(%s, 0), 2) AS `%s`\n%s\nGROUP BY %s ORDER BY 2 DESC;\n' %
                 (A[1], lab, ref(A), A[1], num, den, lab, fj([A[0]]), ref(A)))
    L.append('-- ---- 11. AGGREGATE (SUMMARY) TABLE : pre-computed cube level for fast dashboards ------\n'
             'DROP TABLE IF EXISTS `agg_%s_by_%s_%s`;\nCREATE TABLE `agg_%s_by_%s_%s` AS\n'
             'SELECT %s AS %s_, %s AS %s_, SUM(f.`%s`) AS total_%s, SUM(f.`%s`) AS total_%s, COUNT(*) AS fact_rows\n%s\nGROUP BY %s, %s;\n'
             'SELECT * FROM `agg_%s_by_%s_%s` ORDER BY total_%s DESC LIMIT 10;   -- no joins needed any more\n' %
             (ds['key'], A[1], B[1], ds['key'], A[1], B[1], ref(A), A[1], ref(B), B[1], m, m, m2, m2, fj([A[0], B[0]]), ref(A), ref(B),
              ds['key'], A[1], B[1], m))
    return '\n'.join(L)


def view_sql(ds):
    star = DB(ds) + '_star'
    dims = build_star(ds)
    items = fact_items(ds, dims)
    cols, names = [], []
    for d in dims:
        for c in d['cols']:
            cols.append('%s.`%s` AS `%s`' % (alias(d['name']), c['name'], c['name']))
            names.append(c['name'])
    if ds.get('date'):
        for n in ['full_date', 'year_num', 'quarter_num', 'month_num', 'month_name', 'day_name']:
            cols.append('d_date.`%s` AS `%s`' % (n, n))
            names.append(n)
    for (n, ty, e, d) in items:
        if d is None and n != 'date_key':
            cols.append('f.`%s` AS `%s`' % (n, n))
            names.append(n)
    dup = {n for n in names if names.count(n) > 1}
    assert not dup, (ds['key'], dup)
    dn = [d['name'] for d in dims] + (['dim_date'] if ds.get('date') else [])
    return (banner('EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [%s]' % ds['title'],
                   ['Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)',
                    'Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.']) +
            'USE `%s`;\nCREATE OR REPLACE VIEW `vw_%s_flat` AS\nSELECT\n  %s\n%s;\n\nSELECT * FROM `vw_%s_flat` LIMIT 10;\n' %
            (star, ds['key'], ',\n  '.join(cols), from_joins(ds, dn), ds['key']))


# ----------------------------------------------------------------------------- diagrams
def sty_type(t):
    return re.sub(r'\(.*\)', '', t)


def rows_of(t):
    fkset = {c for (c, _, _) in t.get('fks', [])}
    rows = ['PK  %s  %s' % (t['pk'], t.get('pk_type', 'INT'))]
    for c in t['cols']:
        rows.append('%s  %s  %s' % ('FK ' if c['name'] in fkset else '      ', c['name'], sty_type(c['type'])))
    return rows


def mermaid(tables, rels):
    out = ['```mermaid', 'erDiagram']
    for (child, parent, label) in rels:
        out.append('    %s }o--|| %s : "%s"' % (child.upper(), parent.upper(), label))
    for t in tables:
        out.append('    %s {' % t['name'].upper())
        out.append('        %s %s PK' % (sty_type(t.get('pk_type', 'INT')), t['pk']))
        fkset = {c for (c, _, _) in t.get('fks', [])}
        for c in t['cols']:
            out.append('        %s %s%s' % (sty_type(c['type']), c['name'], ' FK' if c['name'] in fkset else ''))
        out.append('    }')
    out.append('```')
    return '\n'.join(out)


def drawio(title, fact, trees):
    W, RH, HH, GX, GY = 240, 20, 28, 120, 40
    FW = 280
    cells = []
    nid = [10]

    def newid():
        nid[0] += 1
        return 'c%d' % nid[0]

    def height(n):
        return HH + RH * len(n['rows'])

    def used(n):
        ch = sum(used(c) + GY for c in n['children']) - GY if n['children'] else 0
        return max(height(n), ch)

    def style(kind):
        col = {'fact': ('#dae8fc', '#6c8ebf'), 'dim': ('#d5e8d4', '#82b366'), 'sub': ('#fff2cc', '#d6b656')}[kind]
        return ('swimlane;fontStyle=1;childLayout=stackLayout;horizontal=1;startSize=%d;horizontalStack=0;resizeParent=1;'
                'resizeParentMax=0;resizeLast=0;collapsible=0;marginBottom=0;fillColor=%s;strokeColor=%s;fontSize=13;' % (HH, col[0], col[1]))

    def vertex(n, x, y, w, kind):
        i = newid()
        cells.append('<mxCell id="%s" value="%s" style="%s" vertex="1" parent="1"><mxGeometry x="%d" y="%d" width="%d" height="%d" as="geometry"/></mxCell>' %
                     (i, escape(n['name'], {'"': '&quot;'}), style(kind), x, y, w, height(n)))
        for k, r in enumerate(n['rows']):
            cells.append('<mxCell id="%s" value="%s" style="text;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;spacingLeft=6;spacingRight=4;overflow=hidden;rotatable=0;fontFamily=Courier New;fontSize=11;whiteSpace=nowrap;" vertex="1" parent="%s"><mxGeometry y="%d" width="%d" height="%d" as="geometry"/></mxCell>' %
                         (newid(), escape(r, {'"': '&quot;'}), i, HH + k * RH, w, RH))
        return i

    def edge(a, b):
        cells.append('<mxCell id="%s" style="edgeStyle=entityRelationEdgeStyle;fontSize=12;html=1;endArrow=ERmandOne;startArrow=ERmany;endFill=0;startFill=0;rounded=0;" edge="1" parent="1" source="%s" target="%s"><mxGeometry relative="1" as="geometry"/></mxCell>' % (newid(), a, b))

    side_tot = {'L': 0, 'R': 0}
    plan = []
    for i, t in enumerate(trees):
        side = 'L' if i % 2 == 0 else 'R'
        plan.append((t, side, side_tot[side]))
        side_tot[side] += used(t) + GY
    total = max(side_tot.values()) - GY
    fh = HH + RH * len(fact['rows'])
    fy = max(0, int((total - fh) / 2))
    fid = vertex(fact, 0, fy, FW, 'fact')

    def place(n, col, y, side, parent_id, kind):
        x = (FW + GX + (col - 1) * (W + GX)) if side == 'R' else -(col * (W + GX))
        nid_ = vertex(n, x, y, W, kind)
        edge(parent_id, nid_)
        cy = y
        for c in n['children']:
            place(c, col + 1, cy, side, nid_, 'sub')
            cy += used(c) + GY

    for (t, side, y) in plan:
        place(t, 1, y, side, fid, 'dim')
    xml = ('<mxfile host="app.diagrams.net"><diagram name="%s" id="dmbi1"><mxGraphModel dx="1600" dy="900" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1654" pageHeight="1169" math="0" shadow="0"><root><mxCell id="0"/><mxCell id="1" parent="0"/>%s</root></mxGraphModel></diagram></mxfile>' %
           (escape(title, {'"': '&quot;'}), ''.join(cells)))
    return xml


def node(t, children=()):
    return dict(name=t['name'], rows=rows_of(t), children=list(children))


# ----------------------------------------------------------------------------- docs: experiment 1
def exp1_readme(ds):
    star = build_star(ds)
    snow = build_snow(ds)
    hasdate = bool(ds.get('date'))
    fact = fact_table(ds, star)
    factn = fact_table(ds, snow)
    db = DB(ds)
    subs = [s for d in snow for s in d.get('subs', [])]
    L = ['# Experiment 1 - Star and Snowflake Schema : %s\n' % ds['title'],
         '**Aim:** design and implement a star schema and a snowflake schema for efficient storage and retrieval of the %s data for BI.\n' % ds['title'],
         '## Files (run in this order)\n',
         '| # | File | What it does |', '|---|------|--------------|',
         '| 1 | `01_staging_load.sql` | creates schema `%s_stg`, staging table, loads the CSV (**edit the path**) |' % db,
         '| 2 | `02_star_schema.sql` | creates schema `%s_star`: DDL + ETL for the star schema |' % db,
         '| 3 | `03_snowflake_schema.sql` | creates schema `%s_snow`: DDL + ETL for the snowflake schema |' % db,
         '| 4 | `04_verify_and_compare.sql` | row-count / total checks and star-vs-snowflake sample queries |',
         '| - | `star_schema.drawio`, `snowflake_schema.drawio` | open in draw.io (File > Open) for the diagram screenshots |',
         '| - | `schema_diagrams.md` | the same diagrams as Mermaid ER code (renders on GitHub/VS Code) |\n',
         '## How to run\n',
         '**Command line (Windows cmd or Linux terminal):**',
         '```', 'mysql -u root -p --local-infile=1', 'mysql> SOURCE 01_staging_load.sql;', 'mysql> SOURCE 02_star_schema.sql;',
         'mysql> SOURCE 03_snowflake_schema.sql;', 'mysql> SOURCE 04_verify_and_compare.sql;', '```',
         '(start `mysql` from inside this folder, or give the full path with forward slashes).\n',
         '**MySQL Workbench:** File > Open SQL Script > pick the file > click the lightning icon. Repeat for each file in order.\n',
         '## Design decisions (say these in the viva)\n',
         '* **Grain of the fact table:** %s' % ds['grain'],
         '* **Fact table `%s`** holds the numeric measures: %s.' % (ds['fact'], ', '.join('`%s`' % cm(ds)[h]['f'] for h in ds['measures'])),
         ('* **Derived measures:** ' + ', '.join('`%s`' % n for (n, _, _) in ds['fact_derived']) + ' (calculated during the ETL).') if ds['fact_derived'] else '',
         ('* **Degenerate dimension(s)** (identifier kept inside the fact, no table): ' + ', '.join('`%s`' % cm(ds)[h]['f'] for h in ds['degenerate'])) if ds['degenerate'] else '',
         ('* **Date dimension** `dim_date` (day, month, quarter, year, weekday, weekend flag); the fact stores `date_key` = yyyymmdd.') if hasdate else '* There is no date column in this dataset, so there is no date dimension.',
         '* **Surrogate keys:** every dimension has an AUTO_INCREMENT `*_key`; the fact references them with foreign keys.',
         '* **NULL-safe joins (`<=>`)** keep rows that have blank attributes.\n',
         '## Star schema tables\n', '| Table | Type | Columns |', '|-------|------|---------|',
         '| `%s` | FACT | %s |' % (ds['fact'], ', '.join('`%s`' % c['name'] for c in fact['cols']))]
    if hasdate:
        L.append('| `dim_date` | DIM | %s |' % ', '.join('`%s`' % c['name'] for c in DATE_STAR['cols']))
    for d in star:
        L.append('| `%s` | DIM | %s |' % (d['name'], ', '.join('`%s`' % c['name'] for c in d['cols'])))
    L.append('\n## Snowflake schema - what changes\n')
    L.append('Same fact table, but dimension attributes are moved into **sub-dimension** tables (3NF) and the parent keeps a foreign key:\n')
    L.append('| Parent dimension | Sub-dimension(s) |\n|---|---|')
    for d in snow:
        if d.get('subs'):
            L.append('| `%s` | %s |' % (d['name'], ', '.join('`%s` (%s)' % (s['name'], ', '.join(c['name'] for c in s['cols'])) for s in d['subs'])))
    if hasdate:
        L.append('| `dim_date` | `dim_month` > `dim_quarter` > `dim_year` (calendar hierarchy) |')
    L.append('\n| | Star | Snowflake |\n|---|---|---|\n| Dimensions | denormalised (one table each) | normalised into sub-dimensions |\n'
             '| Joins per query | fewer, faster | more joins, slower |\n| Storage | some redundancy | less redundancy |\n| Maintenance | simpler | updates of a value happen in one place |\n'
             '| Tables | %d | %d |\n' % (len(star) + 1 + (1 if hasdate else 0), len(snow) + len(subs) + 1 + (4 if hasdate else 0)))
    L.append('## Screenshots to take for the lab file\n1. ER diagram (draw.io) of the star schema\n2. ER diagram of the snowflake schema\n3. Output of `SHOW TABLES` in each schema\n4. Row counts (step 4 query 1) and one analysis query from each schema\n')
    return '\n'.join(x for x in L if x != '')


def diagrams_md(ds):
    star = build_star(ds)
    snow = build_snow(ds)
    hasdate = bool(ds.get('date'))
    sd = ([DATE_STAR] if hasdate else []) + star
    fs = fact_table(ds, star)
    rels = [(ds['fact'], t['name'], t['pk']) for t in sd]
    L = ['# Schema diagrams - %s\n' % ds['title'], 'Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.\n',
         '## Star schema\n', mermaid([fs] + sd, rels), '\n## Snowflake schema\n']
    fn = fact_table(ds, snow)
    tabs = [fn] + (list(reversed(DATE_SNOW)) if hasdate else []) + [s for d in snow for s in d.get('subs', [])] + snow
    rel2 = []
    for d in snow:
        rel2.append((ds['fact'], d['name'], d['pk']))
        for s in d.get('subs', []):
            rel2.append((d['name'], s['name'], s['pk']))
    if hasdate:
        rel2 += [(ds['fact'], 'dim_date', 'date_key'), ('dim_date', 'dim_month', 'month_key'), ('dim_month', 'dim_quarter', 'quarter_key'), ('dim_quarter', 'dim_year', 'year_key')]
    L.append(mermaid(tabs, rel2))
    return '\n'.join(L)


def drawio_files(ds):
    star = build_star(ds)
    snow = build_snow(ds)
    hasdate = bool(ds.get('date'))
    fs = node(fact_table(ds, star))
    trees = ([node(DATE_STAR)] if hasdate else []) + [node(d) for d in star]
    a = drawio('Star schema - %s' % ds['title'], fs, trees)
    fn = node(fact_table(ds, snow))
    t2 = []
    if hasdate:
        t2.append(node(DATE_SNOW[3], [node(DATE_SNOW[2], [node(DATE_SNOW[1], [node(DATE_SNOW[0])])])]))
    for d in snow:
        t2.append(node(d, [node(s) for s in d.get('subs', [])]))
    b = drawio('Snowflake schema - %s' % ds['title'], fn, t2)
    return a, b


# ----------------------------------------------------------------------------- docs: experiment 2
def exp2_readme(ds):
    o = ds['olap']
    L = ['# Experiment 2 - OLAP and OLTP operations : %s\n' % ds['title'],
         '**Aim:** implement OLTP and OLAP operations using SQL queries and data-warehouse concepts.\n',
         '## Files\n', '| File | Schema it runs on | Content |', '|---|---|---|',
         '| `01_oltp_operations.sql` | `%s_stg` (table `oltp_%s`) | CRUD, ACID transactions, COMMIT/ROLLBACK, SAVEPOINT, locking, trigger, EXPLAIN |' % (DB(ds), ds['key']),
         '| `02_olap_operations.sql` | `%s_star` (star schema from Experiment 1) | roll-up, drill-down, slice, dice, pivot, cube, window functions, KPI ratio, summary table |\n' % DB(ds),
         '**Run Experiment 1 (steps 1 and 2) first.** Requires MySQL 8.0+.\n',
         '## OLTP vs OLAP\n', '| | OLTP | OLAP |', '|---|---|---|',
         '| Purpose | run the business (record sales) | analyse the business (decisions) |', '| Operations | INSERT / UPDATE / DELETE / SELECT one row | big SELECT with GROUP BY over millions of rows |',
         '| Data model | normalised, many tables, indexed by primary key | star/snowflake (fact + dimensions), denormalised |', '| Data | current, detailed | historical, summarised |',
         '| Users | clerks, apps | analysts, managers |', '| Speed goal | milliseconds per transaction | acceptable seconds for complex queries |', '| Integrity | ACID transactions | read-mostly, loaded by ETL |\n',
         '## OLAP operations in `02_olap_operations.sql`\n', '| Operation | Meaning | Where |', '|---|---|---|',
         '| Roll-up | go from detail to summary (climb a hierarchy) | `WITH ROLLUP` |', '| Drill-down | go from summary to detail | 3-level queries |',
         '| Slice | fix one dimension to one value | `WHERE %s = @top_a` |' % ref(o['a']), '| Dice | restrict several dimensions (sub-cube) | `IN (top 2/3)` filters |',
         '| Pivot | rotate rows into columns | dynamic `CASE` pivot |', '| Cube | all combinations of dimensions | `UNION ALL` of grouping sets |',
         '| Window functions | rank, % of total, running total | `RANK() OVER`, `SUM() OVER` |', '| Aggregate table | pre-computed summary for speed | `CREATE TABLE agg_...` |\n',
         'Measure used: **%s** (`%s`). Dimensions used: **%s**, **%s**, **%s**.\n' % (o['m'][1], o['m'][0], o['a'][1], o['b'][1], o['c'][1]),
         '## Tip for the viva\nOLTP query: `EXPLAIN` shows `const` (index lookup, 1 row). OLAP query: full scan + grouping. That is exactly why a separate star schema exists for analysis.\n']
    return '\n'.join(L)


# ----------------------------------------------------------------------------- docs: experiment 4
def mtype(c):
    return {'s': 'type text', 'yn': 'type text', 'i': 'Int64.Type', 'bi': 'Int64.Type', 'd': 'type number', 'f': 'type number',
            'date': 'type date', 'time': 'type time'}[c['k']]


def m_script(ds):
    cols = ds['cols']
    e4 = ds['exp4']
    steps = []

    def add(name, code):
        steps.append((name, code))

    path = 'C:' + BS + 'Users' + BS + 'YOUR_USER' + BS + 'Music' + BS + ds['folder_music'] + BS + ds['csv']
    add('Source', 'Csv.Document(File.Contents("%s"), [Delimiter=",", Columns=%d, Encoding=65001, QuoteStyle=QuoteStyle.Csv])' % (path, len(cols)))
    add('Promoted Headers', 'Table.PromoteHeaders(Source, [PromoteAllScalars=true])')
    prev = 'Promoted Headers'
    cur = ds.get('cur')

    def last():
        return '#"%s"' % steps[-1][0] if ' ' in steps[-1][0] or True else steps[-1][0]

    if cur:
        dcols = [c['h'] for c in cols if c['k'] == 'd']
        tr = ', '.join('{"%s", each try Number.FromText(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.From(_), "$", ""), ",", ""), "(", "-"), ")", "")) otherwise null, type number}' % h for h in dcols)
        add('Cleaned Currency', 'Table.TransformColumns(%s, {%s})' % (last(), tr))
        add('Fixed Year and Month', 'Table.TransformColumns(%s, {{"Year", each Number.From(Text.Replace(Text.From(_), ",", "")), Int64.Type}, {"Month Number", each Number.From(_), Int64.Type}})' % last())
        add('Rebuilt Date', 'Table.AddColumn(%s, "Date New", each #date([Year], [Month Number], 1), type date)' % last())
        add('Removed Old Date', 'Table.RemoveColumns(%s, {"Date"})' % last())
        add('Renamed Date', 'Table.RenameColumns(%s, {{"Date New", "Date"}})' % last())
    typed = []
    for c in cols:
        if cur and (c['k'] == 'd' or c['h'] in ('Year', 'Month Number', 'Date')):
            continue
        if c['k'] == 'date' and '%H' in (ds['date'].get('fmt') or ''):
            typed.append((c['h'], 'type datetime'))
        else:
            typed.append((c['h'], mtype(c)))
    tl = ', '.join('{"%s", %s}' % (h, t) for h, t in typed)
    add('Changed Type', 'Table.TransformColumnTypes(%s, {%s}, "en-US")' % (last(), tl))
    if ds.get('date') and '%H' in (ds['date'].get('fmt') or ''):
        add('Date Only', 'Table.TransformColumns(%s, {{"%s", DateTime.Date, type date}})' % (last(), ds['date']['col']))
    if not cur:
        drop = [c['h'] for c in cols if not c['use']]
        if drop:
            add('Removed Constant Columns', 'Table.RemoveColumns(%s, {%s})' % (last(), ', '.join('"%s"' % h for h in drop)))
    tcols = [c['h'] for c in cols if c['k'] == 's' and c['use'] or (cur and c['k'] == 's' and c['h'] not in ('Year', 'Month Number'))]
    tcols = [h for h in tcols if h in {c['h'] for c in cols} and (not (cur and h == 'Month Number'))]
    if tcols:
        add('Trimmed Text', 'Table.TransformColumns(%s, {%s})' % (last(), ', '.join('{"%s", Text.Trim, type text}' % h for h in tcols)))
    add('Removed Duplicates', 'Table.Distinct(%s)' % last())
    nn = e4['nn']
    add('Removed Null Keys', 'Table.SelectRows(%s, each %s)' % (last(), ' and '.join('[%s] <> null' % h for h in nn)))
    for (name, mexpr, mt, _t) in e4['derived']:
        add('Added ' + name, 'Table.AddColumn(%s, "%s", each %s, %s)' % (last(), name, mexpr, mt))
    L = ['// ' + '=' * 70, '// POWER QUERY (M) SCRIPT - %s' % ds['title'],
         '// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.',
         '// 1) Edit the path in the first step.  2) Rename the query to  %s  (right-click it in the Queries pane) so the DAX file works.' % ds['tbl'],
         '// ' + '=' * 70, 'let']
    for i, (n, code) in enumerate(steps):
        L.append('    #"%s" = %s%s' % (n, code, ',' if i < len(steps) - 1 else ''))
    L.append('in')
    L.append('    #"%s"' % steps[-1][0])
    return '\n'.join(L).replace('#"Source" = ', 'Source = ').replace('Table.PromoteHeaders(#"Source"', 'Table.PromoteHeaders(Source')


def dax_file(ds):
    t = ds['tbl']
    e4 = ds['exp4']
    L = ['// ' + '=' * 70, '// DAX MEASURES - %s   (table name used below: %s)' % (ds['title'], t),
         '// Power BI: Report view > Modeling > New measure > paste ONE line at a time (or use Tabular Editor).',
         '// If your table has another name, use Find/Replace on "%s[".' % t, '// ' + '=' * 70, '', '// ---- 1. basic measures ----']
    for m in e4['meas']:
        L.append('Total %s = SUM(%s[%s])' % (m, t, m))
        L.append('Avg %s = AVERAGE(%s[%s])' % (m, t, m))
    L.append('Row Count = COUNTROWS(%s)' % t)
    L += ['', '// ---- 2. business measures ----']
    for (n, e) in e4['dax']:
        L.append('%s = %s' % (n, e))
    if ds.get('date'):
        dc = ds['date']['col']
        main = MAIN[ds['key']]
        L += ['', '// ---- 3. date table + time intelligence ----',
              '// Modeling > New table; then Model view: relate DateTable[Date] (one) to %s[%s] (many). Mark as date table.' % (t, dc),
              'DateTable = ADDCOLUMNS(CALENDAR(MIN(%s[%s]), MAX(%s[%s])), "Year", YEAR([Date]), "Quarter", "Q" & QUARTER([Date]), "MonthNo", MONTH([Date]), "Month", FORMAT([Date], "MMM"), "Weekday", FORMAT([Date], "ddd"))' % (t, dc, t, dc),
              '%s YTD = TOTALYTD([%s], DateTable[Date])' % (main[6:], main),
              '%s Prev Year = CALCULATE([%s], SAMEPERIODLASTYEAR(DateTable[Date]))' % (main[6:], main),
              '%s MoM %% = VAR cur = [%s] VAR prev = CALCULATE([%s], DATEADD(DateTable[Date], -1, MONTH)) RETURN DIVIDE(cur - prev, prev)' % (main[6:], main, main)]
    return '\n'.join(L)


def tableau_md(ds):
    e4 = ds['exp4']
    L = ['# Tableau Public steps - %s\n' % ds['title'],
         '> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.\n',
         '## 1. Connect and clean (Extract + Transform)\n',
         '1. Open Tableau Public > **Connect > Text file** > pick `%s`.' % ds['csv'],
         '2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).',
         '3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.',
         '4. Switch to a sheet (bottom-left).\n']
    if e4.get('geo'):
        L.append('5. Right click **%s** in the Data pane > **Geographic Role** > choose the matching role (City/Country) so maps work.\n' % e4['geo'])
    L.append('## 2. Calculated fields (Analysis > Create Calculated Field)\n')
    L.append('| Name | Formula |\n|---|---|')
    for (n, _m, _t, tab) in e4['derived']:
        L.append('| %s | `%s` |' % (n, tab))
    L.append('\n## 3. Worksheets\n')
    for i, (typ, fields, q) in enumerate(e4['viz'], 1):
        L.append('**Sheet %d - %s**  \n*Question:* %s  \n*Build:* %s  \n*Mark type:* choose `%s` from the Marks card; add labels / colour as needed.\n' % (i, typ, q, fields, typ.split(' ')[0]))
    L += ['## 4. Dashboard\n',
          '1. Dashboard > New Dashboard > size *Automatic*.', '2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).',
          '3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.',
          '4. Add a title and short text box with 2-3 insights.', '5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.']
    return '\n'.join(L)


def viz_md(ds):
    e4 = ds['exp4']
    L = ['# Recommended visualisations and insights - %s\n' % ds['title'],
         '| # | Visual | Fields | Business question |', '|---|--------|--------|-------------------|']
    for i, (typ, fields, q) in enumerate(e4['viz'], 1):
        L.append('| %d | %s | %s | %s |' % (i, typ, fields, q))
    L += ['\n## Dashboard layout (also covers the dashboard idea of Experiment 3)\n',
          '```', '+------------------------------------------------------------+', '|  KPI cards (totals / averages / rates)     |  slicers        |',
          '+------------------------------------------------------------+', '|  trend / time visual         |  top-N breakdown            |',
          '+------------------------------------------------------------+', '|  category comparison         |  map or matrix / detail     |',
          '+------------------------------------------------------------+', '```\n',
          '## Insight sentences (fill with your numbers)\n']
    for i, (typ, fields, q) in enumerate(e4['viz'], 1):
        L.append('%d. *%s* -> "**<top member>** leads with **<value>** (%s%% of total); **<lowest member>** is lowest; the gap suggests <action>."' % (i, q, '<x>'))
    L += ['\n## Data-quality checks before visualising\n', '* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)',
          '* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)',
          '* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match']
    for n in ds['notes']:
        L.append('* dataset note: ' + n)
    return '\n'.join(L)


def exp4_readme(ds):
    e4 = ds['exp4']
    L = ['# Experiment 4 - Extract, Transform, Visualise (Power BI / Tableau) : %s\n' % ds['title'],
         '**Aim:** extract, transform and visualise business data with Power BI / Tableau and derive insights.\n',
         '## Files\n', '| File | Use |', '|---|---|',
         '| `01_power_query_transform.m` | paste into Power BI Advanced Editor: loads the CSV, fixes types, cleans, adds derived columns |',
         '| `02_dax_measures.dax` | measures for cards/charts (and time intelligence when a date exists) |',
         '| `03_tableau_public_steps.md` | the same work in Tableau Public (connect, calculated fields, sheets, dashboard) |',
         '| `04_visualizations_and_insights.md` | which charts to build, which question each answers, insight sentences |',
         '| `05_mysql_flat_view.sql` | optional: flat view on the star schema if you want to extract from MySQL instead of the CSV |\n',
         '## Power BI workflow (about 20 minutes)\n',
         '1. **Extract:** Home > Get data > Text/CSV > select `%s` > **Transform Data**.' % ds['csv'],
         '2. **Transform:** Home > Advanced Editor > replace all with `01_power_query_transform.m` (edit the path) > Done. Rename the query to `%s`.' % ds['tbl'],
         '   Check *Column quality / distribution / profile* (View tab) for errors and empty values.',
         '3. **Load:** Home > Close & Apply.',
         '4. **Model:** add measures from `02_dax_measures.dax` (Modeling > New measure).',
         '5. **Visualise:** build the visuals listed in `04_visualizations_and_insights.md`; add slicers for %s.' % ', '.join(e4['cat'][:3]),
         '6. **Insights:** write 3-5 observations on the report page (text box) and save the .pbix.',
         '7. Screenshots: Power Query steps, data model/relationships, final report page.\n',
         '**Extract from MySQL instead (optional):** Get data > MySQL database > server `localhost`, database `%s_star` > pick `vw_%s_flat` (create it with `05_mysql_flat_view.sql`). Needs the MySQL Connector/NET driver.\n' % (DB(ds), ds['key']),
         '## Transformations applied\n', '| Derived column | Power Query (M) |', '|---|---|']
    for (n, mexpr, _mt, _t) in e4['derived']:
        L.append('| %s | `%s` |' % (n, mexpr))
    L += ['\n| Cleaning step | Why |', '|---|---|', '| Promote headers, change data types | CSV arrives as text |', '| Trim text columns | hidden spaces break grouping |',
          '| Remove duplicate rows | avoid double counting |', '| Remove rows with a null key (%s) | incomplete records |' % ', '.join(e4['nn'])]
    if ds.get('cur'):
        L.append('| Currency text -> number | values like `$1,618.50` and `($1,000.00)` |')
    if not ds.get('cur') and any(not c['use'] for c in ds['cols']):
        L.append('| Remove constant columns | no analytical value |')
    L.append('')
    return '\n'.join(L)


# ----------------------------------------------------------------------------- dataset README
def dataset_readme(ds):
    star = build_star(ds)
    L = ['# %s\n' % ds['title'], '**Confidence in column list:** %s\n' % CONF[ds['conf']], '**Source:** %s\n' % ds['source']]
    if ds['ambig']:
        L.append('> WARNING: several public files share this name. Open your CSV, compare its header row with the table below. If it differs, follow `00_Common/If_Your_Columns_Differ.md`.\n')
    L += ['## Columns (%d)\n' % len(ds['cols']), '| # | Column | Type | Meaning |', '|---|--------|------|---------|']
    kn = {'s': 'text', 'i': 'int', 'bi': 'bigint', 'd': 'decimal', 'f': 'decimal', 'date': 'date', 'time': 'time', 'yn': 'yes/no flag'}
    for i, c in enumerate(ds['cols'], 1):
        L.append('| %d | `%s` | %s | %s |' % (i, c['h'], kn[c['k']], c['d']))
    L += ['\n## Notes\n'] + ['* ' + n for n in ds['notes']]
    L += ['\n## Folder map\n', '```', '%s/' % ds['folder'],
          '  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams',
          '  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL', '  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals', '```\n',
          '## Exam-day quick path\n',
          '1. Put the CSV in `Music/%s/` (as the exam instructions say) and note the exact path.' % ds['folder_music'],
          '2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.',
          '3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.',
          '4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.\n',
          '## Model at a glance\n', '* Fact: `%s` - %s' % (ds['fact'], ds['grain']),
          '* Dimensions: ' + ', '.join((['`dim_date`'] if ds.get('date') else []) + ['`%s`' % d['name'] for d in star]),
          '* Main measure: %s; analysis dimensions: %s, %s, %s' % (ds['olap']['m'][1], ds['olap']['a'][1], ds['olap']['b'][1], ds['olap']['c'][1])]
    return '\n'.join(L)


# ----------------------------------------------------------------------------- common docs
def common_docs(root):
    c = os.path.join(root, '00_Common')
    w(os.path.join(c, 'Problem_Statements.md'), """# DMBI Lab ESE - Problem statements covered by this kit

## Software that must be installed on the exam machine
1. Draw.io  2. MySQL  3. Power BI Desktop  4. Tableau Public  5. Open Office (Word, Excel etc.)

## Datasets (keep the dataset folder in the **Music** folder of the system)
1. Ecommerce_sales  2. Employee  3. Financials  4. Retail_sales dataset  5. Super Market Analysis  6. Sales Transaction Dataset
7. Retail Transactions Dataset  8. Customer Purchase History Dataset  9. HR Analytics Dataset  10. Inventory and Stock Dataset
11. Online Orders Dataset  12. Banking Customer Dataset

## Experiments
| Exp | Details | Covered here |
|-----|---------|--------------|
| 1 | Design and implement a Star and Snowflake Schema for efficient data storage and retrieval in BI applications | YES - Experiment_1 folders |
| 2 | Implement OLAP and OLTP operations using SQL queries and data warehouse concepts | YES - Experiment_2 folders |
| 3 | Design business dashboards for data-driven decision-making with suitable visualisation techniques | dashboard layout in Exp 4 (not a separate folder) |
| 4 | Extract, transform and visualise business data using Power BI / Tableau and derive insights | YES - Experiment_4 folders |
| 5 | Compare databases, knowledge maps, case-based repositories and wikis for codifying/retrieving knowledge | NOT covered |
""")
    w(os.path.join(c, 'Exam_Day_Runbook.md'), r"""# Exam-day runbook (read this first)

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
""")
    w(os.path.join(c, 'If_Your_Columns_Differ.md'), """# If your CSV columns differ from this kit

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
""")
    w(os.path.join(c, 'Viva_QnA.md'), """# Viva questions and short answers (Data Mining & Business Intelligence lab)

**Q1. What is a data warehouse?** A subject-oriented, integrated, time-variant, non-volatile store of historical data used for analysis and decisions.
**Q2. What is a star schema?** One central fact table joined directly to denormalised dimension tables - looks like a star.
**Q3. What is a snowflake schema?** A star schema whose dimensions are normalised into sub-dimensions (3NF) - looks like a snowflake.
**Q4. Star vs snowflake?** Star: fewer joins, faster queries, simpler, some redundancy. Snowflake: less redundancy/storage, easier maintenance, more joins and complexity.
**Q5. What is a fact table / dimension table?** Fact = measurable events (sales amount, quantity) + foreign keys. Dimension = descriptive context (who, what, where, when).
**Q6. What is the grain?** The level of detail of one fact row (e.g. one invoice line). Decide the grain first.
**Q7. What is a surrogate key and why?** A system-generated integer key for a dimension row; independent of source keys, small and fast for joins.
**Q8. What is a degenerate dimension?** An identifier (invoice/transaction number) stored in the fact with no dimension table.
**Q9. What is a conformed dimension?** A dimension shared by several fact tables with the same meaning (e.g. dim_date).
**Q10. Additive / semi-additive / non-additive measures?** Additive: sum across all dimensions (sales). Semi-additive: only across some (balance not across time). Non-additive: ratios, percentages.
**Q11. What is ETL?** Extract from sources, Transform (clean, convert, derive), Load into the warehouse.
**Q12. What is OLTP?** Online Transaction Processing: many short INSERT/UPDATE/DELETE transactions, normalised data, ACID.
**Q13. What is OLAP?** Online Analytical Processing: multidimensional analysis of historical data (roll-up, drill-down, slice, dice, pivot).
**Q14. OLTP vs OLAP?** OLTP = run the business, current data, row level, normalised. OLAP = analyse the business, historical, aggregated, star schema.
**Q15. Define roll-up and drill-down.** Roll-up: aggregate up a hierarchy (month -> quarter -> year). Drill-down: reverse, from summary to detail.
**Q16. Slice vs dice?** Slice: fix one dimension to one value. Dice: select a sub-cube by restricting two or more dimensions.
**Q17. What is pivot?** Rotate the data axes: turn row values into column headers.
**Q18. Types of OLAP?** ROLAP (relational), MOLAP (multidimensional cube), HOLAP (hybrid).
**Q19. What is ACID?** Atomicity, Consistency, Isolation, Durability.
**Q20. COMMIT / ROLLBACK / SAVEPOINT?** COMMIT makes changes permanent; ROLLBACK undoes the transaction; SAVEPOINT allows a partial rollback.
**Q21. Why an index?** Fast lookup without scanning the whole table (B-tree); essential for OLTP point queries.
**Q22. What is a data mart?** A small subject-specific warehouse (e.g. sales mart).
**Q23. What is a slowly changing dimension?** A dimension whose attributes change over time: Type 1 overwrite, Type 2 add a new row with validity dates, Type 3 add a column.
**Q24. What is a measure and a KPI?** Measure = numeric value (SUM of sales). KPI = measure compared with a target (profit margin, churn rate).
**Q25. What is DAX?** Data Analysis Expressions: the formula language of Power BI for measures and calculated columns.
**Q26. Calculated column vs measure?** Column: computed per row at load time and stored. Measure: computed at query time from the filter context.
**Q27. What is Power Query?** The ETL tool inside Power BI (M language) to connect, clean and shape data.
**Q28. Power BI vs Tableau?** Power BI: DAX, Microsoft ecosystem, modelling strength, cheap. Tableau: very strong visual exploration, drag-and-drop, Tableau Public for publishing.
**Q29. Which chart for what?** Trend = line; comparison = bar/column; share = donut/stacked bar (few categories); relation = scatter; geography = map; detail = table/matrix.
**Q30. What makes a good dashboard?** One purpose, KPI cards first, simple charts, consistent colours, filters/slicers, clear titles, few insights stated.
""")
    w(os.path.join(c, 'Dataset_Sources_and_Confidence.md'),
      '# Dataset sources and confidence\n\nA = column list confirmed online. B = partly confirmed / several files share the name. C = best guess.\n\n| # | Dataset folder | Confidence | Source used |\n|---|---|---|---|\n' +
      '\n'.join('| %d | `%s` | %s | %s |' % (i + 1, d['folder'], d['conf'], d['source'].replace('|', '/')) for i, d in enumerate(DATASETS)))
    t = os.path.join(c, 'tools')
    shutil.copy(os.path.join(HERE, 'spec.py'), os.path.join(t, 'spec.py')) if os.path.isdir(t) else (os.makedirs(t), shutil.copy(os.path.join(HERE, 'spec.py'), os.path.join(t, 'spec.py')))
    shutil.copy(os.path.abspath(__file__), os.path.join(t, 'build_kit.py'))
    w(os.path.join(t, 'README.md'), '# tools\nGenerator used to build this kit. `python build_kit.py out_folder` rebuilds everything from `spec.py` (Python 3, no packages).\n')


def master_readme(root):
    L = ['# DMBI Lab ESE Kit - Experiments 1, 2 and 4 for 12 datasets\n',
         'Works on Windows and Linux (plain `.sql`, `.md`, `.m`, `.dax`, `.drawio` files; UTF-8, forward-slash paths).\n',
         '## Start here\n', '1. `00_Common/Exam_Day_Runbook.md` - commands, order of work, common errors', '2. Open the folder of the dataset you get and read its `README.md`\n',
         '## Contents\n', '| Folder | Dataset | Column list confidence |', '|---|---|---|']
    for d in DATASETS:
        L.append('| `%s` | %s | %s |' % (d['folder'], d['title'], d['conf']))
    L += ['', 'Confidence A = verified online, B = several public files share the name (check header), C = unverified guess.\n',
          '## Inside every dataset folder\n', '```', 'README.md                        columns, notes, exam quick path',
          'Experiment_1_Star_Snowflake/     01_staging_load.sql, 02_star_schema.sql, 03_snowflake_schema.sql, 04_verify_and_compare.sql,',
          '                                 star_schema.drawio, snowflake_schema.drawio, schema_diagrams.md, README.md',
          'Experiment_2_OLAP_OLTP/          01_oltp_operations.sql, 02_olap_operations.sql, README.md',
          'Experiment_4_ETL_Visualization/  01_power_query_transform.m, 02_dax_measures.dax, 03_tableau_public_steps.md,',
          '                                 04_visualizations_and_insights.md, 05_mysql_flat_view.sql, README.md', '```\n',
          '## Requirements\n', '* MySQL 8.0+ (uses window functions, CTEs, GROUPING())', '* Power BI Desktop and/or Tableau Public; draw.io for the diagrams\n',
          '## Honest limits\n', '* The SQL was generated by a script and syntax-checked offline; it was not executed against a live MySQL server in the preparation environment.',
          '  Run it once on your machine tonight with a real CSV and fix the file path.',
          '* Datasets whose names are generic (Employee, Ecommerce_sales, Customer Purchase History, Inventory and Stock, ...) may differ from the file you get. Check the header row first.',
          '* Experiments 3 and 5 are not included (Exp 4 contains a dashboard layout).']
    w(os.path.join(root, 'README.md'), '\n'.join(L))


# ----------------------------------------------------------------------------- main
def build(out):
    root = os.path.join(out, KIT)
    if os.path.isdir(root):
        shutil.rmtree(root)
    for ds in DATASETS:
        ds['folder_music'] = ds['folder'][3:]
        base = os.path.join(root, ds['folder'])
        w(os.path.join(base, 'README.md'), dataset_readme(ds))
        e1 = os.path.join(base, E1)
        w(os.path.join(e1, '01_staging_load.sql'), staging_sql(ds))
        w(os.path.join(e1, '02_star_schema.sql'), star_sql(ds))
        w(os.path.join(e1, '03_snowflake_schema.sql'), snow_sql(ds))
        w(os.path.join(e1, '04_verify_and_compare.sql'), verify_sql(ds))
        a, b = drawio_files(ds)
        w(os.path.join(e1, 'star_schema.drawio'), a)
        w(os.path.join(e1, 'snowflake_schema.drawio'), b)
        w(os.path.join(e1, 'schema_diagrams.md'), diagrams_md(ds))
        w(os.path.join(e1, 'README.md'), exp1_readme(ds))
        e2 = os.path.join(base, E2)
        w(os.path.join(e2, '01_oltp_operations.sql'), oltp_sql(ds))
        w(os.path.join(e2, '02_olap_operations.sql'), olap_sql(ds))
        w(os.path.join(e2, 'README.md'), exp2_readme(ds))
        e4 = os.path.join(base, E4)
        w(os.path.join(e4, '01_power_query_transform.m'), m_script(ds))
        w(os.path.join(e4, '02_dax_measures.dax'), dax_file(ds))
        w(os.path.join(e4, '03_tableau_public_steps.md'), tableau_md(ds))
        w(os.path.join(e4, '04_visualizations_and_insights.md'), viz_md(ds))
        w(os.path.join(e4, '05_mysql_flat_view.sql'), view_sql(ds))
        w(os.path.join(e4, 'README.md'), exp4_readme(ds))
    common_docs(root)
    master_readme(root)
    return root


def make_zip(root, zip_path):
    if os.path.exists(zip_path):
        os.remove(zip_path)
    parent = os.path.dirname(root)
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as z:
        for dp, dn, fn in os.walk(root):
            dn.sort()
            for f in sorted(fn):
                full = os.path.join(dp, f)
                z.write(full, os.path.relpath(full, parent).replace(os.sep, '/'))


if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else 'out'
    r = build(out)
    n = sum(len(f) for _, _, f in os.walk(r))
    print('built', r, n, 'files')
    if len(sys.argv) > 2:
        make_zip(r, sys.argv[2])
        print('zip', sys.argv[2])
