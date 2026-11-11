"""CU01 y RNF01: registro publico del usuario, ingreso seguro y ausencia de administracion (requieren MySQL)."""
import pytest

from se_app import config
from tests.utilidades import borrar_usuario, db, navegador, requiere_mysql

pytestmark = requiere_mysql

NUEVO = {"nombres": "Prueba", "apellidos": "Automática", "correo": "prueba.auto@ejemplo.test", "usuario": "prueba.auto",
         "contrasena": "Registro2026", "confirmacion": "Registro2026", "tipo_documento": "CC",
         "numero_documento": "70000001", "telefono": ""}


@pytest.fixture
def cliente():
    borrar_usuario(NUEVO["usuario"])
    yield navegador()
    borrar_usuario(NUEVO["usuario"])


def test_registro_valida_campos(cliente):
    r = cliente.post("/registro", data={**NUEVO, "correo": "malo", "usuario": "consulta", "confirmacion": "otra",
                                        "numero_documento": "1000000003"})
    assert r.status_code == 200
    assert "El correo no tiene un formato válido." in r.text
    assert "Ese nombre de usuario ya está en uso." in r.text
    assert "Las contraseñas no coinciden." in r.text
    assert "Ya existe un cliente con ese documento." in r.text
    assert not db.consultar_uno("SELECT 1 AS x FROM usuario WHERE correo = 'malo'")


def test_registro_crea_el_usuario_con_su_cliente(cliente):
    r = cliente.post("/registro", data=NUEVO, follow_redirects=False)
    assert r.status_code == 303 and r.headers["location"].startswith("/viviendas")
    fila = db.consultar_uno(
        "SELECT u.contrasena_hash, c.tipo_documento, c.numero_documento FROM usuario u "
        "JOIN cliente c ON c.id_usuario = u.id_usuario WHERE u.usuario = %s", (NUEVO["usuario"],))
    assert fila["contrasena_hash"].startswith("scrypt$")          # RNF02: nunca en texto plano
    assert (fila["tipo_documento"], fila["numero_documento"]) == ("CC", "70000001")
    assert cliente.get("/viviendas").status_code == 200


def test_bloqueo_tras_intentos_fallidos(cliente):
    assert cliente.post("/registro", data=NUEVO, follow_redirects=False).status_code == 303
    cliente.get("/salir")
    for _ in range(config.MAX_INTENTOS - 1):
        r = cliente.post("/login", data={"usuario": NUEVO["usuario"], "contrasena": "equivocada"})
        assert "Usuario o contraseña incorrectos." in r.text
    r = cliente.post("/login", data={"usuario": NUEVO["usuario"], "contrasena": "equivocada"})
    assert "Demasiados intentos fallidos" in r.text
    r = cliente.post("/login", data={"usuario": NUEVO["usuario"], "contrasena": NUEVO["contrasena"]})
    assert "Cuenta bloqueada" in r.text                          # ni con la contraseña correcta
    assert db.consultar_uno("SELECT bloqueado_hasta > NOW() AS b FROM usuario WHERE usuario = %s",
                            (NUEVO["usuario"],))["b"] == 1


def test_las_rutas_exigen_sesion(cliente):
    for ruta in ("/", "/viviendas", "/diagnostico/nuevo", "/historial"):
        r = cliente.get(ruta, follow_redirects=False)
        assert r.status_code == 303 and r.headers["location"] == "/login", ruta


def test_no_hay_pantallas_de_administracion(cliente):
    """La aplicacion no tiene administrador ni muestra el arbol de decision."""
    assert cliente.post("/registro", data=NUEVO, follow_redirects=False).status_code == 303
    for ruta in ("/conocimiento", "/conocimiento/prueba", "/arbol", "/usuarios", "/bitacora"):
        assert cliente.get(ruta).status_code == 404, ruta
    menu = cliente.get("/").text
    for texto in ("Base de conocimiento", "Árbol de decisión", "Usuarios y roles", "Bitácora"):
        assert texto not in menu
