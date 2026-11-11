"""DAO de los clientes (tabla cliente): datos de cada usuario consultante."""
from ...negocio.modelos import Cliente
from ..conexion import BaseDatos
from ..dao import ClienteDAO


class ClienteDAOMySQL(ClienteDAO):
    def __init__(self, bd: BaseDatos):
        self.bd = bd

    def por_usuario(self, id_usuario: int) -> Cliente | None:
        f = self.bd.consultar_uno(
            "SELECT id_cliente, id_usuario, tipo_documento, numero_documento, telefono, fecha_registro "
            "FROM cliente WHERE id_usuario = %s", (id_usuario,))
        if not f:
            return None
        return Cliente(f["id_usuario"], f["tipo_documento"], f["numero_documento"], f["telefono"], f["id_cliente"],
                       f["fecha_registro"])

    def existe_documento(self, tipo_documento: str, numero_documento: str, excepto_cliente: int | None = None) -> bool:
        return bool(self.bd.consultar_uno(
            "SELECT 1 AS x FROM cliente WHERE tipo_documento = %s AND numero_documento = %s AND id_cliente <> %s",
            (tipo_documento, numero_documento, excepto_cliente or 0)))

    def crear(self, cliente: Cliente) -> int:
        return self.bd.ejecutar(
            "INSERT INTO cliente (id_usuario, tipo_documento, numero_documento, telefono) VALUES (%s, %s, %s, %s)",
            (cliente.id_usuario, cliente.tipo_documento, cliente.numero_documento, cliente.telefono or None))

    def actualizar(self, cliente: Cliente) -> None:
        self.bd.ejecutar(
            "UPDATE cliente SET tipo_documento = %s, numero_documento = %s, telefono = %s WHERE id_cliente = %s",
            (cliente.tipo_documento, cliente.numero_documento, cliente.telefono or None, cliente.id_cliente))
