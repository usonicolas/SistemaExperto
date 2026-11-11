-- =====================================================================
--  SISTEMA EXPERTO DE DIAGNOSTICO DE VIVIENDA
--  SCRIPT 2 de 4  -  BASE TRANSACCIONAL (clientes, viviendas y atenciones)
--
--  Universidad Manuela Beltran - Ingenieria de Software
--  Sistemas Expertos - Ing. Jose Marcial Tellez Gomez
--  Lina Maria Brinez Rodriguez & Victor Alfonso Alarcon Ospina - 2026
--
--  Contiene la operacion diaria del sistema: quien consulta, sobre que
--  vivienda, que respondio y que hipotesis se le entregaron. Crece con
--  cada uso.
--
--  7 tablas, una por cada proceso transaccional del sistema:
--    usuario                - usuarios registrados y su acceso (RF01, RNF01)
--    cliente                - datos del cliente de cada usuario (RF01)
--    vivienda               - inmuebles de cada cliente (RF01)
--    atencion               - sesion de diagnostico de una categoria (RF02)
--    atencion_respuesta     - respuestas Si/No del usuario en la sesion (RF02)
--    atencion_diagnostico   - hipotesis concluida, copia historica (RF02)
--    atencion_hipotesis     - las hipotesis ponderadas de la atencion (RF02)
--
--  La aplicacion no tiene roles ni administrador: todos los usuarios son
--  consultantes y solo leen la base de conocimiento. El conocimiento lo
--  cargan y actualizan el ingeniero de conocimiento y el experto de
--  dominio con los scripts SQL (01 y 03), fuera de la aplicacion.
--
--  4 llaves foraneas PUENTE hacia se_base_conocimiento:
--    atencion.id_categoria             -> categoria
--    atencion_respuesta.id_pregunta    -> pregunta
--    atencion_diagnostico.id_hipotesis -> hipotesis
--    atencion_hipotesis.id_hipotesis   -> hipotesis
--
--  ORDEN DE EJECUCION: despues de 01_base_conocimiento.sql, porque las
--  llaves foraneas puente apuntan a ese esquema.
-- =====================================================================

DROP SCHEMA IF EXISTS se_transaccional;
CREATE SCHEMA se_transaccional
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE se_transaccional;


-- ---------------------------------------------------------------------
-- Tabla: usuario
-- Personas que se registran para diagnosticar sus viviendas y llevar su
-- historial. No hay roles: cada usuario solo ve sus propios datos.
-- Soporta el acceso seguro (RNF01): contrasena cifrada (RNF02) y
-- bloqueo por intentos fallidos.
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
  id_usuario        INT          NOT NULL AUTO_INCREMENT,
  nombres           VARCHAR(80)  NOT NULL,
  apellidos         VARCHAR(80)  NOT NULL,
  correo            VARCHAR(120) NOT NULL,
  usuario           VARCHAR(40)  NOT NULL,
  contrasena_hash   VARCHAR(255) NOT NULL COMMENT 'Resumen con sal, nunca texto plano (RNF02)',
  intentos_fallidos SMALLINT     NOT NULL DEFAULT 0 COMMENT 'Bloqueo por intentos (RNF01)',
  bloqueado_hasta   DATETIME     NULL,
  fecha_registro    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario),
  UNIQUE INDEX uq_usuario_correo (correo ASC),
  UNIQUE INDEX uq_usuario_usuario (usuario ASC)
) ENGINE = InnoDB
  COMMENT = 'Usuarios registrados del sistema experto';


-- ---------------------------------------------------------------------
-- Tabla: cliente
-- Datos del cliente (propietario, arrendatario o habitante) asociado a
-- cada usuario, en relacion uno a uno; se registran juntos. Un cliente gestiona
-- una o varias viviendas (RF01). El documento no puede repetirse.
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
  id_cliente       INT          NOT NULL AUTO_INCREMENT,
  id_usuario       INT          NOT NULL COMMENT 'Usuario asociado (uno a uno)',
  tipo_documento   ENUM('CC','CE','TI','PAS') NOT NULL DEFAULT 'CC',
  numero_documento VARCHAR(20)  NOT NULL,
  telefono         VARCHAR(20)  NULL,
  fecha_registro   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_cliente),
  UNIQUE INDEX uq_cliente_usuario (id_usuario ASC),
  UNIQUE INDEX uq_cliente_documento (tipo_documento ASC, numero_documento ASC),
  CONSTRAINT fk_cliente_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Clientes: datos de cada usuario';


