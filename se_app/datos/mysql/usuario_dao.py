"""DAO de los usuarios del sistema (tabla usuario)."""
from datetime import datetime

from ...negocio.modelos import Usuario
from ..conexion import BaseDatos
from ..dao import UsuarioDAO

COLUMNAS = ("id_usuario, rol, nombres, apellidos, correo, usuario, contrasena_hash, intentos_fallidos, "
            "bloqueado_hasta, activo, fecha_registro")


class UsuarioDAOMySQL(UsuarioDAO):
    def __init__(self, bd: BaseDatos):
        self.bd = bd

    @staticmethod
    def _a_usuario(f: dict | None) -> Usuario | None:
        if not f:
            return None
        return Usuario(f["nombres"], f["apellidos"], f["correo"], f["usuario"], f["contrasena_hash"],
                       f["id_usuario"], f["intentos_fallidos"], f["bloqueado_hasta"], bool(f["activo"]),
                       f["fecha_registro"], f["rol"])

    def por_usuario(self, usuario: str) -> Usuario | None:
        return self._a_usuario(self.bd.consultar_uno(f"SELECT {COLUMNAS} FROM usuario WHERE usuario = %s", (usuario,)))

    def por_id(self, id_usuario: int) -> Usuario | None:
        return self._a_usuario(self.bd.consultar_uno(f"SELECT {COLUMNAS} FROM usuario WHERE id_usuario = %s",
                                                     (id_usuario,)))

    def existe(self, campo: str, valor: str) -> bool:
        columna = {"usuario": "usuario", "correo": "correo"}[campo]
        return bool(self.bd.consultar_uno(f"SELECT 1 AS x FROM usuario WHERE {columna} = %s", (valor,)))

    def crear(self, usuario: Usuario) -> int:
        return self.bd.ejecutar(
            "INSERT INTO usuario (rol, nombres, apellidos, correo, usuario, contrasena_hash) "
            "VALUES (%s, %s, %s, %s, %s, %s)",
            (usuario.rol, usuario.nombres, usuario.apellidos, usuario.correo.lower(), usuario.usuario,
             usuario.contrasena_hash))

    def actualizar_contrasena(self, id_usuario: int, contrasena_hash: str) -> None:
        self.bd.ejecutar("UPDATE usuario SET contrasena_hash = %s, intentos_fallidos = 0, bloqueado_hasta = NULL, "
                         "activo = 1 WHERE id_usuario = %s", (contrasena_hash, id_usuario))

    def registrar_intento_fallido(self, id_usuario: int, intentos: int) -> None:
        self.bd.ejecutar("UPDATE usuario SET intentos_fallidos = %s WHERE id_usuario = %s", (intentos, id_usuario))

    def bloquear(self, id_usuario: int, hasta: datetime) -> None:
        self.bd.ejecutar("UPDATE usuario SET intentos_fallidos = 0, bloqueado_hasta = %s WHERE id_usuario = %s",
                         (hasta, id_usuario))

    def desbloquear(self, id_usuario: int) -> None:
        self.bd.ejecutar("UPDATE usuario SET intentos_fallidos = 0, bloqueado_hasta = NULL WHERE id_usuario = %s",
                         (id_usuario,))
