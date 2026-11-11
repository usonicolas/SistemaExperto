"""Control de acceso en la web (RNF01): dependencias de FastAPI sobre la sesion.

La aplicacion no tiene roles: toda ruta protegida exige una sesion iniciada,
y los servicios comprueban que cada vivienda o atencion pertenezca al
cliente de esa sesion (SinPermiso en caso contrario).
"""
from fastapi import Request


class NoAutenticado(Exception):
    pass


class SinPermiso(Exception):
    pass


def usuario_actual(request: Request) -> dict:
    u = request.session.get("usuario")
    if not u:
        raise NoAutenticado()
    return u
