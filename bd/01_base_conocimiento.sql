-- =====================================================================
--  SISTEMA EXPERTO DE DIAGNOSTICO DE VIVIENDA
--  SCRIPT 1 de 4  -  BASE DE CONOCIMIENTO (estructura)
--
--  Universidad Manuela Beltran - Ingenieria de Software
--  Sistemas Expertos - Ing. Jose Marcial Tellez Gomez
--  Lina Maria Brinez Rodriguez & Victor Alfonso Alarcon Ospina - 2026
--
--  SGBD: MySQL 8.0.16 o superior (por los CHECK).
--
--  Contiene el saber experto del sistema: que se pregunta y que se
--  concluye. No cambia con el uso diario, solo cuando el ingeniero de
--  conocimiento registra lo que aporta el experto de dominio (RF03).
--
--  4 tablas (limite definido por el docente):
--    categoria  - las 7 categorias (raiz de cada arbol de decision)
--    pregunta   - los 36 sintomas formulados como preguntas Si/No
--    hipotesis  - las 49 soluciones posibles (consecuente Then)
--    respuesta  - las respuestas que conforman cada hipotesis
--                 (antecedentes If / And). Una hipotesis tiene una o
--                 varias respuestas.
--
--  Granulo de conocimiento = una hipotesis + todas sus respuestas.
--  Equivale a una regla:  If <respuesta 1> And <respuesta 2> ...
--                         Then <hipotesis>
--
--  ORDEN DE EJECUCION:
--    01_base_conocimiento.sql   (este)
--    02_transaccional.sql
--    03_carga_conocimiento.sql
--    04_consultas_granulos.sql
-- =====================================================================

-- El esquema transaccional tiene llaves foraneas hacia este esquema;
-- se desactiva la verificacion solo para poder re-ejecutar el script.
SET FOREIGN_KEY_CHECKS = 0;
DROP SCHEMA IF EXISTS se_base_conocimiento;
SET FOREIGN_KEY_CHECKS = 1;

CREATE SCHEMA se_base_conocimiento
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE se_base_conocimiento;


-- ---------------------------------------------------------------------
-- Tabla: categoria
-- Las 7 categorias de diagnostico. Es la raiz de cada arbol: el usuario
-- elige una y con ella arranca la cadena de preguntas.
-- ---------------------------------------------------------------------
CREATE TABLE categoria (
  id_categoria  INT          NOT NULL AUTO_INCREMENT,
  codigo        VARCHAR(10)  NOT NULL COMMENT 'ELE, HID, EST, HUM, GAS, CTE, CAC',
  nombre        VARCHAR(60)  NOT NULL,
  descripcion   VARCHAR(255) NULL,
  orden         SMALLINT     NOT NULL DEFAULT 0 COMMENT 'Orden de presentacion al usuario',
  activa        TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (id_categoria),
  UNIQUE INDEX uq_categoria_codigo (codigo ASC)
) ENGINE = InnoDB
  COMMENT = 'Categorias de diagnostico (raiz del arbol de decision)';


