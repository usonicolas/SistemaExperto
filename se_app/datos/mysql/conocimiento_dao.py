"""DAO de la base de conocimiento en MySQL (esquema se_base_conocimiento), solo lectura.

El conocimiento se carga y se actualiza con los scripts SQL del proyecto;
la aplicacion nunca escribe en este esquema.
"""
from ...negocio.modelos import Antecedente, Hipotesis, Pregunta
from ..conexion import BaseDatos
from ..dao import ConocimientoDAO

BC = "se_base_conocimiento"


class ConocimientoDAOMySQL(ConocimientoDAO):
    def __init__(self, bd: BaseDatos):
        self.bd = bd

    # ------------------------------------------------------------ consultas granulares del motor

    def categorias(self) -> list[dict]:
        return self.bd.consultar(
            f"SELECT id_categoria, codigo, nombre, descripcion FROM {BC}.categoria WHERE activa = 1 ORDER BY orden")

    def preguntas_de_categoria(self, categoria: str) -> list[Pregunta]:
        filas = self.bd.consultar(
            f"SELECT p.codigo, c.codigo AS categoria, p.texto_pregunta, p.enunciado_positivo, p.enunciado_negativo "
            f"FROM {BC}.pregunta p JOIN {BC}.categoria c ON c.id_categoria = p.id_categoria "
            f"WHERE c.codigo = %s AND p.activa = 1 ORDER BY p.id_pregunta", (categoria,))
        return [Pregunta(f["codigo"], f["categoria"], f["texto_pregunta"], f["enunciado_positivo"],
                         f["enunciado_negativo"]) for f in filas]

    def hipotesis_activas(self, categoria: str) -> list[Hipotesis]:
        filas = self.bd.consultar(
            f"SELECT h.id_hipotesis, h.codigo, c.codigo AS categoria, h.diagnostico, h.nivel_urgencia, "
            f"       h.factor_certeza, h.especialista, h.accion_recomendada, h.validada, h.fuente "
            f"FROM {BC}.hipotesis h JOIN {BC}.categoria c ON c.id_categoria = h.id_categoria "
            f"WHERE c.codigo = %s AND h.activa = 1 ORDER BY h.codigo", (categoria,))
        return [self._a_hipotesis(f) for f in filas]

    def antecedentes_de_pregunta(self, pregunta: str) -> list[Antecedente]:
        """Consulta granular: que hipotesis activas usan la pregunta y que respuesta esperan.

        Es la consulta que el motor bayesiano repite tras cada respuesta y
        para cada pregunta candidata.
        """
        filas = self.bd.consultar(
            f"SELECT h.codigo AS hipotesis, p.codigo AS pregunta, r.valor_respuesta "
            f"FROM {BC}.respuesta r "
            f"JOIN {BC}.hipotesis h ON h.id_hipotesis = r.id_hipotesis "
            f"JOIN {BC}.pregunta  p ON p.id_pregunta  = r.id_pregunta "
            f"WHERE p.codigo = %s AND h.activa = 1 ORDER BY h.codigo", (pregunta,))
        return [Antecedente(f["hipotesis"], f["pregunta"], int(f["valor_respuesta"])) for f in filas]

    def antecedentes_de_hipotesis(self, hipotesis: str) -> list[Antecedente]:
        filas = self.bd.consultar(
            f"SELECT h.codigo AS hipotesis, p.codigo AS pregunta, r.valor_respuesta "
            f"FROM {BC}.respuesta r "
            f"JOIN {BC}.hipotesis h ON h.id_hipotesis = r.id_hipotesis "
            f"JOIN {BC}.pregunta  p ON p.id_pregunta  = r.id_pregunta "
            f"WHERE h.codigo = %s ORDER BY r.orden", (hipotesis,))
        return [Antecedente(f["hipotesis"], f["pregunta"], int(f["valor_respuesta"])) for f in filas]

    def hipotesis(self, codigo: str) -> Hipotesis | None:
        f = self.bd.consultar_uno(
            f"SELECT h.id_hipotesis, h.codigo, c.codigo AS categoria, h.diagnostico, h.nivel_urgencia, "
            f"       h.factor_certeza, h.especialista, h.accion_recomendada, h.validada, h.fuente "
            f"FROM {BC}.hipotesis h JOIN {BC}.categoria c ON c.id_categoria = h.id_categoria "
            f"WHERE h.codigo = %s", (codigo,))
        return self._a_hipotesis(f) if f else None

    @staticmethod
    def _a_hipotesis(f: dict) -> Hipotesis:
        return Hipotesis(f["codigo"], f["categoria"], f["diagnostico"], f["nivel_urgencia"], int(f["factor_certeza"]),
                         f["especialista"], f["accion_recomendada"], bool(f["validada"]), f["fuente"], f["id_hipotesis"])

    def leer_base(self) -> dict:
        preguntas = self.bd.consultar(
            f"SELECT p.codigo, c.codigo AS categoria, p.texto_pregunta, p.enunciado_positivo, p.enunciado_negativo "
            f"FROM {BC}.pregunta p JOIN {BC}.categoria c ON c.id_categoria = p.id_categoria WHERE p.activa = 1")
        hipotesis = self.bd.consultar(
            f"SELECT h.codigo, c.codigo AS categoria, h.diagnostico, h.nivel_urgencia, h.factor_certeza, "
            f"       h.especialista, h.accion_recomendada, h.validada "
            f"FROM {BC}.hipotesis h JOIN {BC}.categoria c ON c.id_categoria = h.id_categoria WHERE h.activa = 1")
        condiciones = self.bd.consultar(
            f"SELECT h.codigo AS hipotesis, p.codigo AS pregunta, r.valor_respuesta, r.orden "
            f"FROM {BC}.respuesta r JOIN {BC}.hipotesis h ON h.id_hipotesis = r.id_hipotesis "
            f"JOIN {BC}.pregunta p ON p.id_pregunta = r.id_pregunta WHERE h.activa = 1")
        return {"categorias": self.categorias(), "preguntas": preguntas, "hipotesis": hipotesis,
                "condiciones": condiciones}
