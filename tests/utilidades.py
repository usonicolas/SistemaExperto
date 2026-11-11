"""Utilidades comunes de las pruebas contra la base real (requieren MySQL)."""
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from fastapi.testclient import TestClient  # noqa: E402

from scripts.semilla import contrasena_de_prueba  # noqa: E402
from se_app.contenedor import contenedor  # noqa: E402
from se_app.main import app  # noqa: E402

db = contenedor.bd
requiere_mysql = pytest.mark.skipif(not db.disponible(), reason="MySQL no disponible")


def navegador() -> TestClient:
    return TestClient(app)


def ingresar(cliente: TestClient, usuario: str, clave: str | None = None) -> None:
    r = cliente.post("/login", data={"usuario": usuario, "contrasena": clave or contrasena_de_prueba()},
                     follow_redirects=False)
    assert r.status_code == 303, r.text[:300]


def borrar_usuario(usuario: str) -> None:
    """Elimina un usuario de prueba con su cliente, sus viviendas y sus atenciones."""
    db.ejecutar("DELETE a FROM atencion a JOIN vivienda v ON v.id_vivienda = a.id_vivienda "
                "JOIN cliente c ON c.id_cliente = v.id_cliente JOIN usuario u ON u.id_usuario = c.id_usuario "
                "WHERE u.usuario = %s", (usuario,))
    db.ejecutar("DELETE v FROM vivienda v JOIN cliente c ON c.id_cliente = v.id_cliente "
                "JOIN usuario u ON u.id_usuario = c.id_usuario WHERE u.usuario = %s", (usuario,))
    db.ejecutar("DELETE c FROM cliente c JOIN usuario u ON u.id_usuario = c.id_usuario WHERE u.usuario = %s",
                (usuario,))
    db.ejecutar("DELETE FROM usuario WHERE usuario = %s", (usuario,))
