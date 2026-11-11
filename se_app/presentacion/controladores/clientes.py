"""RF01 · Gestion de clientes y viviendas (CU01), tablero e historial (CU05)."""
from fastapi import Depends, Form, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from ...negocio.errores import AccesoDenegado, ErrorValidacion
from ..seguridad_web import SinPermiso, usuario_actual
from . import Controlador

CAMPOS_VIVIENDA = ("alias", "direccion", "ciudad", "tipo_vivienda", "antiguedad_anios")


class ControladorClientes(Controlador):
    def registrar_rutas(self):
        self.ruta("GET", "/", self.tablero, response_class=HTMLResponse)
        self.ruta("GET", "/viviendas", self.ver_viviendas, response_class=HTMLResponse)
        self.ruta("POST", "/cliente", self.guardar_cliente, response_class=HTMLResponse)
        self.ruta("POST", "/viviendas", self.crear_vivienda, response_class=HTMLResponse)
        self.ruta("POST", "/viviendas/{id_vivienda}", self.actualizar_vivienda, response_class=HTMLResponse)
        self.ruta("POST", "/viviendas/{id_vivienda}/estado", self.cambiar_estado)
        self.ruta("GET", "/historial", self.ver_historial, response_class=HTMLResponse)

    @property
    def servicio(self):
        return self.servicios.clientes

    def tablero(self, request: Request, u: dict = Depends(usuario_actual)):
        return self.vistas.pagina(request, "tablero.html", **self.servicio.tablero(u["id"]))

    # ------------------------------------------------------------ datos del cliente y viviendas (CU01)

    def _pagina(self, request: Request, u: dict, **extra):
        cliente = self.servicio.cliente(u["id"])
        actuales = ({"tipo_documento": cliente.tipo_documento, "numero_documento": cliente.numero_documento,
                     "telefono": cliente.telefono or ""} if cliente else {})
        ctx = {"cliente": cliente, "viviendas": self.servicio.viviendas(u["id"], incluir_inactivas=True),
               "errores_cliente": {}, "datos_cliente": actuales, "errores_vivienda": {}, "datos_vivienda": {},
               "editando": 0, "bienvenida": 0, "aviso": "", **extra}
        return self.vistas.pagina(request, "viviendas.html", **ctx)

    def ver_viviendas(self, request: Request, bienvenida: int = 0, aviso: str = "",
                      u: dict = Depends(usuario_actual)):
        return self._pagina(request, u, bienvenida=bienvenida, aviso=aviso)

    def guardar_cliente(self, request: Request, tipo_documento: str = Form(""), numero_documento: str = Form(""),
                        telefono: str = Form(""), u: dict = Depends(usuario_actual)):
        datos = {"tipo_documento": tipo_documento, "numero_documento": numero_documento.strip(),
                 "telefono": telefono.strip()}
        try:
            self.servicio.guardar_cliente(u["id"], datos)
        except ErrorValidacion as e:
            return self._pagina(request, u, errores_cliente=e.errores, datos_cliente=datos)
        return RedirectResponse("/viviendas?aviso=cliente", status_code=303)

    async def _datos_vivienda(self, request: Request) -> dict:
        form = await request.form()
        return {c: str(form.get(c, "")).strip() for c in CAMPOS_VIVIENDA}

    async def crear_vivienda(self, request: Request, u: dict = Depends(usuario_actual)):
        datos = await self._datos_vivienda(request)
        try:
            self.servicio.crear_vivienda(u["id"], datos)
        except ErrorValidacion as e:
            return self._pagina(request, u, errores_vivienda=e.errores or {"general": str(e)}, datos_vivienda=datos)
        siguiente = str((await request.form()).get("siguiente", "/viviendas?aviso=vivienda"))
        return RedirectResponse(siguiente if siguiente.startswith("/") else "/viviendas", status_code=303)

    async def actualizar_vivienda(self, request: Request, id_vivienda: int, u: dict = Depends(usuario_actual)):
        datos = await self._datos_vivienda(request)
        try:
            self.servicio.actualizar_vivienda(u["id"], id_vivienda, datos)
        except AccesoDenegado:
            raise SinPermiso()
        except ErrorValidacion as e:
            return self._pagina(request, u, errores_vivienda=e.errores, datos_vivienda=datos, editando=id_vivienda)
        return RedirectResponse("/viviendas?aviso=actualizada", status_code=303)

    def cambiar_estado(self, id_vivienda: int, activa: int = Form(...), u: dict = Depends(usuario_actual)):
        try:
            self.servicio.cambiar_estado_vivienda(u["id"], id_vivienda, bool(activa))
        except AccesoDenegado:
            raise SinPermiso()
        return RedirectResponse(f"/viviendas?aviso={'activada' if activa else 'desactivada'}", status_code=303)

    # ------------------------------------------------------------ historial (CU05)

    def ver_historial(self, request: Request, categoria: str = "", zona: str = "", vivienda: int = 0,
                      u: dict = Depends(usuario_actual)):
        filas = self.servicio.historial(u["id"], categoria, zona, vivienda)
        if self.vistas.es_htmx(request):
            return self.vistas.pagina(request, "_historial_tabla.html", filas=filas)
        return self.vistas.pagina(request, "historial.html", filas=filas, zonas=self.servicios.diagnostico.ZONAS,
                                  categoria=categoria, zona=zona, vivienda=vivienda,
                                  viviendas=self.servicio.viviendas(u["id"], incluir_inactivas=True),
                                  recurrentes=self.servicio.recurrentes(u["id"]))
