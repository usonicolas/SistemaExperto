-- =====================================================================
--  SISTEMA EXPERTO DE DIAGNOSTICO DE VIVIENDA
--  SCRIPT 4 de 4  -  CONSULTAS DE GRANULOS DE CONOCIMIENTO Y
--                     DEMOSTRACION DEL MOTOR DE INFERENCIA
--
--  Universidad Manuela Beltran - Ingenieria de Software
--  Sistemas Expertos - Ing. Jose Marcial Tellez Gomez
--  Lina Maria Brinez Rodriguez & Victor Alfonso Alarcon Ospina - 2026
--
--  Parte A: consultas sobre la base de conocimiento (granulos por
--           hipotesis). Solo leen; se pueden ejecutar las veces que sea.
--  Parte B: demostracion con datos de prueba en la base transaccional.
--           Inserta datos: ejecutarla UNA sola vez despues del script 3.
--
--  Ejecutar despues de 03_carga_conocimiento.sql.
-- =====================================================================

SET NAMES utf8mb4;
SET SESSION group_concat_max_len = 8192;
USE se_base_conocimiento;


-- =====================================================================
--  PARTE A. GRANULOS DE CONOCIMIENTO POR HIPOTESIS
-- =====================================================================

-- ---------------------------------------------------------------------
-- A1. Granulo de UNA hipotesis, en formato If / And / Then.
--     Cambiar el codigo para consultar otra hipotesis.
-- ---------------------------------------------------------------------
SET @hipotesis = 'E05';

SELECT conector, enunciado, pregunta, respuesta_esperada
FROM (
  SELECT r.orden,
         IF(r.orden = 1, 'If', 'And')                                        AS conector,
         IF(r.valor_respuesta = 1, p.enunciado_positivo, p.enunciado_negativo) AS enunciado,
         p.texto_pregunta                                                      AS pregunta,
         IF(r.valor_respuesta = 1, 'Si', 'No')                                 AS respuesta_esperada
  FROM hipotesis h
  JOIN respuesta r ON r.id_hipotesis = h.id_hipotesis
  JOIN pregunta  p ON p.id_pregunta  = r.id_pregunta
  WHERE h.codigo = @hipotesis
  UNION ALL
  SELECT 999, 'Then',
         CONCAT('el sistema determina: ', h.diagnostico),
         CONCAT('Urgencia ', h.nivel_urgencia, ' | FC ', h.factor_certeza, ' % | ', h.especialista),
         h.accion_recomendada
  FROM hipotesis h
  WHERE h.codigo = @hipotesis
) g
ORDER BY g.orden;


-- ---------------------------------------------------------------------
-- A2. Todos los granulos: una fila por hipotesis con su regla completa.
-- ---------------------------------------------------------------------
SELECT c.nombre                                   AS categoria,
       h.codigo                                   AS hipotesis,
       CONCAT(GROUP_CONCAT(
                CONCAT(IF(r.orden = 1, 'If ', 'And '),
                       IF(r.valor_respuesta = 1, p.enunciado_positivo, p.enunciado_negativo))
                ORDER BY r.orden SEPARATOR ' '),
              ' Then ', h.diagnostico)            AS regla,
       COUNT(*)                                   AS num_respuestas,
       h.nivel_urgencia,
       h.factor_certeza,
       h.especialista
FROM hipotesis h
JOIN categoria c ON c.id_categoria = h.id_categoria
JOIN respuesta r ON r.id_hipotesis = h.id_hipotesis
JOIN pregunta  p ON p.id_pregunta  = r.id_pregunta
GROUP BY c.orden, c.nombre, h.id_hipotesis, h.codigo, h.diagnostico,
         h.nivel_urgencia, h.factor_certeza, h.especialista
ORDER BY c.orden, h.codigo;


-- ---------------------------------------------------------------------
-- A3. Resumen por categoria: cuantas hipotesis y cuantas respuestas.
--     Muestra que una hipotesis puede tener una o varias respuestas.
-- ---------------------------------------------------------------------
SELECT c.nombre                         AS categoria,
       COUNT(DISTINCT h.id_hipotesis)   AS hipotesis,
       COUNT(*)                         AS respuestas,
       MIN(n.num)                       AS min_respuestas_por_hipotesis,
       MAX(n.num)                       AS max_respuestas_por_hipotesis
FROM categoria c
JOIN hipotesis h ON h.id_categoria = c.id_categoria
JOIN respuesta r ON r.id_hipotesis = h.id_hipotesis
JOIN (SELECT id_hipotesis, COUNT(*) AS num FROM respuesta GROUP BY id_hipotesis) n
     ON n.id_hipotesis = h.id_hipotesis
