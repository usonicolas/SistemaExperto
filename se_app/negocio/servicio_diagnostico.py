"""RF02 · Gestion de atenciones: diagnosticar una falla con el motor bayesiano (CU02 a CU04)."""
from .errores import AccesoDenegado, ErrorValidacion
from .inferencia_bayesiana import MotorBayesiano
from .modelos import H0, Atencion, Decision, Evidencia
from .motor_prolog import MotorProlog


class ServicioDiagnostico:
    ZONAS = ("Cocina", "Baño", "Habitación", "Sala", "Comedor", "Fachada", "Patio", "Techo", "Garaje", "Otra")
    HIPOTESIS_REPORTADAS = 5

    # Acciones inmediatas de seguridad para diagnosticos criticos (CU03), por categoria.
    ACCIONES_INMEDIATAS = {
        "GAS": ["Ventile: abra puertas y ventanas", "No encienda ni apague interruptores, ni use llamas",
                "Cierre la llave de paso del gas y salga de la vivienda",
                "Llame a la línea de emergencias de su empresa de gas"],
        "ELE": ["Baje el breaker de la zona o el principal", "No vuelva a conectar nada en esa zona",
                "Si ve humo o llama, salga y llame al 123"],
        "EST": ["Salga de la zona afectada y no vuelva a entrar", "Aleje a las personas de muros y columnas inclinados",
                "Llame al 123 si hay riesgo de colapso"],
    }
    ACCIONES_GENERICAS = ["Aléjese de la zona afectada", "Llame al 123 si hay riesgo para las personas"]

    def __init__(self, atenciones, clientes, viviendas, conocimiento, motor: MotorBayesiano, reglas: MotorProlog):
        # AtencionDAO, ClienteDAO, ViviendaDAO y ConocimientoDAO (capa de datos), y los dos motores.
        self.atenciones = atenciones
        self.clientes = clientes
        self.viviendas = viviendas
        self.conocimiento = conocimiento
        self.motor = motor
        self.reglas = reglas

    def _id_cliente(self, id_usuario: int) -> int:
        c = self.clientes.por_usuario(id_usuario)
        if c is None:
            raise AccesoDenegado()
        return c.id_cliente

    # ------------------------------------------------------------ atencion

    def iniciar(self, id_usuario: int, id_vivienda: int, categoria: str, zona: str) -> int:
        """Valida la informacion minima antes de iniciar la inferencia (proceso 1)."""
        faltan = [n for n, v in (("la vivienda", id_vivienda), ("la zona", zona), ("el tipo de problema", categoria))
                  if not v]
        if not faltan and not self.reglas.categoria(categoria):
            faltan = ["un tipo de problema válido"]
        if faltan:
            raise ErrorValidacion("Para continuar elija " + ", ".join(faltan) + ".")
        vivienda = self.viviendas.por_id(id_vivienda)
        if vivienda is None or vivienda.id_cliente != self._id_cliente(id_usuario):
            raise AccesoDenegado()
        if not vivienda.activa:
            raise ErrorValidacion("La vivienda está desactivada; actívela en «Mis datos y viviendas».")
        return self.atenciones.crear(id_vivienda, categoria, zona)

    def atencion(self, id_atencion: int, id_usuario: int) -> Atencion:
        a = self.atenciones.por_id(id_atencion, self._id_cliente(id_usuario))
        if not a:
            raise AccesoDenegado()
        return a

    # ------------------------------------------------------------ ciclo de inferencia

    def avanzar(self, atencion: Atencion) -> Decision:
        """Pide al motor la siguiente pregunta; si concluye, guarda el diagnostico y las hipotesis ponderadas."""
        evidencias = self.atenciones.evidencias(atencion.id_atencion)
        decision = self.motor.decidir(atencion.categoria, evidencias)
        if decision.concluye:
            self._cerrar(atencion, decision)
        return decision

    def responder(self, atencion: Atencion, pregunta: str, valor: int) -> None:
        """Solo acepta la respuesta a la pregunta que el motor formulo (evita dobles envios)."""
        if not atencion.en_curso:
            return
        esperada = self.motor.decidir(atencion.categoria, self.atenciones.evidencias(atencion.id_atencion))
        if esperada.pregunta and esperada.pregunta.codigo == pregunta:
            self.atenciones.registrar_respuesta(atencion.id_atencion, pregunta, 1 if valor else 0)

    def anterior(self, atencion: Atencion) -> None:
        self.atenciones.deshacer_respuesta(atencion.id_atencion)

    def reiniciar(self, atencion: Atencion) -> None:
        self.atenciones.borrar_respuestas(atencion.id_atencion)

    def corregir(self, atencion: Atencion) -> None:
        self.atenciones.reabrir(atencion.id_atencion)
        self.atenciones.deshacer_respuesta(atencion.id_atencion)

    def _cerrar(self, atencion: Atencion, decision: Decision) -> None:
        lider = decision.conclusion
        conclusion = None if lider.es_h0 else lider
        self.atenciones.cerrar(atencion.id_atencion, conclusion, self.ranking(decision.distribucion))

    def ranking(self, distribucion) -> list:
        """Las HIPOTESIS_REPORTADAS hipotesis mas probables, mas H0, ordenadas por probabilidad."""
        reglas = [hp for hp in distribucion.ranking() if not hp.hipotesis.es_h0][:self.HIPOTESIS_REPORTADAS]
        h0 = [hp for hp in distribucion.ranking() if hp.hipotesis.es_h0]
        return sorted(reglas + h0, key=lambda hp: -hp.probabilidad)

    # ------------------------------------------------------------ datos para las pantallas

    def contexto_pregunta(self, atencion: Atencion, decision: Decision) -> dict:
        """Pregunta actual y respuestas dadas; las probabilidades se muestran en el reporte."""
        evidencias = self.atenciones.evidencias(atencion.id_atencion)
        preguntas = {p.codigo: p for p in self.conocimiento.preguntas_de_categoria(atencion.categoria)}
        dist = decision.distribucion
        return {
            "atencion": atencion,
            "pregunta": decision.pregunta,
            "numero": len(evidencias) + 1,
            "total": len(preguntas),
            "dadas": [{"texto": preguntas[e.pregunta].texto if e.pregunta in preguntas else e.pregunta,
                       "valor": e.valor} for e in evidencias],
            "vivas": sum(1 for p in dist.probabilidades.values() if p >= self.motor.RELEVANCIA_MINIMA),
        }

    def _explicacion(self, categoria: str, evidencias: list[Evidencia], codigo: str) -> dict:
        """Ruta If/And de las respuestas, efecto de cada una sobre la conclusion y su trayectoria."""
        preguntas = {p.codigo: p for p in self.conocimiento.preguntas_de_categoria(categoria)}
        trayectoria = self.motor.traza(categoria, evidencias)
        aportes = self.motor.aportes(evidencias, trayectoria, codigo)
        for fila in aportes:
            p = preguntas.get(fila["pregunta"])
            fila["texto"] = p.enunciado(fila["valor"]) if p else fila["pregunta"]
        return {
            "ruta": [{"conector": "If" if i == 0 else "And", "valor": e.valor,
                      "texto": preguntas[e.pregunta].enunciado(e.valor) if e.pregunta in preguntas else e.pregunta}
                     for i, e in enumerate(evidencias)],
            "aportes": aportes,
            "trayectoria": [round(t.probabilidad(codigo) * 100, 1) for t in trayectoria],
        }

    def reporte(self, atencion: Atencion) -> dict | None:
        d = self.atenciones.diagnostico(atencion.id_atencion)
        if not d:
            return None
        evidencias = self.atenciones.evidencias(atencion.id_atencion)
        codigo = d.codigo_hipotesis or H0
        return {
            "d": d,
            "concluyente": d.concluyente,
            "ranking": self.atenciones.ranking(atencion.id_atencion),
            "confirmada_prolog": bool(d.codigo_hipotesis) and self.reglas.confirma(
                atencion.categoria, evidencias, d.codigo_hipotesis),
            "inmediatas": (self.ACCIONES_INMEDIATAS.get(atencion.categoria, self.ACCIONES_GENERICAS)
                           if d.nivel_urgencia == "Critica" else []),
            **self._explicacion(atencion.categoria, evidencias, codigo),
        }