-- ---------------------------------------------------------------------
-- Tabla: vivienda
-- Inmuebles de cada cliente. Es tabla aparte porque el historial y los
-- sintomas recurrentes se consultan POR VIVIENDA (RF02) y un mismo
-- cliente puede tener varias. Una vivienda se desactiva, nunca se borra,
-- para conservar su historial.
-- ---------------------------------------------------------------------
CREATE TABLE vivienda (
  id_vivienda      INT          NOT NULL AUTO_INCREMENT,
  id_cliente       INT          NOT NULL COMMENT 'Cliente que gestiona la vivienda',
  alias            VARCHAR(60)  NOT NULL COMMENT 'Casa principal, Apto arriendo...',
  direccion        VARCHAR(160) NOT NULL,
  ciudad           VARCHAR(60)  NOT NULL,
  tipo_vivienda    ENUM('Casa','Apartamento','Otro') NOT NULL DEFAULT 'Casa',
  antiguedad_anios SMALLINT     NULL,
  activa           TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (id_vivienda),
  INDEX idx_vivienda_cliente (id_cliente ASC),
  CONSTRAINT fk_vivienda_cliente
    FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_vivienda_antiguedad
    CHECK (antiguedad_anios IS NULL OR antiguedad_anios BETWEEN 0 AND 500)
) ENGINE = InnoDB
  COMMENT = 'Viviendas de cada cliente';


-- ---------------------------------------------------------------------
-- Tabla: atencion
-- Una sesion de diagnostico sobre UNA categoria. Si el usuario evalua
-- varias categorias, se crea una atencion por cada una. El cliente se
-- obtiene a traves de la vivienda, para no duplicar el dato.
--
-- PUENTE a la base de conocimiento:
--   id_categoria -> se_base_conocimiento.categoria
-- ---------------------------------------------------------------------
CREATE TABLE atencion (
  id_atencion   INT         NOT NULL AUTO_INCREMENT,
  id_vivienda   INT         NOT NULL,
  id_categoria  INT         NOT NULL COMMENT 'PUENTE -> se_base_conocimiento.categoria',
  zona_vivienda VARCHAR(60) NULL COMMENT 'Cocina, bano, fachada...',
  fecha_inicio  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_fin     DATETIME    NULL,
  estado        ENUM('EN_CURSO','DIAGNOSTICADA','SIN_DIAGNOSTICO','ABANDONADA')
                NOT NULL DEFAULT 'EN_CURSO',
  PRIMARY KEY (id_atencion),
  INDEX idx_atencion_vivienda (id_vivienda ASC),
  INDEX idx_atencion_categoria (id_categoria ASC),
  CONSTRAINT fk_atencion_vivienda
    FOREIGN KEY (id_vivienda) REFERENCES vivienda (id_vivienda)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_atencion_categoria
    FOREIGN KEY (id_categoria) REFERENCES se_base_conocimiento.categoria (id_categoria)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Sesion de diagnostico de una categoria';


-- ---------------------------------------------------------------------
-- Tabla: atencion_respuesta
-- Respuestas Si/No que el usuario dio en la sesion, en el orden en que
-- el motor hizo las preguntas. Son los HECHOS de la consulta (memoria de
-- trabajo): el motor los compara con las respuestas de cada hipotesis.
--
-- PUENTE a la base de conocimiento:
--   id_pregunta -> se_base_conocimiento.pregunta
-- ---------------------------------------------------------------------
CREATE TABLE atencion_respuesta (
  id_atencion_respuesta INT        NOT NULL AUTO_INCREMENT,
  id_atencion           INT        NOT NULL,
  id_pregunta           INT        NOT NULL COMMENT 'PUENTE -> se_base_conocimiento.pregunta',
  respuesta             TINYINT(1) NOT NULL COMMENT '1 = Si, 0 = No',
  orden                 SMALLINT   NOT NULL COMMENT 'Orden en que se formulo la pregunta',
  fecha_respuesta       DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_atencion_respuesta),
  UNIQUE INDEX uq_atencion_pregunta (id_atencion ASC, id_pregunta ASC),
  INDEX idx_atencion_respuesta_pregunta (id_pregunta ASC),
  CONSTRAINT fk_atencion_respuesta_atencion
    FOREIGN KEY (id_atencion) REFERENCES atencion (id_atencion)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_atencion_respuesta_pregunta
    FOREIGN KEY (id_pregunta) REFERENCES se_base_conocimiento.pregunta (id_pregunta)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_atencion_respuesta_valor
    CHECK (respuesta IN (0, 1))
) ENGINE = InnoDB
  COMMENT = 'Respuestas Si/No del usuario en una atencion';


