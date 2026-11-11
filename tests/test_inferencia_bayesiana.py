"""Pruebas del motor de inferencia bayesiano (objetivo 4: validacion).

- Unitarias con una base minima en memoria, sin MySQL: formula de Bayes,
  ganancia de informacion, parada y consultas granulares.
- Contra la base real (se omiten si MySQL no responde): las 49 reglas
  quedan primeras respondiendo segun su ruta, la conclusion por defecto
  en las 7 categorias y los casos del plan de validacion del manual.
"""
import math
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from se_app.contenedor import contenedor  # noqa: E402
from se_app.negocio.inferencia_bayesiana import MotorBayesiano  # noqa: E402
from se_app.negocio.modelos import H0, Evidencia  # noqa: E402
from tests.base_prueba import REGLAS, ConocimientoDAOMemoria  # noqa: E402

requiere_mysql = pytest.mark.skipif(not contenedor.bd.disponible(), reason="MySQL no disponible")


def recorrer(motor, categoria, contestar, limite=40):
    """Simula al usuario: responde lo que el motor pregunte hasta que concluya."""
    evidencias = []
    for _ in range(limite):
        decision = motor.decidir(categoria, evidencias)
        if decision.concluye:
            return decision, evidencias
        evidencias.append(Evidencia(decision.pregunta.codigo, contestar(decision.pregunta.codigo)))
    raise AssertionError("El motor no llegó a una conclusión")


@pytest.fixture
def motor():
    return MotorBayesiano(ConocimientoDAOMemoria())


# ---------------------------------------------------------------- unitarias

def test_previas_suman_uno_y_siguen_el_factor_de_certeza(motor):
    d = motor.distribucion_inicial("ELE")
    assert math.isclose(sum(d.probabilidades.values()), 1.0)
    assert math.isclose(d.probabilidad(H0), MotorBayesiano.PREVIA_H0)
    suma_fc = sum(fc for _, fc, _ in REGLAS.values())
    assert math.isclose(d.probabilidad("E05"), (1 - MotorBayesiano.PREVIA_H0) * 93 / suma_fc)


def test_actualizacion_aplica_el_teorema_de_bayes(motor):
    previa = motor.distribucion_inicial("ELE")
    posterior = motor.actualizar(previa, Evidencia("olor_quemado", 1))
    eps, sigma = MotorBayesiano.ERROR_RESPUESTA, MotorBayesiano.SINTOMA_AJENO
    # P(e|H): E05, E01, E08 esperan Si; E02 espera No; H0 no usa la pregunta.
    verosimilitud = {"E05": 1 - eps, "E01": 1 - eps, "E08": 1 - eps, "E02": eps, H0: sigma}
    total = sum(previa.probabilidad(h) * v for h, v in verosimilitud.items())
    for h, v in verosimilitud.items():
        assert math.isclose(posterior.probabilidad(h), previa.probabilidad(h) * v / total)


def test_cada_respuesta_hace_una_consulta_granular(motor):
    motor.inferir("ELE", [Evidencia("olor_quemado", 1), Evidencia("sobrecalentamiento", 1)])
    assert motor.conocimiento.consultas == 2


def test_pregunta_inicial_es_la_de_mayor_ganancia(motor):
    decision = motor.decidir("ELE", [])
    dist = motor.distribucion_inicial("ELE")
    ganancias = {p: motor.ganancia(dist, motor.conocimiento.antecedentes_de_pregunta(p))
                 for p in ("olor_quemado", "sobrecalentamiento", "breaker", "chispas")}
    assert decision.pregunta.codigo == max(ganancias, key=ganancias.get)
    assert decision.ganancia > 0


def test_concluye_la_regla_que_coincide(motor):
    decision, evidencias = recorrer(motor, "ELE", {"olor_quemado": 1, "sobrecalentamiento": 1}.get)
    assert decision.conclusion.codigo == "E05"
    assert decision.distribucion.probabilidad("E05") >= MotorBayesiano.UMBRAL_CONFIRMACION
    assert {e.pregunta for e in evidencias} >= {"olor_quemado", "sobrecalentamiento"}


def test_todo_no_lleva_a_la_conclusion_por_defecto(motor):
    decision, _ = recorrer(motor, "ELE", lambda p: 0)
    assert decision.conclusion.es_h0


