"""RF01 · Gestion de clientes y viviendas (CU01), tablero e historial del consultante (CU05)."""
import re

from .errores import AccesoDenegado, ErrorValidacion
from .modelos import TIPOS_DOCUMENTO, TIPOS_VIVIENDA, Cliente, Vivienda


def validar_cliente(d: dict, clientes, excepto_cliente: int | None = None) -> dict:
    """Errores {campo: mensaje} de los datos del cliente; valida que el documento no este repetido."""
    errores = {}
    if d.get("tipo_documento") not in dict(TIPOS_DOCUMENTO):
        errores["tipo_documento"] = "Elija un tipo de documento."
    numero = d.get("numero_documento", "")
    if not numero:
        errores["numero_documento"] = "Escriba el número de documento."
    elif not re.fullmatch(r"[A-Za-z0-9]{4,20}", numero):
        errores["numero_documento"] = "Use entre 4 y 20 letras o números, sin puntos ni espacios."
    elif not errores and clientes.existe_documento(d["tipo_documento"], numero, excepto_cliente):
        errores["numero_documento"] = "Ya existe un cliente con ese documento."
    if d.get("telefono") and not re.fullmatch(r"[0-9 +()-]{7,20}", d["telefono"]):
        errores["telefono"] = "El teléfono no es válido."
    return errores


class ServicioClientes:
    def __init__(self, clientes, viviendas, atenciones):
        # ClienteDAO, ViviendaDAO y AtencionDAO (capa de datos).
        self.clientes = clientes
        self.viviendas_dao = viviendas
        self.atenciones = atenciones

    # ------------------------------------------------------------ cliente

    def cliente(self, id_usuario: int) -> Cliente | None:
        return self.clientes.por_usuario(id_usuario)

    def _cliente_o_error(self, id_usuario: int) -> Cliente:
        c = self.clientes.por_usuario(id_usuario)
        if c is None:
            raise ErrorValidacion("Primero registre sus datos de cliente.")
        return c

    def guardar_cliente(self, id_usuario: int, datos: dict) -> Cliente:
        """Registra o actualiza los datos del cliente del usuario consultante."""
        actual = self.clientes.por_usuario(id_usuario)
        errores = validar_cliente(datos, self.clientes, actual.id_cliente if actual else None)
        if errores:
            raise ErrorValidacion("Revise los datos del cliente.", errores)
        cliente = Cliente(id_usuario, datos["tipo_documento"], datos["numero_documento"],
                          datos.get("telefono") or None, actual.id_cliente if actual else None)
        if actual:
            self.clientes.actualizar(cliente)
        else:
            cliente.id_cliente = self.clientes.crear(cliente)
        return cliente

    # ------------------------------------------------------------ viviendas

    @staticmethod
    def validar_vivienda(d: dict) -> dict:
        errores = {}
        for campo, nombre in (("alias", "un nombre para la vivienda"), ("direccion", "la dirección"),
                              ("ciudad", "la ciudad")):
            if not d.get(campo, "").strip():
                errores[campo] = f"Escriba {nombre}."
        if d.get("tipo_vivienda") not in TIPOS_VIVIENDA:
            errores["tipo_vivienda"] = "Elija un tipo de vivienda."
        antiguedad = str(d.get("antiguedad_anios") or "").strip()
        if antiguedad and (not antiguedad.isdigit() or int(antiguedad) > 500):
            errores["antiguedad_anios"] = "Escriba la antigüedad en años (0 a 500)."
        return errores

    def viviendas(self, id_usuario: int, incluir_inactivas: bool = False) -> list[Vivienda]:
        c = self.clientes.por_usuario(id_usuario)
        return self.viviendas_dao.de_cliente(c.id_cliente, incluir_inactivas) if c else []

    def _vivienda_propia(self, id_usuario: int, id_vivienda: int) -> Vivienda:
        c = self._cliente_o_error(id_usuario)
        v = self.viviendas_dao.por_id(id_vivienda)
        if v is None or v.id_cliente != c.id_cliente:
            raise AccesoDenegado()
        return v

    def _desde_formulario(self, datos: dict, id_cliente: int, id_vivienda: int | None = None) -> Vivienda:
        antiguedad = str(datos.get("antiguedad_anios") or "").strip()
        return Vivienda(id_cliente, datos["alias"].strip(), datos["direccion"].strip(), datos["ciudad"].strip(),
                        datos["tipo_vivienda"], int(antiguedad) if antiguedad else None, id_vivienda=id_vivienda)

    def crear_vivienda(self, id_usuario: int, datos: dict) -> int:
        c = self._cliente_o_error(id_usuario)
        errores = self.validar_vivienda(datos)
        if errores:
            raise ErrorValidacion("Revise los datos de la vivienda.", errores)
        return self.viviendas_dao.crear(self._desde_formulario(datos, c.id_cliente))

    def actualizar_vivienda(self, id_usuario: int, id_vivienda: int, datos: dict) -> None:
        v = self._vivienda_propia(id_usuario, id_vivienda)
        errores = self.validar_vivienda(datos)
        if errores:
            raise ErrorValidacion("Revise los datos de la vivienda.", errores)
        self.viviendas_dao.actualizar(self._desde_formulario(datos, v.id_cliente, v.id_vivienda))

    def cambiar_estado_vivienda(self, id_usuario: int, id_vivienda: int, activa: bool) -> None:
        """Desactiva o reactiva una vivienda; nunca se borra, para conservar su historial."""
        self._vivienda_propia(id_usuario, id_vivienda)
        self.viviendas_dao.cambiar_activa(id_vivienda, activa)

    # ------------------------------------------------------------ tablero e historial (CU05)

    def tablero(self, id_usuario: int) -> dict:
        c = self.clientes.por_usuario(id_usuario)
        if c is None:
            return {"cliente": None, "viviendas": [], "indicadores": {}, "recientes": [], "recurrentes": []}
        return {"cliente": c,
                "viviendas": self.viviendas_dao.de_cliente(c.id_cliente),
                "indicadores": self.atenciones.indicadores(c.id_cliente),
                "recientes": self.atenciones.historial(c.id_cliente, limite=5),
                "recurrentes": self.atenciones.recurrentes(c.id_cliente)}

    def historial(self, id_usuario: int, categoria: str = "", zona: str = "", id_vivienda: int = 0) -> list[dict]:
        c = self.clientes.por_usuario(id_usuario)
        return self.atenciones.historial(c.id_cliente, categoria, zona, id_vivienda) if c else []

    def recurrentes(self, id_usuario: int) -> list[dict]:
        c = self.clientes.por_usuario(id_usuario)
        return self.atenciones.recurrentes(c.id_cliente) if c else []
