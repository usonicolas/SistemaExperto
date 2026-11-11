"""Interfaces DAO (Data Access Object) de la capa de datos.

Cada interfaz declara las operaciones de acceso a datos de un agregado del
modelo y oculta el SGBD a la capa de negocio: los servicios y los motores
dependen de estas interfaces, no de MySQL. Las implementaciones estan en
datos/mysql/ y las crea FabricaDAOMySQL. En las pruebas, ConocimientoDAO
se implementa en memoria (tests/base_prueba.py).

La aplicacion solo lee la base de conocimiento: el conocimiento del
experto se carga y se actualiza con los scripts SQL del proyecto
(03_carga_conocimiento.sql), por eso ConocimientoDAO no tiene operaciones
de escritura.

    DAO              Tablas que gestiona
    ConocimientoDAO  categoria, pregunta, hipotesis, respuesta (solo lectura, consultas granulares)
    UsuarioDAO       usuario
    ClienteDAO       cliente
    ViviendaDAO      vivienda
    AtencionDAO      atencion, atencion_respuesta, atencion_diagnostico, atencion_hipotesis
"""
from abc import ABC, abstractmethod
from datetime import datetime

from ..negocio.modelos import (Antecedente, Atencion, Cliente, Diagnostico, Evidencia, Hipotesis,
                               HipotesisPonderada, Pregunta, Usuario, Vivienda)


class ConocimientoDAO(ABC):
    """Consultas granulares a la base de conocimiento que usan los motores de inferencia."""

    @abstractmethod
    def categorias(self) -> list[dict]:
        """Categorias activas, en el orden en que se presentan."""

    @abstractmethod
    def preguntas_de_categoria(self, categoria: str) -> list[Pregunta]:
        """Preguntas activas de una categoria."""

    @abstractmethod
    def hipotesis_activas(self, categoria: str) -> list[Hipotesis]:
        """Hipotesis candidatas de la categoria (consecuentes de los granulos activos)."""

    @abstractmethod
    def antecedentes_de_pregunta(self, pregunta: str) -> list[Antecedente]:
        """Granulo de una pregunta: que hipotesis activas la usan y que respuesta espera cada una."""

    @abstractmethod
    def antecedentes_de_hipotesis(self, hipotesis: str) -> list[Antecedente]:
        """Granulo completo de una hipotesis: sus respuestas If/And en orden."""

    @abstractmethod
    def hipotesis(self, codigo: str) -> Hipotesis | None:
        """Una hipotesis por su codigo."""

    @abstractmethod
    def leer_base(self) -> dict:
        """Base de conocimiento activa completa, para cargar el motor Prolog."""


class UsuarioDAO(ABC):
    @abstractmethod
    def por_usuario(self, usuario: str) -> Usuario | None: ...

    @abstractmethod
    def por_id(self, id_usuario: int) -> Usuario | None: ...

    @abstractmethod
    def existe(self, campo: str, valor: str) -> bool:
        """Comprueba los indices UNIQUE de la tabla: 'usuario' o 'correo'."""

    @abstractmethod
    def crear(self, usuario: Usuario) -> int: ...

    @abstractmethod
    def actualizar_contrasena(self, id_usuario: int, contrasena_hash: str) -> None: ...

    @abstractmethod
    def registrar_intento_fallido(self, id_usuario: int, intentos: int) -> None: ...

    @abstractmethod
    def bloquear(self, id_usuario: int, hasta: datetime) -> None: ...

    @abstractmethod
    def desbloquear(self, id_usuario: int) -> None: ...


class ClienteDAO(ABC):
    @abstractmethod
    def por_usuario(self, id_usuario: int) -> Cliente | None: ...

    @abstractmethod
    def existe_documento(self, tipo_documento: str, numero_documento: str, excepto_cliente: int | None = None) -> bool:
        """Comprueba el indice UNIQUE del documento, sin contar al propio cliente."""

    @abstractmethod
    def crear(self, cliente: Cliente) -> int: ...

    @abstractmethod
    def actualizar(self, cliente: Cliente) -> None: ...


class ViviendaDAO(ABC):
    @abstractmethod
    def de_cliente(self, id_cliente: int, incluir_inactivas: bool = False) -> list[Vivienda]:
        """Viviendas del cliente, con el numero de atenciones y la fecha de la ultima."""

    @abstractmethod
    def por_id(self, id_vivienda: int) -> Vivienda | None: ...

    @abstractmethod
    def crear(self, vivienda: Vivienda) -> int: ...

    @abstractmethod
    def actualizar(self, vivienda: Vivienda) -> None: ...

    @abstractmethod
    def cambiar_activa(self, id_vivienda: int, activa: bool) -> None: ...


class AtencionDAO(ABC):
    @abstractmethod
    def crear(self, id_vivienda: int, categoria: str, zona: str) -> int: ...

    @abstractmethod
    def por_id(self, id_atencion: int, id_cliente: int) -> Atencion | None:
        """La atencion, solo si pertenece a una vivienda del cliente."""

    @abstractmethod
    def evidencias(self, id_atencion: int) -> list[Evidencia]:
        """Memoria de trabajo: respuestas de la atencion en el orden en que se dieron."""

    @abstractmethod
    def registrar_respuesta(self, id_atencion: int, pregunta: str, valor: int) -> None: ...

    @abstractmethod
    def deshacer_respuesta(self, id_atencion: int) -> None: ...

    @abstractmethod
    def borrar_respuestas(self, id_atencion: int) -> None: ...

    @abstractmethod
    def cerrar(self, id_atencion: int, conclusion: Hipotesis | None, ranking: list[HipotesisPonderada]) -> None:
        """Guarda el diagnostico y las hipotesis ponderadas, y cierra la atencion."""

    @abstractmethod
    def reabrir(self, id_atencion: int) -> None: ...

    @abstractmethod
    def diagnostico(self, id_atencion: int) -> Diagnostico | None: ...

    @abstractmethod
    def ranking(self, id_atencion: int) -> list[dict]:
        """Hipotesis ponderadas guardadas al cerrar la atencion."""

    @abstractmethod
    def historial(self, id_cliente: int, categoria: str = "", zona: str = "", id_vivienda: int = 0,
                  limite: int = 200) -> list[dict]: ...

    @abstractmethod
    def recurrentes(self, id_cliente: int) -> list[dict]: ...

    @abstractmethod
    def indicadores(self, id_cliente: int) -> dict: ...

