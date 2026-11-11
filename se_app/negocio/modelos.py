"""Entidades del dominio del sistema experto.

Son tambien los objetos de transferencia (DTO) que intercambian la capa de
negocio y los DAO de la capa de datos.
"""
import math
from dataclasses import dataclass, field
from datetime import datetime

# Codigo de la hipotesis H0: "no hay una falla identificable con las reglas".
H0 = "H0"
URGENCIAS = ("Critica", "Alta", "Media", "Baja")

TIPOS_DOCUMENTO = (("CC", "Cédula de ciudadanía"), ("CE", "Cédula de extranjería"),
                   ("TI", "Tarjeta de identidad"), ("PAS", "Pasaporte"))
TIPOS_VIVIENDA = ("Casa", "Apartamento", "Otro")


# ---------------------------------------------------------------- base de conocimiento

@dataclass(frozen=True)
class Pregunta:
    """Sintoma formulado como pregunta Si/No."""
    codigo: str
    categoria: str
    texto: str
    enunciado_si: str
    enunciado_no: str
    activa: bool = True

    def enunciado(self, valor: int) -> str:
        """Redaccion de la respuesta dada, para las explicaciones."""
        return self.enunciado_si if valor else self.enunciado_no


@dataclass(frozen=True)
class Hipotesis:
    """Consecuente (Then) de una regla, con sus metadatos."""
    codigo: str
    categoria: str
    diagnostico: str
    urgencia: str | None
    certeza: int                 # factor de certeza del experto, 0 a 100
    especialista: str | None = None
    accion: str | None = None
    validada: bool = True
    fuente: str | None = None
    id: int | None = None

    @property
    def es_h0(self) -> bool:
        return self.codigo == H0

    @staticmethod
    def sin_falla(categoria: str) -> "Hipotesis":
        return Hipotesis(H0, categoria, "Sin falla identificable con las reglas", None, 0)


@dataclass(frozen=True)
class Antecedente:
    """Fila de un granulo: la regla 'hipotesis' espera 'valor' en 'pregunta'."""
    hipotesis: str
    pregunta: str
    valor: int


@dataclass(frozen=True)
class Evidencia:
    """Respuesta del usuario: un hecho de la memoria de trabajo."""
    pregunta: str
    valor: int


@dataclass(frozen=True)
class HipotesisPonderada:
    hipotesis: Hipotesis
    previa: float                # P(H)
    probabilidad: float          # P(H | evidencias)

    @property
    def porcentaje(self) -> float:
        return round(self.probabilidad * 100, 1)


@dataclass
class Distribucion:
    """Distribucion de probabilidad sobre las hipotesis de una categoria."""
    probabilidades: dict[str, float]
    previas: dict[str, float]
    hipotesis: dict[str, Hipotesis]

    def normalizada(self, valores: dict[str, float]) -> "Distribucion":
        total = sum(valores.values()) or 1.0
        return Distribucion({h: v / total for h, v in valores.items()}, self.previas, self.hipotesis)

    def lider(self) -> Hipotesis:
        codigo = max(self.probabilidades, key=self.probabilidades.get)
        return self.hipotesis[codigo]

    def probabilidad(self, codigo: str) -> float:
        return self.probabilidades.get(codigo, 0.0)

    def entropia(self) -> float:
        """Incertidumbre en bits: 0 = una sola hipotesis posible."""
        return -sum(p * math.log2(p) for p in self.probabilidades.values() if p > 0)

    def ranking(self, n: int | None = None, incluir_h0: bool = True) -> list[HipotesisPonderada]:
        orden = sorted(self.probabilidades, key=lambda h: (-self.probabilidades[h], h))
        if not incluir_h0:
            orden = [h for h in orden if h != H0]
        return [HipotesisPonderada(self.hipotesis[h], self.previas[h], self.probabilidades[h]) for h in orden[:n]]


@dataclass
class Decision:
    """Resultado de un ciclo del motor: preguntar o concluir."""
    distribucion: Distribucion
    pregunta: Pregunta | None = None
    ganancia: float = 0.0                         # bits de informacion esperados de la pregunta
    antecedentes: list[Antecedente] = field(default_factory=list)   # granulo consultado de la pregunta

    @property
    def concluye(self) -> bool:
        return self.pregunta is None

    @property
    def conclusion(self) -> Hipotesis:
        return self.distribucion.lider()


# ---------------------------------------------------------------- base transaccional

@dataclass
class Usuario:
    """Persona que se registra para diagnosticar y llevar el historial de sus viviendas (tabla usuario).

    La aplicacion no tiene roles ni administrador: todos los usuarios son
    consultantes y cada uno solo ve sus propios datos.
    """
    nombres: str
    apellidos: str
    correo: str
    usuario: str
    contrasena_hash: str = ""
    id_usuario: int | None = None
    intentos_fallidos: int = 0
    bloqueado_hasta: datetime | None = None
    fecha_registro: datetime | None = None

    @property
    def nombre(self) -> str:
        return f"{self.nombres} {self.apellidos}"


@dataclass
class Cliente:
    """Datos del cliente asociado a cada usuario (tabla cliente)."""
    id_usuario: int
    tipo_documento: str
    numero_documento: str
    telefono: str | None = None
    id_cliente: int | None = None
    fecha_registro: datetime | None = None


@dataclass
class Vivienda:
    """Inmueble de un cliente (tabla vivienda)."""
    id_cliente: int
    alias: str
    direccion: str
    ciudad: str
    tipo_vivienda: str = "Casa"
    antiguedad_anios: int | None = None
    activa: bool = True
    id_vivienda: int | None = None
    atenciones: int = 0                  # calculado: atenciones registradas
    ultima: datetime | None = None       # calculado: fecha de la ultima atencion


@dataclass
class Atencion:
    """Sesion de diagnostico de una categoria sobre una vivienda (tabla atencion)."""
    id_atencion: int
    id_vivienda: int
    categoria: str                       # codigo de la categoria (puente a la base de conocimiento)
    categoria_nombre: str
    zona_vivienda: str | None
    estado: str
    fecha_inicio: datetime | None = None
    fecha_fin: datetime | None = None
    vivienda: str = ""                   # alias de la vivienda
    direccion: str = ""
    ciudad: str = ""

    @property
    def en_curso(self) -> bool:
        return self.estado == "EN_CURSO"


@dataclass
class Diagnostico:
    """Copia historica del diagnostico de una atencion (tabla atencion_diagnostico)."""
    id_atencion: int
    diagnostico_texto: str
    id_hipotesis: int | None = None
    codigo_hipotesis: str | None = None
    nivel_urgencia: str | None = None
    especialista_sugerido: str | None = None
    accion_recomendada: str | None = None
    factor_certeza: int | None = None
    fecha_generacion: datetime | None = None
    validada: bool | None = None
    fuente: str | None = None

    @property
    def concluyente(self) -> bool:
        return self.id_hipotesis is not None

