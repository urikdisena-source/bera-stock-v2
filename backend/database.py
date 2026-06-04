import pymysql
import pymysql.cursors
from config import Config

def get_connection():
    """Retorna una conexión a la base de datos."""
    return pymysql.connect(
        host=Config.DB_HOST,
        port=Config.DB_PORT,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        database=Config.DB_NAME,
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=False
    )

def query(sql, params=None, fetchone=False):
    """Ejecuta un SELECT y retorna resultados."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return cur.fetchone() if fetchone else cur.fetchall()
    finally:
        conn.close()

def execute(sql, params=None):
    """Ejecuta INSERT/UPDATE/DELETE. Retorna lastrowid."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            conn.commit()
            return cur.lastrowid
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()

def execute_many(sql, data):
    """Ejecuta múltiples filas de una vez."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.executemany(sql, data)
            conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()

def transaction(operations):
    """
    Ejecuta múltiples operaciones en una sola transacción.
    operations: lista de tuplas (sql, params)
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            for sql, params in operations:
                cur.execute(sql, params or ())
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()
