"""DAO de las atenciones (se_transaccional): sesion, respuestas, diagnostico,
hipotesis ponderadas e historial.

Toda consulta de una atencion filtra por el cliente a traves de la
vivienda, para que cada cliente solo vea lo suyo (RF02).
"""
from ...negocio.modelos import Atencion, Diagnostico, Evidencia, Hipotesis, HipotesisPonderada
from ..conexion import BaseDatos
from ..dao import AtencionDAO

BC = "se_base_conocimiento"


class AtencionDAOMySQL(AtencionDAO):
    def __init__(self, bd: BaseDatos):
        self.bd = bd

    # ------------------------------------------------------------ atencion y memoria de trabajo (CU02)

    def crear(self, id_vivienda: int, categoria: str, zona: str) -> int:
        return self.bd.ejecutar(
            f"INSERT INTO atencion (id_vivienda, id_categoria, zona_vivienda) "
            f"SELECT %s, id_categoria, %s FROM {BC}.categoria WHERE codigo = %s", (id_vivienda, zona, categoria))

    def por_id(self, id_atencion: int, id_cliente: int) -> Atencion | None:
        f = self.bd.consultar_uno(
            f"SELECT a.*, c.codigo AS categoria, c.nombre AS categoria_nombre, v.alias AS vivienda, v.direccion, "
            f"       v.ciudad "
            f"FROM atencion a JOIN vivienda v ON v.id_vivienda = a.id_vivienda "
            f"JOIN {BC}.categoria c ON c.id_categoria = a.id_categoria "
            f"WHERE a.id_atencion = %s AND v.id_cliente = %s", (id_atencion, id_cliente))
        if not f:
            return None
        return Atencion(f["id_atencion"], f["id_vivienda"], f["categoria"], f["categoria_nombre"], f["zona_vivienda"],
                        f["estado"], f["fecha_inicio"], f["fecha_fin"], f["vivienda"], f["direccion"], f["ciudad"])

    def evidencias(self, id_atencion: int) -> list[Evidencia]:
        filas = self.bd.consultar(
            f"SELECT p.codigo, ar.respuesta FROM atencion_respuesta ar "
            f"JOIN {BC}.pregunta p ON p.id_pregunta = ar.id_pregunta WHERE ar.id_atencion = %s ORDER BY ar.orden",
            (id_atencion,))
        return [Evidencia(f["codigo"], int(f["respuesta"])) for f in filas]

    def registrar_respuesta(self, id_atencion: int, pregunta: str, valor: int) -> None:
        self.bd.ejecutar(
            f"INSERT INTO atencion_respuesta (id_atencion, id_pregunta, respuesta, orden) "
            f"SELECT %s, p.id_pregunta, %s, "
            f"       (SELECT COALESCE(MAX(orden), 0) + 1 FROM atencion_respuesta WHERE id_atencion = %s) "
            f"FROM {BC}.pregunta p WHERE p.codigo = %s", (id_atencion, valor, id_atencion, pregunta))

    def deshacer_respuesta(self, id_atencion: int) -> None:
        self.bd.ejecutar("DELETE FROM atencion_respuesta WHERE id_atencion = %s ORDER BY orden DESC LIMIT 1",
                         (id_atencion,))

    def borrar_respuestas(self, id_atencion: int) -> None:
        self.bd.ejecutar("DELETE FROM atencion_respuesta WHERE id_atencion = %s", (id_atencion,))

    def cerrar(self, id_atencion: int, conclusion: Hipotesis | None, ranking: list[HipotesisPonderada]) -> None:
        """Guarda el diagnostico y las hipotesis ponderadas como copia historica y cierra la atencion.

        conclusion = None registra la conclusion por defecto (RNF22).
        """
        with self.bd.transaccion() as cnx:
            cur = cnx.cursor()
            cur.execute("DELETE FROM atencion_diagnostico WHERE id_atencion = %s", (id_atencion,))
            cur.execute("DELETE FROM atencion_hipotesis WHERE id_atencion = %s", (id_atencion,))
            if conclusion:
                cur.execute(
                    "INSERT INTO atencion_diagnostico (id_atencion, id_hipotesis, diagnostico_texto, nivel_urgencia, "
                    "  especialista_sugerido, accion_recomendada, factor_certeza) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                    (id_atencion, conclusion.id, conclusion.diagnostico, conclusion.urgencia,
                     conclusion.especialista, conclusion.accion, conclusion.certeza))
                estado = "DIAGNOSTICADA"
            else:
                cur.execute("INSERT INTO atencion_diagnostico (id_atencion, id_hipotesis, diagnostico_texto) "
                            "VALUES (%s, NULL, 'Sin diagnóstico concluyente')", (id_atencion,))
                estado = "SIN_DIAGNOSTICO"
            for posicion, hp in enumerate(ranking, 1):
                cur.execute(
                    "INSERT INTO atencion_hipotesis (id_atencion, id_hipotesis, codigo_hipotesis, diagnostico_texto, "
                    "  posicion, probabilidad_previa, probabilidad) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                    (id_atencion, hp.hipotesis.id, hp.hipotesis.codigo, hp.hipotesis.diagnostico, posicion,
                     round(hp.previa, 6), round(hp.probabilidad, 6)))
            cur.execute("UPDATE atencion SET estado = %s, fecha_fin = NOW() WHERE id_atencion = %s",
                        (estado, id_atencion))

    def reabrir(self, id_atencion: int) -> None:
        """Permite corregir respuestas de una atencion ya cerrada."""
        with self.bd.transaccion() as cnx:
            cur = cnx.cursor()
            cur.execute("DELETE FROM atencion_diagnostico WHERE id_atencion = %s", (id_atencion,))
            cur.execute("DELETE FROM atencion_hipotesis WHERE id_atencion = %s", (id_atencion,))
            cur.execute("UPDATE atencion SET estado = 'EN_CURSO', fecha_fin = NULL WHERE id_atencion = %s",
                        (id_atencion,))

    def diagnostico(self, id_atencion: int) -> Diagnostico | None:
        f = self.bd.consultar_uno(
            f"SELECT d.*, h.codigo AS codigo_hipotesis, h.validada, h.fuente "
            f"FROM atencion_diagnostico d LEFT JOIN {BC}.hipotesis h ON h.id_hipotesis = d.id_hipotesis "
            f"WHERE d.id_atencion = %s", (id_atencion,))
        if not f:
            return None
        return Diagnostico(f["id_atencion"], f["diagnostico_texto"], f["id_hipotesis"], f["codigo_hipotesis"],
                           f["nivel_urgencia"], f["especialista_sugerido"], f["accion_recomendada"],
                           f["factor_certeza"], f["fecha_generacion"],
                           None if f["validada"] is None else bool(f["validada"]), f["fuente"])

    def ranking(self, id_atencion: int) -> list[dict]:
        return self.bd.consultar(
            f"SELECT ah.*, h.nivel_urgencia FROM atencion_hipotesis ah "
            f"LEFT JOIN {BC}.hipotesis h ON h.id_hipotesis = ah.id_hipotesis "
            f"WHERE ah.id_atencion = %s ORDER BY ah.posicion", (id_atencion,))

    # ------------------------------------------------------------ historial e indicadores (CU05)

    def historial(self, id_cliente: int, categoria: str = "", zona: str = "", id_vivienda: int = 0,
                  limite: int = 200) -> list[dict]:
        sql = (f"SELECT a.id_atencion, a.fecha_inicio, a.zona_vivienda, a.estado, c.codigo AS categoria, "
               f"       c.nombre AS categoria_nombre, v.id_vivienda, v.alias AS vivienda, d.diagnostico_texto, "
               f"       d.nivel_urgencia, d.factor_certeza, ah.probabilidad "
               f"FROM atencion a JOIN vivienda v ON v.id_vivienda = a.id_vivienda "
               f"JOIN {BC}.categoria c ON c.id_categoria = a.id_categoria "
               f"LEFT JOIN atencion_diagnostico d ON d.id_atencion = a.id_atencion "
               f"LEFT JOIN atencion_hipotesis ah ON ah.id_atencion = a.id_atencion AND ah.posicion = 1 "
               f"WHERE v.id_cliente = %s AND a.estado IN ('DIAGNOSTICADA', 'SIN_DIAGNOSTICO')")
        params: list = [id_cliente]
        if categoria:
            sql += " AND c.codigo = %s"
            params.append(categoria)
        if zona:
            sql += " AND a.zona_vivienda = %s"
            params.append(zona)
        if id_vivienda:
            sql += " AND v.id_vivienda = %s"
            params.append(id_vivienda)
        sql += " ORDER BY a.fecha_inicio DESC, a.id_atencion DESC LIMIT %s"
        params.append(limite)
        return self.bd.consultar(sql, tuple(params))

    def recurrentes(self, id_cliente: int) -> list[dict]:
        """Categorias que se repiten en una misma vivienda en los ultimos 90 dias."""
        return self.bd.consultar(
            f"SELECT v.alias AS vivienda, c.nombre AS categoria, COUNT(*) AS veces "
            f"FROM atencion a JOIN vivienda v ON v.id_vivienda = a.id_vivienda "
            f"JOIN {BC}.categoria c ON c.id_categoria = a.id_categoria "
            f"WHERE v.id_cliente = %s AND a.estado = 'DIAGNOSTICADA' AND a.fecha_inicio >= NOW() - INTERVAL 90 DAY "
            f"GROUP BY v.id_vivienda, c.id_categoria HAVING COUNT(*) >= 2", (id_cliente,))

    def indicadores(self, id_cliente: int) -> dict:
        return self.bd.consultar_uno(
            "SELECT "
            " (SELECT COUNT(*) FROM atencion a JOIN vivienda v ON v.id_vivienda = a.id_vivienda "
            "   WHERE v.id_cliente = %s AND a.estado <> 'EN_CURSO' AND a.fecha_inicio >= DATE_FORMAT(NOW(), '%%Y-%%m-01')) AS mes, "
            " (SELECT COUNT(*) FROM atencion_diagnostico d JOIN atencion a ON a.id_atencion = d.id_atencion "
            "   JOIN vivienda v ON v.id_vivienda = a.id_vivienda WHERE v.id_cliente = %s AND d.nivel_urgencia = 'Critica') AS criticas, "
            " (SELECT COUNT(*) FROM vivienda v WHERE v.id_cliente = %s AND v.activa = 1) AS viviendas, "
            " (SELECT AVG(TIMESTAMPDIFF(SECOND, a.fecha_inicio, a.fecha_fin)) FROM atencion a "
            "   JOIN vivienda v ON v.id_vivienda = a.id_vivienda WHERE v.id_cliente = %s AND a.fecha_fin IS NOT NULL) AS segundos",
            (id_cliente, id_cliente, id_cliente, id_cliente)) or {}