-- ---------------------------------------------------------------------
-- Tabla: pregunta
-- Catalogo de los 36 sintomas, cada uno formulado como pregunta Si/No.
-- Guarda tambien los dos enunciados con que se redacta la regla en
-- formato If / And / Then: el afirmativo (respuesta Si) y el negativo
-- (respuesta No).
-- El codigo coincide con el identificador del hecho en el manual tecnico
-- (tabla de hechos del dominio) y en el motor de inferencia.
-- ---------------------------------------------------------------------
CREATE TABLE pregunta (
  id_pregunta        INT          NOT NULL AUTO_INCREMENT,
  id_categoria       INT          NOT NULL,
  codigo             VARCHAR(40)  NOT NULL COMMENT 'olor_quemado, fuga_visible, silbido...',
  texto_pregunta     VARCHAR(255) NOT NULL COMMENT 'Texto que ve el usuario',
  enunciado_positivo VARCHAR(255) NOT NULL COMMENT 'Redaccion para respuesta Si',
  enunciado_negativo VARCHAR(255) NOT NULL COMMENT 'Redaccion para respuesta No',
  activa             TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (id_pregunta),
  UNIQUE INDEX uq_pregunta_codigo (codigo ASC),
  INDEX idx_pregunta_categoria (id_categoria ASC),
  CONSTRAINT fk_pregunta_categoria
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Sintomas formulados como preguntas Si/No';


-- ---------------------------------------------------------------------
-- Tabla: hipotesis
-- Las 49 soluciones que el sistema puede concluir. Cada fila es el
-- CONSECUENTE (Then) de una regla, con sus metadatos: urgencia,
-- especialista, accion recomendada y factor de certeza.
--
-- validada = 0 identifica las hipotesis complementarias, derivadas del
-- analisis de las entrevistas y pendientes de validar con el experto.
-- ---------------------------------------------------------------------
CREATE TABLE hipotesis (
  id_hipotesis       INT          NOT NULL AUTO_INCREMENT,
  id_categoria       INT          NOT NULL,
  codigo             VARCHAR(10)  NOT NULL COMMENT 'E01 ... E12, H01 ... C03',
  diagnostico        VARCHAR(255) NOT NULL COMMENT 'Consecuente (Then)',
  nivel_urgencia     ENUM('Critica','Alta','Media','Baja') NOT NULL,
  especialista       VARCHAR(120) NOT NULL,
  accion_recomendada VARCHAR(500) NOT NULL,
  factor_certeza     SMALLINT     NOT NULL COMMENT 'Confianza del experto, 0 a 100',
  fuente             VARCHAR(120) NOT NULL COMMENT 'Entrevista de la que proviene',
  validada           TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '0 = complementaria, pendiente de validar',
  activa             TINYINT(1)   NOT NULL DEFAULT 1,
  fecha_creacion     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_modificacion DATETIME     NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_hipotesis),
  UNIQUE INDEX uq_hipotesis_codigo (codigo ASC),
  INDEX idx_hipotesis_categoria (id_categoria ASC),
  CONSTRAINT fk_hipotesis_categoria
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_hipotesis_factor_certeza
    CHECK (factor_certeza BETWEEN 0 AND 100)
) ENGINE = InnoDB
  COMMENT = 'Hipotesis o soluciones del sistema experto (consecuente Then)';


-- ---------------------------------------------------------------------
-- Tabla: respuesta
-- Las respuestas que conforman cada hipotesis: los ANTECEDENTES If/And.
-- Una hipotesis tiene una o varias respuestas, y reproduce la ruta
-- completa del arbol desde la raiz de la categoria, incluidas las
-- respuestas No que descartan las demas causas.
--
--   valor_respuesta = 1 -> el usuario debe responder Si  ("hay...")
--   valor_respuesta = 0 -> el usuario debe responder No  ("no hay...")
--   orden = 1 -> es el If;  orden >= 2 -> son los And
--
-- Ejemplo: la hipotesis E04 tiene 8 respuestas; la C03, solo 1.
--
-- Es una ENTIDAD DEBIL: no tiene identificador propio. Se identifica por
-- la hipotesis y la pregunta que relaciona (llave primaria compuesta).
-- ---------------------------------------------------------------------
CREATE TABLE respuesta (
  id_hipotesis    INT        NOT NULL,
  id_pregunta     INT        NOT NULL,
  valor_respuesta TINYINT(1) NOT NULL COMMENT '1 = Si, 0 = No',
  orden           SMALLINT   NOT NULL COMMENT '1 = If, 2 o mas = And',
  PRIMARY KEY (id_hipotesis, id_pregunta),
  UNIQUE INDEX uq_respuesta_hipotesis_orden (id_hipotesis ASC, orden ASC),
  INDEX idx_respuesta_pregunta (id_pregunta ASC),
  CONSTRAINT fk_respuesta_hipotesis
    FOREIGN KEY (id_hipotesis) REFERENCES hipotesis (id_hipotesis)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_respuesta_pregunta
    FOREIGN KEY (id_pregunta) REFERENCES pregunta (id_pregunta)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_respuesta_valor
    CHECK (valor_respuesta IN (0, 1))
) ENGINE = InnoDB
  COMMENT = 'Respuestas que conforman cada hipotesis (antecedentes If/And)';
