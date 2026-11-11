"""Fabrica de DAO para MySQL: crea cada DAO con la conexion compartida."""
from ..conexion import BaseDatos, crear_base_datos
from .atencion_dao import AtencionDAOMySQL
from .cliente_dao import ClienteDAOMySQL
from .conocimiento_dao import ConocimientoDAOMySQL
from .usuario_dao import UsuarioDAOMySQL
from .vivienda_dao import ViviendaDAOMySQL


class FabricaDAOMySQL:
    """Unico punto que conoce las implementaciones MySQL de los DAO.

    Cambiar de SGBD implicaria escribir otra fabrica con las mismas
    operaciones; la capa de negocio no cambiaria.
    """

    def __init__(self, bd: BaseDatos | None = None):
        self.bd = bd or crear_base_datos()

    def transaccion(self):
        """Unidad de trabajo: agrupa operaciones de varios DAO en una transaccion."""
        return self.bd.transaccion()

    def conocimiento(self) -> ConocimientoDAOMySQL:
        return ConocimientoDAOMySQL(self.bd)

    def usuarios(self) -> UsuarioDAOMySQL:
        return UsuarioDAOMySQL(self.bd)

    def clientes(self) -> ClienteDAOMySQL:
        return ClienteDAOMySQL(self.bd)

    def viviendas(self) -> ViviendaDAOMySQL:
        return ViviendaDAOMySQL(self.bd)

    def atenciones(self) -> AtencionDAOMySQL:
        return AtencionDAOMySQL(self.bd)