GROUP BY c.orden, c.nombre
ORDER BY c.orden;


-- ---------------------------------------------------------------------
-- A4. Hipotesis de urgencia critica (activan la alerta del RF02).
-- ---------------------------------------------------------------------
SELECT h.codigo, c.nombre AS categoria, h.diagnostico, h.factor_certeza,
       h.especialista, h.accion_recomendada
FROM hipotesis h
JOIN categoria c ON c.id_categoria = h.id_categoria
WHERE h.nivel_urgencia = 'Critica'
ORDER BY h.factor_certeza DESC;


-- ---------------------------------------------------------------------
-- A5. En que hipotesis interviene una pregunta y con que respuesta.
--     Cambiar el codigo para consultar otra pregunta.
-- ---------------------------------------------------------------------
SET @pregunta = 'breaker';

SELECT p.texto_pregunta,
       h.codigo                              AS hipotesis,
       h.diagnostico,
       IF(r.valor_respuesta = 1, 'Si', 'No') AS respuesta_requerida,
       IF(r.orden = 1, 'If', 'And')          AS conector,
       r.orden                               AS posicion_en_la_regla
FROM pregunta p
JOIN respuesta r ON r.id_pregunta  = p.id_pregunta
JOIN hipotesis h ON h.id_hipotesis = r.id_hipotesis
WHERE p.codigo = @pregunta
ORDER BY h.codigo;


-- ---------------------------------------------------------------------
-- A6. Uso de cada pregunta en la base de conocimiento.
-- ---------------------------------------------------------------------
SELECT c.nombre AS categoria, p.codigo, p.texto_pregunta,
       SUM(r.valor_respuesta = 1) AS veces_con_si,
       SUM(r.valor_respuesta = 0) AS veces_con_no,
       COUNT(*)                   AS hipotesis_donde_aparece
FROM pregunta p
JOIN categoria c ON c.id_categoria = p.id_categoria
JOIN respuesta r ON r.id_pregunta  = p.id_pregunta
GROUP BY c.orden, c.nombre, p.id_pregunta, p.codigo, p.texto_pregunta
ORDER BY c.orden, hipotesis_donde_aparece DESC;


-- ---------------------------------------------------------------------
-- A7. Hipotesis complementarias pendientes de validar con el experto.
-- ---------------------------------------------------------------------
SELECT h.codigo, h.diagnostico, h.nivel_urgencia, h.factor_certeza, h.fuente
FROM hipotesis h
WHERE h.validada = 0
ORDER BY h.codigo;


-- =====================================================================
--  PARTE B. DEMOSTRACION DEL MOTOR DE INFERENCIA (datos de prueba)
--  Ejecutar una sola vez.
-- =====================================================================
USE se_transaccional;

-- ---------------------------------------------------------------------
-- B1. Usuario de prueba con su cliente y su vivienda. La aplicacion no
--     tiene roles ni administrador: todo usuario es consultante.
--     La contrasena es un valor de ejemplo; la aplicacion guarda el
--     resumen real con scripts/semilla.py (RNF02).
-- ---------------------------------------------------------------------
INSERT INTO usuario (nombres, apellidos, correo, usuario, contrasena_hash) VALUES
  ('Usuario', 'Consultante', 'consulta@ejemplo.test', 'consulta', 'ejemplo.no.valido.consulta');

INSERT INTO cliente (id_usuario, tipo_documento, numero_documento, telefono)
SELECT id_usuario, 'CC', '1000000003', '3000000000'
FROM usuario WHERE usuario = 'consulta';

INSERT INTO vivienda (id_cliente, alias, direccion, ciudad, tipo_vivienda, antiguedad_anios)
SELECT cl.id_cliente, 'Casa principal', 'Calle 00 # 00-00', 'Bogota', 'Casa', 25
FROM cliente cl
JOIN usuario u ON u.id_usuario = cl.id_usuario AND u.usuario = 'consulta';

-- ---------------------------------------------------------------------
-- B2. Se abre una atencion en la categoria electrica.
-- ---------------------------------------------------------------------
INSERT INTO atencion (id_vivienda, id_categoria, zona_vivienda)
SELECT v.id_vivienda, c.id_categoria, 'Cocina'
FROM vivienda v
JOIN cliente cl ON cl.id_cliente = v.id_cliente
JOIN usuario u  ON u.id_usuario  = cl.id_usuario AND u.usuario = 'consulta'
JOIN se_base_conocimiento.categoria c ON c.codigo = 'ELE';
SET @atencion = LAST_INSERT_ID();

