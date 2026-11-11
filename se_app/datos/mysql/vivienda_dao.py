"""DAO de las viviendas de cada cliente (tabla vivienda)."""
from ...negocio.modelos import Vivienda
from ..conexion import BaseDatos
from ..dao import ViviendaDAO


class ViviendaDAOMySQL(ViviendaDAO):
    def __init__(self, bd: BaseDatos):
        self.bd = bd

    @staticmethod
    def _a_vivienda(f: dict) -> Vivienda:
        return Vivienda(f["id_cliente"], f["alias"], f["direccion"], f["ciudad"], f["tipo_vivienda"],
                        f["antiguedad_anios"], bool(f["activa"]), f["id_vivienda"], int(f.get("atenciones") or 0),
                        f.get("ultima"))

    def de_cliente(self, id_cliente: int, incluir_inactivas: bool = False) -> list[Vivienda]:
        filas = self.bd.consultar(
            "SELECT v.*, COUNT(a.id_atencion) AS atenciones, MAX(a.fecha_inicio) AS ultima "
            "FROM vivienda v LEFT JOIN atencion a ON a.id_vivienda = v.id_vivienda "
            "WHERE v.id_cliente = %s" + ("" if incluir_inactivas else " AND v.activa = 1") +
            " GROUP BY v.id_vivienda ORDER BY v.activa DESC, v.id_vivienda", (id_cliente,))
        return [self._a_vivienda(f) for f in filas]

    def por_id(self, id_vivienda: int) -> Vivienda | None:
        f = self.bd.consultar_uno("SELECT * FROM vivienda WHERE id_vivienda = %s", (id_vivienda,))
        return self._a_vivienda(f) if f else None

    def crear(self, vivienda: Vivienda) -> int:
        return self.bd.ejecutar(
            "INSERT INTO vivienda (id_cliente, alias, direccion, ciudad, tipo_vivienda, antiguedad_anios) "
            "VALUES (%s, %s, %s, %s, %s, %s)",
            (vivienda.id_cliente, vivienda.alias, vivienda.direccion, vivienda.ciudad, vivienda.tipo_vivienda,
             vivienda.antiguedad_anios))

    def actualizar(self, vivienda: Vivienda) -> None:
        self.bd.ejecutar(
            "UPDATE vivienda SET alias = %s, direccion = %s, ciudad = %s, tipo_vivienda = %s, antiguedad_anios = %s "
            "WHERE id_vivienda = %s",
            (vivienda.alias, vivienda.direccion, vivienda.ciudad, vivienda.tipo_vivienda, vivienda.antiguedad_anios,
             vivienda.id_vivienda))

    def cambiar_activa(self, id_vivienda: int, activa: bool) -> None:
        self.bd.ejecutar("UPDATE vivienda SET activa = %s WHERE id_vivienda = %s", (int(activa), id_vivienda))
