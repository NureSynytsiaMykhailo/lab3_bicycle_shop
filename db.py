import os
import re
from contextlib import contextmanager

import pyodbc

CONN_STR = os.environ.get(
    "DB_CONN",
    "DRIVER={ODBC Driver 18 for SQL Server};SERVER=LENOVO;DATABASE=bicycle_shop;"
    "Trusted_Connection=yes;TrustServerCertificate=yes",
)


@contextmanager
def get_conn():
    conn = pyodbc.connect(CONN_STR, autocommit=True)
    try:
        yield conn
    finally:
        conn.close()


def query(sql, params=()):
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(sql, params)
        while cur.description is None:
            if not cur.nextset():
                return []
        cols = [c[0] for c in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]


def parse_db_error(e):
    text = str(e.args[1]) if len(e.args) > 1 else str(e)
    msg = text.split("[SQL Server]")[-1]
    msg = re.sub(r"\s*\(SQL\w+\)\s*$", "", msg)
    m = re.search(r"\s*\((\d+)\)\s*$", msg)
    code = int(m.group(1)) if m else None
    if m:
        msg = msg[: m.start()]
    return code, msg.strip()