-- ---------------------------------------------------------------------
-- B3. SIGUIENTE PREGUNTA (encadenamiento hacia atras).
--     Entre las hipotesis de la categoria que todavia son posibles
--     (ninguna respuesta dada las contradice), devuelve la primera
--     pregunta de su ruta que aun no se ha respondido. Si no devuelve
--     filas, ya no hay nada que preguntar y se ejecuta B5.
--     Ejecutar antes de cada respuesta.
-- ---------------------------------------------------------------------
SELECT p.codigo, p.texto_pregunta
FROM se_base_conocimiento.hipotesis h
JOIN se_base_conocimiento.respuesta r ON r.id_hipotesis = h.id_hipotesis
JOIN se_base_conocimiento.pregunta  p ON p.id_pregunta  = r.id_pregunta
WHERE h.activa = 1
  AND h.id_categoria = (SELECT id_categoria FROM atencion WHERE id_atencion = @atencion)
  AND NOT EXISTS (SELECT 1
                  FROM se_base_conocimiento.respuesta r2
                  JOIN atencion_respuesta ar ON ar.id_pregunta = r2.id_pregunta
                                            AND ar.id_atencion = @atencion
                  WHERE r2.id_hipotesis = h.id_hipotesis
                    AND ar.respuesta <> r2.valor_respuesta)
  AND NOT EXISTS (SELECT 1 FROM atencion_respuesta ar
                  WHERE ar.id_atencion = @atencion AND ar.id_pregunta = r.id_pregunta)
ORDER BY r.orden, h.codigo
LIMIT 1;
-- Primera ejecucion -> olor_quemado

-- ---------------------------------------------------------------------
-- B4. El usuario responde. En el caso de prueba: hay olor a quemado (Si)
--     y hay sobrecalentamiento (Si). Tras la segunda respuesta, B3 ya
--     no devuelve filas.
-- ---------------------------------------------------------------------
INSERT INTO atencion_respuesta (id_atencion, id_pregunta, respuesta, orden)
SELECT @atencion, id_pregunta, 1, 1 FROM se_base_conocimiento.pregunta WHERE codigo = 'olor_quemado';
-- (B3 ahora devuelve -> sobrecalentamiento)
INSERT INTO atencion_respuesta (id_atencion, id_pregunta, respuesta, orden)
SELECT @atencion, id_pregunta, 1, 2 FROM se_base_conocimiento.pregunta WHERE codigo = 'sobrecalentamiento';

-- ---------------------------------------------------------------------
-- B5. INFERENCIA: hipotesis cuyas respuestas coinciden TODAS con las
--     dadas por el usuario. Las hipotesis de una categoria son
--     mutuamente excluyentes, asi que devuelve a lo sumo una fila.
--     Sin filas = sin diagnostico concluyente (RNF22).
-- ---------------------------------------------------------------------
SELECT h.codigo, h.diagnostico, h.nivel_urgencia, h.factor_certeza,
       h.especialista, h.accion_recomendada
FROM se_base_conocimiento.hipotesis h
JOIN se_base_conocimiento.respuesta r ON r.id_hipotesis = h.id_hipotesis
JOIN atencion_respuesta ar ON ar.id_pregunta = r.id_pregunta
                          AND ar.id_atencion = @atencion
WHERE h.activa = 1
GROUP BY h.id_hipotesis, h.codigo, h.diagnostico, h.nivel_urgencia,
         h.factor_certeza, h.especialista, h.accion_recomendada
HAVING COUNT(*) = (SELECT COUNT(*) FROM se_base_conocimiento.respuesta r3
                   WHERE r3.id_hipotesis = h.id_hipotesis)
   AND SUM(ar.respuesta <> r.valor_respuesta) = 0
ORDER BY FIELD(h.nivel_urgencia, 'Critica', 'Alta', 'Media', 'Baja'), h.factor_certeza DESC;
-- Resultado esperado -> E05 Riesgo de incendio electrico (Critica)

-- ---------------------------------------------------------------------
-- B6. Se guarda el diagnostico (copia historica) y se cierra la atencion.
-- ---------------------------------------------------------------------
INSERT INTO atencion_diagnostico (id_atencion, id_hipotesis, diagnostico_texto, nivel_urgencia,
                                  especialista_sugerido, accion_recomendada, factor_certeza)
SELECT @atencion, h.id_hipotesis, h.diagnostico, h.nivel_urgencia,
       h.especialista, h.accion_recomendada, h.factor_certeza
FROM se_base_conocimiento.hipotesis h
WHERE h.codigo = 'E05';

UPDATE atencion SET estado = 'DIAGNOSTICADA', fecha_fin = NOW() WHERE id_atencion = @atencion;