def test_ranking_ordenado_y_normalizado(motor):
    d = motor.inferir("ELE", [Evidencia("olor_quemado", 1)])
    ranking = d.ranking()
    assert [hp.probabilidad for hp in ranking] == sorted((hp.probabilidad for hp in ranking), reverse=True)
    assert math.isclose(sum(hp.probabilidad for hp in ranking), 1.0)
    # E02 espera "No" en olor_quemado: la respuesta "Si" la contradice y su probabilidad cae mas de 10 veces.
    assert d.probabilidad("E02") < motor.distribucion_inicial("ELE").probabilidad("E02") / 10


# ---------------------------------------------------------------- base real

def _granulos(kb):
    conds = {}
    for c in kb["condiciones"]:
        conds.setdefault(c["hipotesis"], {})[c["pregunta"]] = c["valor_respuesta"]
    return [(h["codigo"], h["categoria"], conds.get(h["codigo"], {})) for h in kb["hipotesis"]]


@pytest.fixture(scope="module")
def base_real():
    return contenedor.dao_conocimiento.leer_base()


@requiere_mysql
def test_cada_regla_queda_primera_por_su_ruta(base_real):
    """Respondiendo segun los antecedentes de cada regla, el motor la concluye con al menos 90 %."""
    motor, fallas = contenedor.motor_bayesiano, []
    for codigo, categoria, condiciones in _granulos(base_real):
        decision, _ = recorrer(motor, categoria, lambda p: condiciones.get(p, 0))
        p = decision.distribucion.probabilidad(codigo)
        if decision.conclusion.codigo != codigo or p < MotorBayesiano.UMBRAL_CONFIRMACION:
            fallas.append(f"{codigo}: concluyó {decision.conclusion.codigo} ({p:.0%})")
    assert not fallas, fallas


@requiere_mysql
def test_conclusion_por_defecto_en_cada_categoria(base_real):
    """Sin sintomas (todo No) la hipotesis ganadora es H0: sin diagnostico concluyente (RNF22)."""
    for c in base_real["categorias"]:
        decision, _ = recorrer(contenedor.motor_bayesiano, c["codigo"], lambda p: 0)
        assert decision.conclusion.es_h0, c["codigo"]


# Los 12 casos de la tabla del plan de validacion del manual. Las preguntas que el motor formula y no
# estan en el caso se responden No: el motor las hace para descartar las demas hipotesis.
CASOS_PLAN_VALIDACION = [
    ("CP01", "ELE", {"olor_quemado": 1, "sobrecalentamiento": 1}, "E05"),
    ("CP02", "ELE", {"olor_quemado": 1, "breaker": 1, "sobrecalentamiento": 0}, "E01"),
    ("CP03", "ELE", {"chispas": 1, "olor_quemado": 0, "cables": 0}, "E09"),
    ("CP04", "HID", {"fuga_visible": 1, "humedad_lavamanos": 0}, "H08"),
    ("CP05", "HID", {"agua_color": 1, "fuga_visible": 0}, "H06"),
    ("CP06", "EST", {"hundimiento": 1, "inclinacion": 1}, "S03"),
    ("CP07", "EST", {"hundimiento": 1, "inclinacion": 0}, "S07"),
    ("CP08", "HUM", {"manchas": 1, "moho": 0}, "M05"),
    ("CP09", "GAS", {"olor_gas": 1, "silbido": 0}, "G04"),
    ("CP10", "GAS", {"silbido": 1, "olor_gas": 0, "consumo_gas": 0}, "G06"),
    ("CP11", "CTE", {"corrientes_aire": 1}, "C01"),
    ("CP12", "CAC", {"ruido_exterior": 0}, "H0"),
]


@requiere_mysql
@pytest.mark.parametrize("caso,categoria,respuestas,esperado", CASOS_PLAN_VALIDACION)
def test_casos_de_prueba_del_manual(base_real, caso, categoria, respuestas, esperado):
    decision, _ = recorrer(contenedor.motor_bayesiano, categoria, lambda p: respuestas.get(p, 0))
    assert decision.conclusion.codigo == esperado, caso
    if esperado != "H0":
        assert decision.distribucion.probabilidad(esperado) >= MotorBayesiano.UMBRAL_CONFIRMACION, caso


@requiere_mysql
def test_reporta_cinco_hipotesis_ponderadas():
    """El servicio guarda las 5 reglas mas probables mas H0, ordenadas y con probabilidades validas."""
    dist = contenedor.motor_bayesiano.inferir("ELE", [Evidencia("olor_quemado", 1)])
    ranking = contenedor.diagnostico.ranking(dist)
    reglas = [hp for hp in ranking if not hp.hipotesis.es_h0]
    assert len(reglas) == 5 and any(hp.hipotesis.es_h0 for hp in ranking)
    assert all(0 <= hp.probabilidad <= 1 for hp in ranking)
