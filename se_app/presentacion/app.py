"""Aplicacion web: crea FastAPI, registra los controladores y traduce los errores a pantallas."""
import logging
from logging.handlers import RotatingFileHandler

import mysql.connector
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from starlette.middleware.sessions import SessionMiddleware

from .. import config
from ..contenedor import contenedor
from .controladores.clientes import ControladorClientes
from .controladores.diagnostico import ControladorDiagnostico
from .controladores.sesion import ControladorSesion
from .seguridad_web import NoAutenticado, SinPermiso
from .vistas import CARPETA, Vistas

log = logging.getLogger("se_app")


def configurar_registro_errores() -> None:
    """RNF23: los errores no controlados quedan en logs/errores.log con fecha, usuario y traza."""
    if any(isinstance(h, RotatingFileHandler) for h in log.handlers):
        return
    config.ARCHIVO_ERRORES.parent.mkdir(exist_ok=True)
    archivo = RotatingFileHandler(config.ARCHIVO_ERRORES, maxBytes=1_000_000, backupCount=5, encoding="utf-8")
    archivo.setLevel(logging.ERROR)
    archivo.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
    log.addHandler(archivo)


def crear_app() -> FastAPI:
    configurar_registro_errores()
    app = FastAPI(title="Sistema experto de diagnóstico de vivienda")
    app.add_middleware(SessionMiddleware, secret_key=config.SECRET_KEY, max_age=60 * 60 * 8, same_site="lax")
    app.mount("/static", StaticFiles(directory=CARPETA / "static"), name="static")
    vistas = Vistas(contenedor.motor_prolog)

    for clase in (ControladorSesion, ControladorClientes, ControladorDiagnostico):
        app.include_router(clase(contenedor, vistas).router)

    def cargar_motor_reglas() -> None:
        try:
            log.info("Motor de reglas cargado con %s reglas", contenedor.motor_prolog.recargar())
        except mysql.connector.Error as e:
            log.error("No se pudo cargar la base de conocimiento: %s", e)

    app.add_event_handler("startup", cargar_motor_reglas)

    @app.middleware("http")
    async def motor_cargado(request: Request, call_next):
        # Si MySQL no estaba listo al arrancar, la base se carga en la primera peticion.
        if not contenedor.motor_prolog.cargado and not request.url.path.startswith("/static"):
            cargar_motor_reglas()
        return await call_next(request)

    def usuario_de(request: Request) -> str:
        u = request.session.get("usuario") if "session" in request.scope else None
        return u["usuario"] if u else "anónimo"

    @app.exception_handler(NoAutenticado)
    def _no_autenticado(request: Request, _):
        return vistas.redirigir(request, "/login")

    @app.exception_handler(SinPermiso)
    def _sin_permiso(request: Request, _):
        return vistas.pagina(request, "error.html", titulo="Acceso restringido",
                             mensaje="Esta información no existe o pertenece a otro usuario (RNF01).")

    @app.exception_handler(mysql.connector.Error)
    def _sin_base(request: Request, exc):
        log.error("Error de base de datos · usuario=%s · %s %s", usuario_de(request), request.method,
                  request.url.path, exc_info=exc)
        return vistas.pagina(request, "error.html", titulo="La base de datos no responde",
                             mensaje="Verifique que el contenedor de MySQL esté encendido y vuelva a intentarlo.")

    @app.exception_handler(Exception)
    def _error(request: Request, exc):
        log.error("Error no controlado · usuario=%s · %s %s", usuario_de(request), request.method,
                  request.url.path, exc_info=exc)
        return vistas.pagina(request, "error.html", titulo="Ocurrió un error",
                             mensaje="El error quedó registrado para su revisión. Intente de nuevo en unos minutos.")

    return app


app = crear_app()