-- ---------------------------------------------------------------------
-- B7. Hipotesis ponderadas de la atencion: las 5 mas probables y H0,
--     con su probabilidad previa y final. Son los valores que calcula el
--     motor bayesiano de la aplicacion para estas dos respuestas.
-- ---------------------------------------------------------------------
INSERT INTO atencion_hipotesis (id_atencion, id_hipotesis, codigo_hipotesis, diagnostico_texto,
                                posicion, probabilidad_previa, probabilidad)
SELECT @atencion, h.id_hipotesis, v.codigo, COALESCE(h.diagnostico, v.texto), v.posicion, v.previa, v.final
FROM (SELECT 'E05' AS codigo, NULL AS texto, 1 AS posicion, 0.092416 AS previa, 0.935871 AS final
      UNION ALL SELECT 'E01', NULL, 2, 0.087448, 0.018073
      UNION ALL SELECT 'E12', NULL, 3, 0.076517, 0.015813
      UNION ALL SELECT 'E08', NULL, 4, 0.075523, 0.015608
      UNION ALL SELECT 'H0', 'Sin falla identificable con las reglas', 5, 0.050000, 0.005272
      UNION ALL SELECT 'E02', NULL, 6, 0.091423, 0.001928) v
LEFT JOIN se_base_conocimiento.hipotesis h ON h.codigo = v.codigo;

-- ---------------------------------------------------------------------
-- B8. Caso sin diagnostico concluyente: categoria acustica, el usuario
--     responde No a la unica pregunta. B5 no devuelve filas.
-- ---------------------------------------------------------------------
INSERT INTO atencion (id_vivienda, id_categoria, zona_vivienda)
SELECT v.id_vivienda, c.id_categoria, 'Habitación'
FROM vivienda v
JOIN cliente cl ON cl.id_cliente = v.id_cliente
JOIN usuario u  ON u.id_usuario  = cl.id_usuario AND u.usuario = 'consulta'
JOIN se_base_conocimiento.categoria c ON c.codigo = 'CAC';
SET @atencion2 = LAST_INSERT_ID();

INSERT INTO atencion_respuesta (id_atencion, id_pregunta, respuesta, orden)
SELECT @atencion2, id_pregunta, 0, 1 FROM se_base_conocimiento.pregunta WHERE codigo = 'ruido_exterior';

INSERT INTO atencion_diagnostico (id_atencion, id_hipotesis, diagnostico_texto)
VALUES (@atencion2, NULL, 'Sin diagnóstico concluyente');

INSERT INTO atencion_hipotesis (id_atencion, id_hipotesis, codigo_hipotesis, diagnostico_texto,
                                posicion, probabilidad_previa, probabilidad)
SELECT @atencion2, NULL, 'H0', 'Sin falla identificable con las reglas', 1, 0.050000, 0.703125
UNION ALL
SELECT @atencion2, h.id_hipotesis, h.codigo, h.diagnostico, 2, 0.950000, 0.296875
FROM se_base_conocimiento.hipotesis h WHERE h.codigo = 'C03';

UPDATE atencion SET estado = 'SIN_DIAGNOSTICO', fecha_fin = NOW() WHERE id_atencion = @atencion2;

-- ---------------------------------------------------------------------
-- B9. Historial del cliente (RF02): atenciones, respuestas y diagnostico.
-- ---------------------------------------------------------------------
SELECT a.id_atencion, a.fecha_inicio, c.nombre AS categoria, a.zona_vivienda, a.estado,
       COUNT(ar.id_atencion_respuesta) AS preguntas_respondidas,
       d.diagnostico_texto, d.nivel_urgencia, d.especialista_sugerido
FROM atencion a
JOIN vivienda v ON v.id_vivienda = a.id_vivienda
JOIN cliente cl ON cl.id_cliente = v.id_cliente
JOIN usuario  u ON u.id_usuario  = cl.id_usuario
JOIN se_base_conocimiento.categoria c ON c.id_categoria = a.id_categoria
LEFT JOIN atencion_respuesta   ar ON ar.id_atencion = a.id_atencion
LEFT JOIN atencion_diagnostico d  ON d.id_atencion  = a.id_atencion
WHERE u.usuario = 'consulta'
GROUP BY a.id_atencion, a.fecha_inicio, c.nombre, a.zona_vivienda, a.estado,
         d.diagnostico_texto, d.nivel_urgencia, d.especialista_sugerido
ORDER BY a.fecha_inicio DESC;

-- B10. Preguntas y respuestas de una atencion, en el orden en que se hicieron.
SELECT ar.orden, p.texto_pregunta, IF(ar.respuesta = 1, 'Si', 'No') AS respuesta
FROM atencion_respuesta ar
JOIN se_base_conocimiento.pregunta p ON p.id_pregunta = ar.id_pregunta
WHERE ar.id_atencion = @atencion
ORDER BY ar.orden;
