"""Conexion a MySQL con un pool de conexiones y transacciones anidables."""
from contextlib import contextmanager
from contextvars import ContextVar

import mysql.connector
from mysql.connector import pooling

from .. import config


class BaseDatos:
    """Punto unico de acceso a MySQL, compartido por todos los DAO.

    Las consultas usan nombres calificados (se_base_conocimiento.tabla /
    se_transaccional.tabla) porque la aplicacion trabaja con los dos
    esquemas a la vez. El pool se crea en la primera consulta, de modo que
    la aplicacion puede arrancar aunque MySQL aun no responda.

    transaccion() es anidable: si ya hay una abierta en el contexto actual,
    la reutiliza. Asi un servicio puede agrupar las operaciones de varios
    DAO en una sola unidad de trabajo (por ejemplo, el usuario y su cliente).
    """

    def __init__(self, host: str, puerto: int, usuario: str, contrasena: str, esquema: str, tamano_pool: int = 8,
                 zona_horaria: str = "-05:00"):
        self._parametros = dict(host=host, port=puerto, user=usuario, password=contrasena, database=esquema,
                                charset="utf8mb4", collation="utf8mb4_0900_ai_ci", autocommit=False,
                                connection_timeout=5, time_zone=zona_horaria)
        self._tamano_pool = tamano_pool
        self._pool = None
        self._actual: ContextVar = ContextVar(f"cnx_{id(self)}", default=None)

    def _obtener_pool(self):
        if self._pool is None:
            self._pool = pooling.MySQLConnectionPool(pool_name="se_pool", pool_size=self._tamano_pool,
                                                     **self._parametros)
        return self._pool

    @contextmanager
    def transaccion(self):
        """Entrega una conexion; confirma al salir o deshace si hubo error."""
        abierta = self._actual.get()
        if abierta is not None:          # transaccion anidada: la confirma la externa
            yield abierta
            return
        cnx = self._obtener_pool().get_connection()
        marca = self._actual.set(cnx)
        try:
            yield cnx
            cnx.commit()
        except Exception:
            cnx.rollback()
            raise
        finally:
            self._actual.reset(marca)
            cnx.close()

    def consultar(self, sql: str, params: tuple = ()) -> list[dict]:
        with self.transaccion() as cnx:
            cur = cnx.cursor(dictionary=True)
            cur.execute(sql, params)
            return cur.fetchall()

    def consultar_uno(self, sql: str, params: tuple = ()) -> dict | None:
        filas = self.consultar(sql, params)
        return filas[0] if filas else None

    def ejecutar(self, sql: str, params: tuple = ()) -> int:
        """Ejecuta una escritura y devuelve el ultimo id insertado."""
        with self.transaccion() as cnx:
            cur = cnx.cursor()
            cur.execute(sql, params)
            return cur.lastrowid

    def disponible(self) -> bool:
        try:
            self.consultar("SELECT 1 AS ok")
            return True
        except mysql.connector.Error:
            return False


def crear_base_datos() -> BaseDatos:
    return BaseDatos(config.MYSQL_HOST, config.MYSQL_PORT, config.MYSQL_USER, config.MYSQL_PASSWORD,
                     config.ESQUEMA_TRANSACCIONAL, zona_horaria=config.MYSQL_ZONA_HORARIA)
