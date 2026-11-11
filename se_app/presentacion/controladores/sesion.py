"""Ingreso, registro publico del usuario (CU01) y cierre de sesion (RNF01)."""
from fastapi import Form, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from ...negocio.errores import ErrorAcceso, ErrorValidacion
from . import Controlador

CAMPOS_USUARIO = ("nombres", "apellidos", "correo", "usuario", "contrasena", "confirmacion",
                  "tipo_documento", "numero_documento", "telefono")


async def datos_formulario_usuario(request: Request) -> dict:
    """Campos del formulario de usuario y cliente; las contrasenas no se recortan."""
    form = await request.form()
    datos = {c: str(form.get(c, "")).strip() for c in CAMPOS_USUARIO}
    datos["contrasena"], datos["confirmacion"] = form.get("contrasena", ""), form.get("confirmacion", "")
    return datos


class ControladorSesion(Controlador):
    def registrar_rutas(self):
        self.ruta("GET", "/login", self.ver_login, response_class=HTMLResponse)
        self.ruta("POST", "/login", self.iniciar_sesion, response_class=HTMLResponse)
        self.ruta("GET", "/registro", self.ver_registro, response_class=HTMLResponse)
        self.ruta("POST", "/registro", self.registrar, response_class=HTMLResponse)
        self.ruta("GET", "/salir", self.cerrar_sesion)

    def ver_login(self, request: Request):
        if request.session.get("usuario"):
            return RedirectResponse("/", status_code=303)
        return self.vistas.pagina(request, "login.html", error=None)

    def iniciar_sesion(self, request: Request, usuario: str = Form(...), contrasena: str = Form(...)):
        try:
            request.session["usuario"] = self.servicios.usuarios.autenticar(usuario.strip(), contrasena)
        except ErrorAcceso as e:
            return self.vistas.pagina(request, "login.html", error=str(e), usuario_ingresado=usuario)
        return RedirectResponse("/", status_code=303)

    def ver_registro(self, request: Request):
        if request.session.get("usuario"):
            return RedirectResponse("/", status_code=303)
        return self.vistas.pagina(request, "registro.html", datos={}, errores={})

    async def registrar(self, request: Request):
        """Registro publico: crea el usuario con su registro de cliente."""
        datos = await datos_formulario_usuario(request)
        try:
            request.session["usuario"] = self.servicios.usuarios.registrar(datos)
        except ErrorValidacion as e:
            return self.vistas.pagina(request, "registro.html", datos=datos, errores=e.errores)
        return RedirectResponse("/viviendas?bienvenida=1", status_code=303)

    def cerrar_sesion(self, request: Request):
        request.session.clear()
        return RedirectResponse("/login", status_code=303)
