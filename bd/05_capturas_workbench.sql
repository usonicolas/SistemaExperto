-- =====================================================================
--  SISTEMA EXPERTO DE DIAGNOSTICO DE VIVIENDA
--  CONSULTAS PARA LAS CAPTURAS DEL MANUAL TECNICO (MySQL Workbench)
--
--  Requisito: haber ejecutado los scripts 01, 02, 03 y 04.
--  Uso: ubicar el cursor dentro de un bloque y presionar Ctrl + Enter
--  (ejecuta solo la sentencia actual). Cada bloque es independiente.
--  Tomar la captura de la grilla de resultados y guardarla en la
--  carpeta "figuras" con el nombre indicado.
-- =====================================================================
-- ---------------------------------------------------------------------
-- CAPTURA 1  ->  figuras/captura_A1_granulo_E05.png
-- Granulo de la hipotesis E05 en formato If / And / Then
-- ---------------------------------------------------------------------
SELECT conector, enunciado, pregunta, respuesta_esperada
FROM (
  SELECT r.orden,
         IF(r.orden = 1, 'If', 'And') AS conector,
         IF(r.valor_respuesta = 1, p.enunciado_positivo, p.enunciado_negativo) AS enunciado,
         p.texto_pregunta AS pregunta,
         IF(r.valor_respuesta = 1, 'Si', 'No') AS respuesta_esperada
  FROM se_base_conocimiento.hipotesis h
  JOIN se_base_conocimiento.respuesta r ON r.id_hipotesis = h.id_hipotesis
  JOIN se_base_conocimiento.pregunta  p ON p.id_pregunta  = r.id_pregunta
  WHERE h.codigo = 'E05'
  UNION ALL
  SELECT 999, 'Then', CONCAT('el sistema determina: ', h.diagnostico),
         CONCAT('Urgencia ', h.nivel_urgencia, ' | FC ', h.factor_certeza, ' % | ', h.especialista),
         h.accion_recomendada
  FROM se_base_conocimiento.hipotesis h
  WHERE h.codigo = 'E05'
) g
ORDER BY g.orden;


-- ---------------------------------------------------------------------
-- CAPTURA 2  ->  figuras/captura_A3_resumen.png
-- Resumen de granulos cargados por categoria
-- ---------------------------------------------------------------------
SELECT c.nombre AS categoria,
       COUNT(DISTINCT h.id_hipotesis) AS hipotesis,
       COUNT(*)                       AS respuestas,
       MIN(n.num) AS min_respuestas_por_hipotesis,
       MAX(n.num) AS max_respuestas_por_hipotesis
FROM se_base_conocimiento.categoria c
JOIN se_base_conocimiento.hipotesis h ON h.id_categoria = c.id_categoria
JOIN se_base_conocimiento.respuesta r ON r.id_hipotesis = h.id_hipotesis
JOIN (SELECT id_hipotesis, COUNT(*) AS num FROM se_base_conocimiento.respuesta GROUP BY id_hipotesis) n
     ON n.id_hipotesis = h.id_hipotesis
GROUP BY c.orden, c.nombre
ORDER BY c.orden;


-- ---------------------------------------------------------------------
-- CAPTURA 3  ->  figuras/captura_A4_criticas.png
-- Hipotesis de urgencia critica
-- ---------------------------------------------------------------------
SELECT h.codigo, c.nombre AS categoria, h.diagnostico, h.factor_certeza, h.especialista
FROM se_base_conocimiento.hipotesis h
JOIN se_base_conocimiento.categoria c ON c.id_categoria = h.id_categoria
WHERE h.nivel_urgencia = 'Critica'
ORDER BY h.factor_certeza DESC;


-- ---------------------------------------------------------------------
-- CAPTURA 4  ->  figuras/captura_A5_breaker.png
-- Hipotesis en las que interviene la pregunta del breaker
-- ---------------------------------------------------------------------
SELECT h.codigo AS hipotesis, h.diagnostico,
       IF(r.valor_respuesta = 1, 'Si', 'No') AS respuesta_requerida,
       IF(r.orden = 1, 'If', 'And') AS conector, r.orden AS posicion
FROM se_base_conocimiento.pregunta p
JOIN se_base_conocimiento.respuesta r ON r.id_pregunta  = p.id_pregunta
JOIN se_base_conocimiento.hipotesis h ON h.id_hipotesis = r.id_hipotesis
WHERE p.codigo = 'breaker'
ORDER BY h.codigo;


-- ---------------------------------------------------------------------
-- CAPTURA 5  ->  figuras/captura_B5_inferencia.png
-- Inferencia sobre la atencion de prueba numero 1 (categoria electrica)
-- ---------------------------------------------------------------------
SELECT h.codigo, h.diagnostico, h.nivel_urgencia, h.factor_certeza, h.especialista
FROM se_base_conocimiento.hipotesis h
JOIN se_base_conocimiento.respuesta r ON r.id_hipotesis = h.id_hipotesis
JOIN se_transaccional.atencion_respuesta ar ON ar.id_pregunta = r.id_pregunta
                                           AND ar.id_atencion = 1
WHERE h.activa = 1
GROUP BY h.id_hipotesis, h.codigo, h.diagnostico, h.nivel_urgencia, h.factor_certeza, h.especialista
HAVING COUNT(*) = (SELECT COUNT(*) FROM se_base_conocimiento.respuesta r3
                   WHERE r3.id_hipotesis = h.id_hipotesis)
   AND SUM(ar.respuesta <> r.valor_respuesta) = 0;


-- ---------------------------------------------------------------------
-- CAPTURA 6  ->  figuras/captura_B10_historial.png
-- Historial del cliente de prueba (atencion con diagnostico y sin el)
-- ---------------------------------------------------------------------
SELECT a.id_atencion, c.nombre AS categoria, a.zona_vivienda, a.estado,
       COUNT(ar.id_atencion_respuesta) AS preguntas_respondidas,
       d.diagnostico_texto, d.nivel_urgencia, d.especialista_sugerido
FROM se_transaccional.atencion a
JOIN se_transaccional.vivienda v ON v.id_vivienda = a.id_vivienda
JOIN se_transaccional.cliente cl ON cl.id_cliente = v.id_cliente
JOIN se_transaccional.usuario  u ON u.id_usuario  = cl.id_usuario
JOIN se_base_conocimiento.categoria c ON c.id_categoria = a.id_categoria
LEFT JOIN se_transaccional.atencion_respuesta   ar ON ar.id_atencion = a.id_atencion
LEFT JOIN se_transaccional.atencion_diagnostico d  ON d.id_atencion  = a.id_atencion
WHERE u.usuario = 'consulta'
GROUP BY a.id_atencion, c.nombre, a.zona_vivienda, a.estado,
         d.diagnostico_texto, d.nivel_urgencia, d.especialista_sugerido
ORDER BY a.id_atencion;


-- ---------------------------------------------------------------------
-- CAPTURA 7  ->  figuras/captura_B7_hipotesis_ponderadas.png
-- Hipotesis ponderadas de la atencion de prueba numero 1
-- ---------------------------------------------------------------------
SELECT ah.posicion, ah.codigo_hipotesis, ah.diagnostico_texto,
       ROUND(ah.probabilidad_previa * 100, 1) AS previa_pct,
       ROUND(ah.probabilidad * 100, 1)        AS final_pct
FROM se_transaccional.atencion_hipotesis ah
WHERE ah.id_atencion = 1
ORDER BY ah.posicion;
