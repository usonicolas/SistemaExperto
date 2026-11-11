"""RF01 y RF02: gestion de clientes y viviendas y gestion de atenciones de punta a punta (requieren MySQL)."""
import re

import pytest

from tests.utilidades import borrar_usuario, db, navegador, requiere_mysql

pytestmark = requiere_mysql

USUARIO = {"nombres": "Cliente", "apellidos": "Prueba", "correo": "cliente.prueba@ejemplo.test",
           "usuario": "cliente.prueba", "contrasena": "Cliente2026", "confirmacion": "Cliente2026",
           "tipo_documento": "CE", "numero_documento": "80000001", "telefono": "3100000000"}
VIVIENDA = {"alias": "Apartamento de prueba", "direccion": "Calle 1 # 2-3", "ciudad": "Medellín",
            "tipo_vivienda": "Apartamento", "antiguedad_anios": "10"}


@pytest.fixture
def consultante():
    borrar_usuario(USUARIO["usuario"])
    c = navegador()
    assert c.post("/registro", data=USUARIO, follow_redirects=False).status_code == 303
    yield c
    borrar_usuario(USUARIO["usuario"])


def viviendas_del_cliente() -> list[dict]:
    return db.consultar("SELECT v.* FROM vivienda v JOIN cliente c ON c.id_cliente = v.id_cliente "
                        "JOIN usuario u ON u.id_usuario = c.id_usuario WHERE u.usuario = %s", (USUARIO["usuario"],))


def test_registrar_y_actualizar_vivienda(consultante):
    assert consultante.post("/viviendas", data=VIVIENDA, follow_redirects=False).status_code == 303
    (v,) = viviendas_del_cliente()
    assert (v["alias"], v["ciudad"], v["antiguedad_anios"], v["activa"]) == ("Apartamento de prueba", "Medellín", 10, 1)
    r = consultante.post(f"/viviendas/{v['id_vivienda']}", data={**VIVIENDA, "ciudad": "Cali"}, follow_redirects=False)
    assert r.status_code == 303
    assert viviendas_del_cliente()[0]["ciudad"] == "Cali"


def test_vivienda_sin_datos_muestra_los_errores(consultante):
    r = consultante.post("/viviendas", data={**VIVIENDA, "alias": "", "antiguedad_anios": "mil"})
    assert "Escriba un nombre para la vivienda." in r.text
    assert "Escriba la antigüedad en años (0 a 500)." in r.text
    assert not viviendas_del_cliente()


def test_documento_repetido_no_se_acepta(consultante):
    r = consultante.post("/cliente", data={"tipo_documento": "CC", "numero_documento": "1000000003", "telefono": ""})
    assert "Ya existe un cliente con ese documento." in r.text


def test_desactivar_vivienda_conserva_historial_y_bloquea_diagnostico(consultante):
    consultante.post("/viviendas", data=VIVIENDA)
    (v,) = viviendas_del_cliente()
    consultante.post(f"/viviendas/{v['id_vivienda']}/estado", data={"activa": 0})
    assert viviendas_del_cliente()[0]["activa"] == 0           # se desactiva, no se borra
    r = consultante.post("/diagnostico", data={"id_vivienda": v["id_vivienda"], "zona": "Cocina", "categoria": "ELE"})
    assert "La vivienda está desactivada" in r.text


def test_no_se_gestionan_viviendas_ajenas(consultante):
    ajena = db.consultar_uno("SELECT v.id_vivienda, v.activa FROM vivienda v JOIN cliente c ON c.id_cliente = v.id_cliente "
                             "JOIN usuario u ON u.id_usuario = c.id_usuario WHERE u.usuario = 'consulta' LIMIT 1")
    r = consultante.post(f"/viviendas/{ajena['id_vivienda']}/estado", data={"activa": 0})
    assert "Acceso restringido" in r.text
    assert db.consultar_uno("SELECT activa FROM vivienda WHERE id_vivienda = %s", (ajena["id_vivienda"],))["activa"] == 1


def test_no_se_ven_atenciones_ajenas(consultante):
    ajena = db.consultar_uno("SELECT a.id_atencion FROM atencion a JOIN vivienda v ON v.id_vivienda = a.id_vivienda "
                             "JOIN cliente c ON c.id_cliente = v.id_cliente JOIN usuario u ON u.id_usuario = c.id_usuario "
                             "WHERE u.usuario = 'consulta' LIMIT 1")
    for ruta in (f"/diagnostico/{ajena['id_atencion']}", f"/diagnostico/{ajena['id_atencion']}/reporte"):
        r = consultante.get(ruta)
        assert "Acceso restringido" in r.text, ruta
    assert "Acceso restringido" in consultante.post(f"/diagnostico/{ajena['id_atencion']}/responder",
                                                    data={"pregunta": "olor_quemado", "valor": 1}).text


def test_atencion_completa_guarda_diagnostico_e_hipotesis_ponderadas(consultante):
    consultante.post("/viviendas", data=VIVIENDA)
    (v,) = viviendas_del_cliente()
    r = consultante.post("/diagnostico", data={"id_vivienda": v["id_vivienda"], "zona": "Cocina", "categoria": "ELE"},
                         follow_redirects=False)
    id_atencion = int(re.search(r"/diagnostico/(\d+)", r.headers["location"]).group(1))
    for pregunta in ("olor_quemado", "sobrecalentamiento"):
        consultante.post(f"/diagnostico/{id_atencion}/responder", data={"pregunta": pregunta, "valor": 1})
    reporte = consultante.get(f"/diagnostico/{id_atencion}/reporte")
    assert "Riesgo de incendio eléctrico" in reporte.text and "Riesgo crítico" in reporte.text
    atencion = db.consultar_uno("SELECT estado FROM atencion WHERE id_atencion = %s", (id_atencion,))
    ranking = db.consultar("SELECT codigo_hipotesis, probabilidad FROM atencion_hipotesis WHERE id_atencion = %s "
                           "ORDER BY posicion", (id_atencion,))
    assert atencion["estado"] == "DIAGNOSTICADA"
    assert ranking[0]["codigo_hipotesis"] == "E05" and float(ranking[0]["probabilidad"]) >= 0.9
    assert len(ranking) == 6 and any(f["codigo_hipotesis"] == "H0" for f in ranking)
    historial = consultante.get(f"/historial?vivienda={v['id_vivienda']}")
    assert "Riesgo de incendio eléctrico" in historial.text