-- ---------------------------------------------------------------------
-- Tabla: atencion_diagnostico
-- Hipotesis mas probable al cerrar la atencion. Guarda COPIA del texto
-- ademas del id_hipotesis: si la hipotesis se edita o se desactiva
-- despues con los scripts de la base de conocimiento, el historial ya
-- entregado no cambia.
-- id_hipotesis queda NULL cuando no hubo diagnostico concluyente
-- (RNF22). Como cada atencion cubre una sola categoria, tiene a lo sumo
-- un diagnostico.
--
-- PUENTE a la base de conocimiento:
--   id_hipotesis -> se_base_conocimiento.hipotesis
-- ---------------------------------------------------------------------
CREATE TABLE atencion_diagnostico (
  id_diagnostico        INT          NOT NULL AUTO_INCREMENT,
  id_atencion           INT          NOT NULL,
  id_hipotesis          INT          NULL COMMENT 'PUENTE -> se_base_conocimiento.hipotesis. NULL = sin diagnostico',
  diagnostico_texto     VARCHAR(255) NOT NULL COMMENT 'Copia historica del consecuente',
  nivel_urgencia        ENUM('Critica','Alta','Media','Baja') NULL,
  especialista_sugerido VARCHAR(120) NULL,
  accion_recomendada    VARCHAR(500) NULL,
  factor_certeza        SMALLINT     NULL,
  fecha_generacion      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_diagnostico),
  UNIQUE INDEX uq_diagnostico_atencion (id_atencion ASC),
  INDEX idx_diagnostico_hipotesis (id_hipotesis ASC),
  CONSTRAINT fk_diagnostico_atencion
    FOREIGN KEY (id_atencion) REFERENCES atencion (id_atencion)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_diagnostico_hipotesis
    FOREIGN KEY (id_hipotesis) REFERENCES se_base_conocimiento.hipotesis (id_hipotesis)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Diagnostico emitido (copia historica de la hipotesis)';


-- ---------------------------------------------------------------------
-- Tabla: atencion_hipotesis
-- Hipotesis ponderadas de una atencion: las 5 mas probables y la
-- hipotesis H0 ("sin falla identificable"), con su probabilidad previa
-- y final. Guarda COPIA del codigo y del texto, igual que
-- atencion_diagnostico, para que el historial no cambie si despues se
-- edita la hipotesis.
--
--   probabilidad_previa  P(H)              antes de la primera respuesta
--   probabilidad         P(H | respuestas) al cerrar la atencion
--   posicion             1 = la mas probable
--   id_hipotesis         NULL para H0
--
-- PUENTE a la base de conocimiento:
--   id_hipotesis -> se_base_conocimiento.hipotesis
-- ---------------------------------------------------------------------
CREATE TABLE atencion_hipotesis (
  id_atencion_hipotesis INT           NOT NULL AUTO_INCREMENT,
  id_atencion           INT           NOT NULL,
  id_hipotesis          INT           NULL COMMENT 'PUENTE -> se_base_conocimiento.hipotesis. NULL = H0',
  codigo_hipotesis      VARCHAR(10)   NOT NULL COMMENT 'Codigo de la hipotesis, o H0',
  diagnostico_texto     VARCHAR(255)  NOT NULL COMMENT 'Copia historica del consecuente',
  posicion              SMALLINT      NOT NULL COMMENT '1 = la mas probable',
  probabilidad_previa   DECIMAL(7,6)  NOT NULL COMMENT 'P(H) antes de las respuestas',
  probabilidad          DECIMAL(7,6)  NOT NULL COMMENT 'P(H | respuestas) al cerrar',
  PRIMARY KEY (id_atencion_hipotesis),
  UNIQUE INDEX uq_atencion_hipotesis_posicion (id_atencion ASC, posicion ASC),
  INDEX idx_atencion_hipotesis_hipotesis (id_hipotesis ASC),
  CONSTRAINT fk_atencion_hipotesis_atencion
    FOREIGN KEY (id_atencion) REFERENCES atencion (id_atencion)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_atencion_hipotesis_hipotesis
    FOREIGN KEY (id_hipotesis) REFERENCES se_base_conocimiento.hipotesis (id_hipotesis)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT ck_atencion_hipotesis_probabilidad
    CHECK (probabilidad BETWEEN 0 AND 1 AND probabilidad_previa BETWEEN 0 AND 1)
) ENGINE = InnoDB
  COMMENT = 'Hipotesis ponderadas por probabilidad al cerrar la atencion';

