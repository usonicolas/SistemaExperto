-- =====================================================================
--  SISTEMA EXPERTO DE DIAGNOSTICO DE VIVIENDA
--  SCRIPT 3 de 4  -  CARGA DEL CONOCIMIENTO DEL EXPERTO HUMANO
--
--  Universidad Manuela Beltran - Ingenieria de Software
--  Sistemas Expertos - Ing. Jose Marcial Tellez Gomez
--  Lina Maria Brinez Rodriguez & Victor Alfonso Alarcon Ospina - 2026
--
--  Carga en la base de conocimiento lo obtenido en las entrevistas con
--  el electricista, el tecnico en fontaneria, el ingeniero civil y el
--  tecnico en gas:
--     7 categorias, 36 preguntas, 49 hipotesis y 190 respuestas.
--
--  Las llaves se resuelven por CODIGO (no por id numerico), asi que el
--  script no depende del orden de los AUTO_INCREMENT.
--
--  Generado a partir de la misma fuente que el manual tecnico (arboles
--  de decision y reglas If / And / Then).
--  Ejecutar despues de 01_base_conocimiento.sql y 02_transaccional.sql.
-- =====================================================================

SET NAMES utf8mb4;
USE se_base_conocimiento;

-- ---------------------------------------------------------------------
-- 1. Categorias (raiz de cada arbol de decision)
-- ---------------------------------------------------------------------
INSERT INTO categoria (codigo, nombre, descripcion, orden) VALUES
  ('ELE', 'Eléctrica', 'Fallas en la instalación eléctrica de la vivienda', 1),
  ('HID', 'Hidráulica', 'Fugas, obstrucciones y fallas en el agua y el desagüe', 2),
  ('EST', 'Estructural', 'Grietas, asentamientos e integridad estructural', 3),
  ('HUM', 'Humedad', 'Filtraciones, moho y condensación', 4),
  ('GAS', 'Gas', 'Fugas y fallas en la red de gas domiciliario', 5),
  ('CTE', 'Confort térmico', 'Aislamiento térmico de la vivienda', 6),
  ('CAC', 'Confort acústico', 'Aislamiento acústico de la vivienda', 7);

-- ---------------------------------------------------------------------
-- 2. Preguntas (sintomas), agrupadas por categoria
-- ---------------------------------------------------------------------
-- Eléctrica (8 preguntas)
INSERT INTO pregunta (id_categoria, codigo, texto_pregunta, enunciado_positivo, enunciado_negativo) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'olor_quemado',
   '¿Olor a quemado en tomas o tablero?',
   'hay olor a quemado en tomas o en el tablero eléctrico',
   'no hay olor a quemado en tomas ni en el tablero eléctrico'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'sobrecalentamiento',
   '¿Enchufes o interruptores sobrecalentados?',
   'hay sobrecalentamiento de enchufes o interruptores',
   'no hay sobrecalentamiento de enchufes ni interruptores'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'breaker',
   '¿El breaker se dispara con frecuencia?',
   'el disyuntor (breaker) se dispara con frecuencia',
   'el disyuntor (breaker) no se dispara con frecuencia'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'chispas',
   '¿Chispas al conectar un electrodoméstico?',
   'se presentan chispas al conectar o desconectar un electrodoméstico',
   'no se presentan chispas al conectar o desconectar un electrodoméstico'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'cables',
   '¿Cables expuestos o deteriorados?',
   'hay cables visiblemente expuestos o deteriorados',
   'no hay cables expuestos ni deteriorados'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'cortos',
   '¿Cortocircuitos frecuentes?',
   'se presentan cortocircuitos frecuentes',
   'no se presentan cortocircuitos frecuentes'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'parpadeo',
   '¿Parpadeo constante de las luces?',
   'hay parpadeo constante de las luces',
   'no hay parpadeo constante de las luces'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'tomas',
   '¿Tomas que dejan de funcionar?',
   'hay tomas de corriente que dejan de funcionar',
   'no hay tomas de corriente que hayan dejado de funcionar');

-- Hidráulica (8 preguntas)
INSERT INTO pregunta (id_categoria, codigo, texto_pregunta, enunciado_positivo, enunciado_negativo) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'fuga_visible',
   '¿Fuga visible en tuberías?',
   'hay fuga visible en tuberías o conexiones',
   'no hay fuga visible en tuberías ni conexiones'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'humedad_lavamanos',
   '¿Humedad bajo el lavamanos?',
   'hay manchas de humedad bajo el lavamanos o el fregadero',
   'no hay manchas de humedad bajo el lavamanos ni el fregadero'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'agua_color',
   '¿Agua con color o turbidez?',
   'el agua sale con color, olor o turbidez inusual',
   'el agua no presenta color, olor ni turbidez inusual'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'mal_olor_desague',
   '¿Mal olor en los desagües?',
   'hay mal olor proveniente de los desagües',
   'no hay mal olor proveniente de los desagües'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'obstruccion',
   '¿Desagües obstruidos o lentos?',
   'hay obstrucción o lentitud en los desagües',
   'no hay obstrucción ni lentitud en los desagües'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'baja_presion',
   '¿Baja presión de agua?',
   'hay baja presión de agua en uno o varios puntos',
   'no hay baja presión de agua'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'golpeteo',
   '¿Golpeteo en las tuberías?',
   'hay ruidos (golpeteo) en las tuberías al abrir o cerrar llaves',
   'no hay ruidos ni golpeteo en las tuberías'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'goteo',
   '¿Goteo constante en grifos?',
   'hay goteo constante en grifos o llaves de paso',
   'no hay goteo en grifos ni llaves de paso');

-- Estructural (8 preguntas)
INSERT INTO pregunta (id_categoria, codigo, texto_pregunta, enunciado_positivo, enunciado_negativo) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'hundimiento',
   '¿Hundimiento o desnivel en el piso?',
   'hay hundimiento o desnivel perceptible en el piso',
   'no hay hundimiento ni desnivel perceptible en el piso'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'inclinacion',
   '¿Inclinación en muros o columnas?',
   'hay inclinación visible en muros o columnas',
   'no hay inclinación visible en muros ni columnas'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'grietas_diagonales',
   '¿Grietas diagonales en paredes?',
   'hay grietas diagonales en paredes',
   'no hay grietas diagonales en paredes'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'puertas',
   '¿Puertas o ventanas que no cierran?',
   'hay puertas o ventanas que dejan de cerrar correctamente',
   'las puertas y ventanas cierran correctamente'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'grietas_vh',
   '¿Grietas verticales u horizontales?',
   'hay grietas verticales u horizontales en paredes',
   'no hay grietas verticales ni horizontales en paredes'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'humedad_ascendente',
   '¿Humedad ascendente en muros?',
   'hay humedad ascendente en la base de los muros o cimientos',
   'no hay humedad ascendente en la base de los muros ni cimientos'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'fisuras_techo',
   '¿Fisuras finas en el techo?',
   'hay grietas o fisuras finas visibles en el techo o placa',
   'no hay grietas ni fisuras visibles en el techo ni la placa'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'panete',
   '¿Desprendimiento de pañete?',
   'hay desprendimiento de revoque, pañete o recubrimiento',
   'no hay desprendimiento de revoque, pañete ni recubrimiento');

-- Humedad (5 preguntas)
INSERT INTO pregunta (id_categoria, codigo, texto_pregunta, enunciado_positivo, enunciado_negativo) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'manchas',
   '¿Manchas de humedad en techo o pared?',
   'hay manchas de humedad en techos o paredes',
   'no hay manchas de humedad en techos ni paredes'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'moho',
   '¿Moho u hongos visibles?',
   'hay presencia visible de moho u hongos',
   'no hay presencia visible de moho ni hongos'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'pintura',
   '¿Pintura descascarada o ampollada?',
   'hay pintura descascarada, ampollada o desprendida',
   'no hay pintura descascarada, ampollada ni desprendida'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'olor_humedad',
   '¿Olor persistente a humedad?',
   'hay olor persistente a humedad o encierro',
   'no hay olor persistente a humedad ni encierro'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'condensacion',
   '¿Condensación en ventanas?',
   'hay condensación recurrente en ventanas o superficies frías',
   'no hay condensación recurrente en ventanas ni superficies frías');

-- Gas (4 preguntas)
INSERT INTO pregunta (id_categoria, codigo, texto_pregunta, enunciado_positivo, enunciado_negativo) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'GAS'), 'olor_gas',
   '¿Olor característico a gas?',
   'hay olor característico a gas dentro de la vivienda',
   'no hay olor característico a gas dentro de la vivienda'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'GAS'), 'silbido',
   '¿Silbido en tuberías de gas?',
   'hay silbido audible cerca de tuberías o conexiones de gas',
   'no hay silbido audible cerca de tuberías ni conexiones de gas'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'GAS'), 'consumo_gas',
   '¿Consumo de gas inusualmente alto?',
   'hay un aumento inusual en el consumo de gas sin justificación aparente',
   'no hay un aumento inusual en el consumo de gas'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'GAS'), 'llama_amarilla',
   '¿Llama amarilla o naranja?',
   'la llama de la estufa es de color amarillo o naranja en lugar de azul',
   'la llama de la estufa es azul');

-- Confort térmico (2 preguntas)
INSERT INTO pregunta (id_categoria, codigo, texto_pregunta, enunciado_positivo, enunciado_negativo) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'CTE'), 'corrientes_aire',
   '¿Corrientes de aire en ventanas o puertas?',
   'hay corrientes de aire perceptibles alrededor de ventanas o puertas',
   'no hay corrientes de aire perceptibles alrededor de ventanas ni puertas'),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'CTE'), 'diferencia_temp',
   '¿Diferencias de temperatura entre habitaciones?',
   'hay diferencias notorias de temperatura entre habitaciones',
   'no hay diferencias notorias de temperatura entre habitaciones');

-- Confort acústico (1 preguntas)
INSERT INTO pregunta (id_categoria, codigo, texto_pregunta, enunciado_positivo, enunciado_negativo) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'CAC'), 'ruido_exterior',
   '¿Ruido exterior excesivo?',
   'hay ingreso excesivo de ruido exterior',
   'no hay ingreso excesivo de ruido exterior');

-- ---------------------------------------------------------------------
-- 3. Hipotesis (consecuente Then de cada regla)
--    validada = 0: hipotesis complementaria, pendiente de validar con el experto
-- ---------------------------------------------------------------------
-- Eléctrica (12 hipotesis)
INSERT INTO hipotesis (id_categoria, codigo, diagnostico, nivel_urgencia, especialista, accion_recomendada, factor_certeza, fuente, validada) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E05', 'Riesgo de incendio eléctrico', 'Critica',
   'Electricista (atención urgente)',
   'Bajar el breaker de inmediato, no volver a energizar la zona y llamar a un electricista con carácter urgente.',
   93, 'Entrevista 1 - Electricista residencial', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E01', 'Sobrecarga del circuito o falla en el tablero', 'Alta',
   'Electricista certificado',
   'Bajar el breaker de la zona afectada y no volver a usarla hasta la revisión de un electricista.',
   88, 'Entrevista 1 - Electricista residencial', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E08', 'Conexión floja o punto caliente en toma o tablero', 'Alta',
   'Electricista',
   'Desconectar los equipos de la toma afectada, bajar el breaker de la zona si el olor persiste y solicitar revisión.',
   76, 'Entrevista 1 - Electricista residencial', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E02', 'Riesgo de cortocircuito', 'Critica',
   'Electricista (atención urgente)',
   'Desconectar el electrodoméstico afectado y no usar esa toma ni los cables expuestos hasta la revisión.',
   92, 'Entrevista 1 - Electricista residencial', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E09', 'Desgaste de contactos en la toma o la clavija', 'Alta',
   'Electricista',
   'No volver a usar la toma ni el enchufe que produjo la chispa hasta que sean revisados.',
   78, 'Entrevista 1 - Electricista residencial', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E07', 'Deterioro de la instalación eléctrica', 'Media',
   'Electricista',
   'Evitar el contacto con los cables expuestos y aislar temporalmente la zona mientras se programa la reparación.',
   78, 'Entrevista 1 - Electricista residencial', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E06', 'Corto en la instalación', 'Alta',
   'Electricista',
   'Evitar reactivar el breaker repetidamente y solicitar revisión de la instalación antes de seguir usando el circuito.',
   85, 'Entrevista 1 - Electricista residencial', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E10', 'Protección del circuito deficiente', 'Alta',
   'Electricista certificado',
   'Limitar el uso del circuito afectado y solicitar la revisión del tablero y de sus protecciones.',
   70, 'Entrevista 1 - Electricista residencial', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E12', 'Conexión deficiente o sobrecarga en enchufe o interruptor', 'Alta',
   'Electricista',
   'Desconectar los equipos del punto sobrecalentado y no volver a usarlo hasta que sea revisado.',
   77, 'Entrevista 1 - Electricista residencial', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E03', 'Fluctuación de voltaje o falla de conexión', 'Media',
   'Electricista',
   'Evitar conectar electrodomésticos sensibles hasta confirmar la causa de la fluctuación.',
   72, 'Entrevista 1 - Electricista residencial', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E11', 'Sobrecarga por uso simultáneo de equipos', 'Media',
   'Electricista',
   'Repartir los equipos de alto consumo entre distintos circuitos y evitar usarlos al mismo tiempo hasta la revisión.',
   72, 'Entrevista 1 - Electricista residencial', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'ELE'), 'E04', 'Fallo puntual en toma de corriente', 'Baja',
   'Electricista (revisión programada)',
   'Probar la toma con otro electrodoméstico y, si el problema persiste, programar una revisión de rutina.',
   75, 'Entrevista 1 - Electricista residencial', 1);

-- Hidráulica (11 hipotesis)
INSERT INTO hipotesis (id_categoria, codigo, diagnostico, nivel_urgencia, especialista, accion_recomendada, factor_certeza, fuente, validada) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'H01', 'Fuga activa en tubería de suministro', 'Alta',
   'Plomero',
   'Cerrar la llave de paso de esa zona para detener la fuga mientras llega el plomero.',
   90, 'Entrevista 2 - Técnico en fontanería', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'H08', 'Fuga localizada en conexión o accesorio', 'Media',
   'Plomero',
   'Cerrar la llave de paso de la zona y colocar un recipiente bajo la fuga mientras llega el plomero.',
   80, 'Entrevista 2 - Técnico en fontanería', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'H06', 'Contaminación o corrosión en la tubería', 'Alta',
   'Plomero / empresa de acueducto',
   'Suspender el consumo de esa agua para bebida o cocina hasta que sea evaluada.',
   80, 'Entrevista 2 - Técnico en fontanería', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'H07', 'Fuga oculta en conexión de desagüe', 'Media',
   'Plomero',
   'Revisar la conexión bajo el mueble y evitar el uso intensivo de esa salida hasta la revisión.',
   76, 'Entrevista 2 - Técnico en fontanería', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'H09', 'Filtración en conexión de suministro bajo el mueble', 'Media',
   'Plomero',
   'Secar la zona, revisar las mangueras de abasto y vigilar si la mancha crece.',
   70, 'Entrevista 2 - Técnico en fontanería', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'H04', 'Taponamiento en la red de desagüe', 'Media',
   'Plomero',
   'Evitar verter más agua o residuos por ese desagüe hasta destaparlo o hacerlo revisar.',
   82, 'Entrevista 2 - Técnico en fontanería', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'H10', 'Obstrucción localizada en sifón o desagüe', 'Baja',
   'Plomero',
   'Limpiar el sifón o usar un destapador manual, sin mezclar productos químicos; si persiste, llamar al plomero.',
   75, 'Entrevista 2 - Técnico en fontanería', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'H02', 'Obstrucción parcial o sedimentación', 'Media',
   'Plomero',
   'Evitar el uso simultáneo de varias salidas de agua mientras se programa la revisión.',
   68, 'Entrevista 2 - Técnico en fontanería', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'H03', 'Golpe de ariete o aire atrapado', 'Baja',
   'Plomero',
   'Cerrar las llaves de forma gradual mientras se programa la revisión; no representa una urgencia.',
   70, 'Entrevista 2 - Técnico en fontanería', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'H05', 'Empaque o válvula desgastada', 'Baja',
   'Plomero',
   'Cerrar bien la llave tras cada uso y programar el cambio del empaque; no es urgente.',
   74, 'Entrevista 2 - Técnico en fontanería', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HID'), 'H11', 'Sifón seco o ventilación deficiente del desagüe', 'Baja',
   'Plomero',
   'Dejar correr agua en los desagües poco usados para restablecer el sello del sifón; si el olor persiste, solicitar revisión.',
   72, 'Entrevista 2 - Técnico en fontanería', 0);

-- Estructural (10 hipotesis)
INSERT INTO hipotesis (id_categoria, codigo, diagnostico, nivel_urgencia, especialista, accion_recomendada, factor_certeza, fuente, validada) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'S03', 'Riesgo de falla en la cimentación', 'Critica',
   'Ingeniero civil (atención urgente)',
   'Restringir el acceso a la zona afectada y contactar de inmediato a un ingeniero civil.',
   92, 'Entrevista 3 - Ingeniero civil', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'S07', 'Asentamiento del piso o falla del contrapiso', 'Alta',
   'Ingeniero civil',
   'Evitar ubicar cargas pesadas sobre la zona hundida y solicitar la evaluación de un ingeniero civil.',
   80, 'Entrevista 3 - Ingeniero civil', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'S01', 'Asentamiento diferencial de la estructura', 'Alta',
   'Ingeniero civil',
   'Evitar sobrecargar la zona afectada y contactar a un ingeniero civil para una evaluación estructural pronta.',
   85, 'Entrevista 3 - Ingeniero civil', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'S08', 'Grietas por movimiento estructural localizado', 'Media',
   'Ingeniero civil',
   'Marcar los extremos de la grieta con la fecha para vigilar si crece y programar una evaluación estructural.',
   74, 'Entrevista 3 - Ingeniero civil', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'S06', 'Desplome estructural incipiente', 'Alta',
   'Ingeniero civil',
   'Evitar permanecer cerca del muro inclinado y solicitar una evaluación estructural con prontitud.',
   80, 'Entrevista 3 - Ingeniero civil', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'S09', 'Fisuración de muros por retracción o cargas', 'Media',
   'Ingeniero civil',
   'Registrar con fotografías la ubicación y la longitud de la grieta, y solicitar una revisión si aumenta.',
   70, 'Entrevista 3 - Ingeniero civil', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'S04', 'Humedad capilar en cimientos', 'Media',
   'Ingeniero civil / impermeabilizador',
   'Evitar revestir la zona húmeda hasta aplicar una solución de impermeabilización.',
   73, 'Entrevista 3 - Ingeniero civil', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'S02', 'Fisuras superficiales por contracción', 'Baja',
   'Maestro de obra',
   'Monitorear la fisura periódicamente; no requiere atención inmediata si no crece ni se acompaña de otros síntomas.',
   70, 'Entrevista 3 - Ingeniero civil', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'S05', 'Deterioro superficial del recubrimiento', 'Baja',
   'Maestro de obra',
   'Retirar el material suelto para evitar caídas y programar el resane; no representa riesgo estructural.',
   72, 'Entrevista 3 - Ingeniero civil', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'EST'), 'S10', 'Desajuste de la carpintería de puertas o ventanas', 'Baja',
   'Técnico en carpintería',
   'Revisar bisagras y herrajes; si el problema aparece junto con grietas, repetir el diagnóstico estructural.',
   68, 'Entrevista 3 - Ingeniero civil', 0);

-- Humedad (7 hipotesis)
INSERT INTO hipotesis (id_categoria, codigo, diagnostico, nivel_urgencia, especialista, accion_recomendada, factor_certeza, fuente, validada) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'M01', 'Filtración activa desde la cubierta', 'Alta',
   'Impermeabilizador / ingeniero civil',
   'Proteger los objetos bajo la zona afectada y contactar a un impermeabilizador con prontitud.',
   83, 'Entrevista 3 - Ingeniero civil', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'M05', 'Filtración incipiente o fuga en tubería empotrada', 'Media',
   'Plomero / impermeabilizador',
   'Delimitar la mancha con lápiz y observar si crece; verificar si coincide con tuberías o con días de lluvia.',
   74, 'Entrevista 3 - Ingeniero civil', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'M04', 'Humedad ambiental elevada', 'Media',
   'Revisión de ventilación / impermeabilizador',
   'Mejorar la ventilación de la zona y limpiar el moho visible con los productos adecuados.',
   71, 'Entrevista 3 - Ingeniero civil', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'M02', 'Humedad acumulada bajo el recubrimiento', 'Media',
   'Impermeabilizador',
   'Ventilar el espacio y evitar sellar la zona con pintura nueva hasta resolver la humedad de fondo.',
   75, 'Entrevista 3 - Ingeniero civil', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'M06', 'Deterioro del acabado por humedad residual', 'Baja',
   'Maestro de obra / pintor',
   'Raspar la pintura suelta, dejar secar el muro y aplicar un sellador antes de volver a pintar.',
   65, 'Entrevista 3 - Ingeniero civil', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'M03', 'Ventilación insuficiente o puente térmico', 'Baja',
   'Revisión de ventilación',
   'Ventilar el espacio con regularidad y secar la condensación para evitar la aparición de moho.',
   68, 'Entrevista 3 - Ingeniero civil', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'HUM'), 'M07', 'Humedad oculta o ventilación insuficiente', 'Baja',
   'Revisión de ventilación',
   'Ventilar el espacio a diario y revisar zonas cerradas (clósets, detrás de muebles) en busca de humedad.',
   66, 'Entrevista 3 - Ingeniero civil', 0);

-- Gas (6 hipotesis)
INSERT INTO hipotesis (id_categoria, codigo, diagnostico, nivel_urgencia, especialista, accion_recomendada, factor_certeza, fuente, validada) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'GAS'), 'G01', 'Fuga activa de gas', 'Critica',
   'Empresa de gas (atención urgente)',
   'Ventilar de inmediato, no accionar interruptores ni encender llamas, y llamar a la empresa de gas desde afuera.',
   95, 'Entrevista 4 - Técnico en gas domiciliario', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'GAS'), 'G04', 'Fuga leve de gas', 'Critica',
   'Empresa de gas (atención urgente)',
   'Ventilar de inmediato, no accionar interruptores ni encender llamas, cerrar la llave de paso del gas y llamar a la empresa de gas desde afuera.',
   82, 'Entrevista 4 - Técnico en gas domiciliario', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'GAS'), 'G05', 'Fuga en conexión no detectada por el olfato', 'Critica',
   'Empresa de gas (atención urgente)',
   'Ventilar de inmediato y contactar a la empresa de gas con carácter urgente, aunque no se perciba olor.',
   88, 'Entrevista 4 - Técnico en gas domiciliario', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'GAS'), 'G06', 'Posible fuga en conexión de gas', 'Critica',
   'Empresa de gas (atención urgente)',
   'Cerrar la llave de paso del gas, ventilar la vivienda y contactar a la empresa de gas, aunque no se perciba olor.',
   80, 'Entrevista 4 - Técnico en gas domiciliario', 0),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'GAS'), 'G03', 'Posible fuga menor no perceptible', 'Alta',
   'Técnico de gas',
   'Revisar visualmente las conexiones y solicitar una revisión técnica próxima, aunque no haya olor perceptible.',
   74, 'Entrevista 4 - Técnico en gas domiciliario', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'GAS'), 'G02', 'Combustión incompleta o quemador desajustado', 'Media',
   'Técnico de gas',
   'Apagar la estufa y no usarla hasta que un técnico de gas revise y ajuste el quemador.',
   78, 'Entrevista 4 - Técnico en gas domiciliario', 1);

-- Confort térmico (2 hipotesis)
INSERT INTO hipotesis (id_categoria, codigo, diagnostico, nivel_urgencia, especialista, accion_recomendada, factor_certeza, fuente, validada) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'CTE'), 'C01', 'Sellado deficiente de marcos', 'Baja',
   'Técnico en carpintería / sellado',
   'Usar burletes temporales en los marcos y evaluar el sellado profesional de ventanas y puertas.',
   70, 'Entrevista 3 - Ingeniero civil', 1),
  ((SELECT id_categoria FROM categoria WHERE codigo = 'CTE'), 'C02', 'Aislamiento térmico insuficiente', 'Baja',
   'Especialista en aislamiento',
   'Identificar las zonas con mayor pérdida térmica y considerar mejorar el aislamiento en esos puntos.',
   65, 'Entrevista 3 - Ingeniero civil', 1);

-- Confort acústico (1 hipotesis)
INSERT INTO hipotesis (id_categoria, codigo, diagnostico, nivel_urgencia, especialista, accion_recomendada, factor_certeza, fuente, validada) VALUES
  ((SELECT id_categoria FROM categoria WHERE codigo = 'CAC'), 'C03', 'Aislamiento acústico insuficiente', 'Baja',
   'Especialista en acústica',
   'Evaluar el sellado de ventanas y considerar materiales de aislamiento acústico en la zona más expuesta.',
   65, 'Entrevista 3 - Ingeniero civil', 1);

-- ---------------------------------------------------------------------
-- 4. Respuestas que conforman cada hipotesis (antecedentes If / And)
--    Cada bloque es un granulo de conocimiento: la regla completa.
-- ---------------------------------------------------------------------

-- ===== Rama Eléctrica =====

-- E05 - Riesgo de incendio eléctrico  (Crítica, FC 93 %)
--   If  hay olor a quemado en tomas o en el tablero eléctrico
--   And hay sobrecalentamiento de enchufes o interruptores
--   Then el sistema determina: Riesgo de incendio eléctrico
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 1 AS valor, 1 AS orden
      UNION ALL SELECT 'sobrecalentamiento', 1, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E05';

-- E01 - Sobrecarga del circuito o falla en el tablero  (Alta, FC 88 %)
--   If  hay olor a quemado en tomas o en el tablero eléctrico
--   And no hay sobrecalentamiento de enchufes ni interruptores
--   And el disyuntor (breaker) se dispara con frecuencia
--   Then el sistema determina: Sobrecarga del circuito o falla en el tablero
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 1 AS valor, 1 AS orden
      UNION ALL SELECT 'sobrecalentamiento', 0, 2
      UNION ALL SELECT 'breaker', 1, 3) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E01';

-- E08 - Conexión floja o punto caliente en toma o tablero  (Alta, FC 76 %)
--   If  hay olor a quemado en tomas o en el tablero eléctrico
--   And no hay sobrecalentamiento de enchufes ni interruptores
--   And el disyuntor (breaker) no se dispara con frecuencia
--   Then el sistema determina: Conexión floja o punto caliente en toma o tablero
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 1 AS valor, 1 AS orden
      UNION ALL SELECT 'sobrecalentamiento', 0, 2
      UNION ALL SELECT 'breaker', 0, 3) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E08';

-- E02 - Riesgo de cortocircuito  (Crítica, FC 92 %)
--   If  no hay olor a quemado en tomas ni en el tablero eléctrico
--   And se presentan chispas al conectar o desconectar un electrodoméstico
--   And hay cables visiblemente expuestos o deteriorados
--   Then el sistema determina: Riesgo de cortocircuito
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'chispas', 1, 2
      UNION ALL SELECT 'cables', 1, 3) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E02';

-- E09 - Desgaste de contactos en la toma o la clavija  (Alta, FC 78 %)
--   If  no hay olor a quemado en tomas ni en el tablero eléctrico
--   And se presentan chispas al conectar o desconectar un electrodoméstico
--   And no hay cables expuestos ni deteriorados
--   Then el sistema determina: Desgaste de contactos en la toma o la clavija
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'chispas', 1, 2
      UNION ALL SELECT 'cables', 0, 3) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E09';

-- E07 - Deterioro de la instalación eléctrica  (Media, FC 78 %)
--   If  no hay olor a quemado en tomas ni en el tablero eléctrico
--   And no se presentan chispas al conectar o desconectar un electrodoméstico
--   And hay cables visiblemente expuestos o deteriorados
--   Then el sistema determina: Deterioro de la instalación eléctrica
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'chispas', 0, 2
      UNION ALL SELECT 'cables', 1, 3) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E07';

-- E06 - Corto en la instalación  (Alta, FC 85 %)
--   If  no hay olor a quemado en tomas ni en el tablero eléctrico
--   And no se presentan chispas al conectar o desconectar un electrodoméstico
--   And no hay cables expuestos ni deteriorados
--   And se presentan cortocircuitos frecuentes
--   And el disyuntor (breaker) se dispara con frecuencia
--   Then el sistema determina: Corto en la instalación
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'chispas', 0, 2
      UNION ALL SELECT 'cables', 0, 3
      UNION ALL SELECT 'cortos', 1, 4
      UNION ALL SELECT 'breaker', 1, 5) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E06';

-- E10 - Protección del circuito deficiente  (Alta, FC 70 %)
--   If  no hay olor a quemado en tomas ni en el tablero eléctrico
--   And no se presentan chispas al conectar o desconectar un electrodoméstico
--   And no hay cables expuestos ni deteriorados
--   And se presentan cortocircuitos frecuentes
--   And el disyuntor (breaker) no se dispara con frecuencia
--   Then el sistema determina: Protección del circuito deficiente
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'chispas', 0, 2
      UNION ALL SELECT 'cables', 0, 3
      UNION ALL SELECT 'cortos', 1, 4
      UNION ALL SELECT 'breaker', 0, 5) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E10';

-- E12 - Conexión deficiente o sobrecarga en enchufe o interruptor  (Alta, FC 77 %)
--   If  no hay olor a quemado en tomas ni en el tablero eléctrico
--   And no se presentan chispas al conectar o desconectar un electrodoméstico
--   And no hay cables expuestos ni deteriorados
--   And no se presentan cortocircuitos frecuentes
--   And hay sobrecalentamiento de enchufes o interruptores
--   Then el sistema determina: Conexión deficiente o sobrecarga en enchufe o interruptor
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'chispas', 0, 2
      UNION ALL SELECT 'cables', 0, 3
      UNION ALL SELECT 'cortos', 0, 4
      UNION ALL SELECT 'sobrecalentamiento', 1, 5) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E12';

-- E03 - Fluctuación de voltaje o falla de conexión  (Media, FC 72 %)
--   If  no hay olor a quemado en tomas ni en el tablero eléctrico
--   And no se presentan chispas al conectar o desconectar un electrodoméstico
--   And no hay cables expuestos ni deteriorados
--   And no se presentan cortocircuitos frecuentes
--   And no hay sobrecalentamiento de enchufes ni interruptores
--   And hay parpadeo constante de las luces
--   Then el sistema determina: Fluctuación de voltaje o falla de conexión
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'chispas', 0, 2
      UNION ALL SELECT 'cables', 0, 3
      UNION ALL SELECT 'cortos', 0, 4
      UNION ALL SELECT 'sobrecalentamiento', 0, 5
      UNION ALL SELECT 'parpadeo', 1, 6) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E03';

-- E11 - Sobrecarga por uso simultáneo de equipos  (Media, FC 72 %)
--   If  no hay olor a quemado en tomas ni en el tablero eléctrico
--   And no se presentan chispas al conectar o desconectar un electrodoméstico
--   And no hay cables expuestos ni deteriorados
--   And no se presentan cortocircuitos frecuentes
--   And no hay sobrecalentamiento de enchufes ni interruptores
--   And no hay parpadeo constante de las luces
--   And el disyuntor (breaker) se dispara con frecuencia
--   Then el sistema determina: Sobrecarga por uso simultáneo de equipos
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'chispas', 0, 2
      UNION ALL SELECT 'cables', 0, 3
      UNION ALL SELECT 'cortos', 0, 4
      UNION ALL SELECT 'sobrecalentamiento', 0, 5
      UNION ALL SELECT 'parpadeo', 0, 6
      UNION ALL SELECT 'breaker', 1, 7) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E11';

-- E04 - Fallo puntual en toma de corriente  (Baja, FC 75 %)
--   If  no hay olor a quemado en tomas ni en el tablero eléctrico
--   And no se presentan chispas al conectar o desconectar un electrodoméstico
--   And no hay cables expuestos ni deteriorados
--   And no se presentan cortocircuitos frecuentes
--   And no hay sobrecalentamiento de enchufes ni interruptores
--   And no hay parpadeo constante de las luces
--   And el disyuntor (breaker) no se dispara con frecuencia
--   And hay tomas de corriente que dejan de funcionar
--   Then el sistema determina: Fallo puntual en toma de corriente
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_quemado' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'chispas', 0, 2
      UNION ALL SELECT 'cables', 0, 3
      UNION ALL SELECT 'cortos', 0, 4
      UNION ALL SELECT 'sobrecalentamiento', 0, 5
      UNION ALL SELECT 'parpadeo', 0, 6
      UNION ALL SELECT 'breaker', 0, 7
      UNION ALL SELECT 'tomas', 1, 8) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'E04';

-- ===== Rama Hidráulica =====

-- H01 - Fuga activa en tubería de suministro  (Alta, FC 90 %)
--   If  hay fuga visible en tuberías o conexiones
--   And hay manchas de humedad bajo el lavamanos o el fregadero
--   Then el sistema determina: Fuga activa en tubería de suministro
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'fuga_visible' AS cod_pregunta, 1 AS valor, 1 AS orden
      UNION ALL SELECT 'humedad_lavamanos', 1, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'H01';

-- H08 - Fuga localizada en conexión o accesorio  (Media, FC 80 %)
--   If  hay fuga visible en tuberías o conexiones
--   And no hay manchas de humedad bajo el lavamanos ni el fregadero
--   Then el sistema determina: Fuga localizada en conexión o accesorio
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'fuga_visible' AS cod_pregunta, 1 AS valor, 1 AS orden
      UNION ALL SELECT 'humedad_lavamanos', 0, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'H08';

-- H06 - Contaminación o corrosión en la tubería  (Alta, FC 80 %)
--   If  no hay fuga visible en tuberías ni conexiones
--   And el agua sale con color, olor o turbidez inusual
--   Then el sistema determina: Contaminación o corrosión en la tubería
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'fuga_visible' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'agua_color', 1, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'H06';

-- H07 - Fuga oculta en conexión de desagüe  (Media, FC 76 %)
--   If  no hay fuga visible en tuberías ni conexiones
--   And el agua no presenta color, olor ni turbidez inusual
--   And hay manchas de humedad bajo el lavamanos o el fregadero
--   And hay mal olor proveniente de los desagües
--   Then el sistema determina: Fuga oculta en conexión de desagüe
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'fuga_visible' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'agua_color', 0, 2
      UNION ALL SELECT 'humedad_lavamanos', 1, 3
      UNION ALL SELECT 'mal_olor_desague', 1, 4) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'H07';

-- H09 - Filtración en conexión de suministro bajo el mueble  (Media, FC 70 %)
--   If  no hay fuga visible en tuberías ni conexiones
--   And el agua no presenta color, olor ni turbidez inusual
--   And hay manchas de humedad bajo el lavamanos o el fregadero
--   And no hay mal olor proveniente de los desagües
--   Then el sistema determina: Filtración en conexión de suministro bajo el mueble
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'fuga_visible' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'agua_color', 0, 2
      UNION ALL SELECT 'humedad_lavamanos', 1, 3
      UNION ALL SELECT 'mal_olor_desague', 0, 4) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'H09';

-- H04 - Taponamiento en la red de desagüe  (Media, FC 82 %)
--   If  no hay fuga visible en tuberías ni conexiones
--   And el agua no presenta color, olor ni turbidez inusual
--   And no hay manchas de humedad bajo el lavamanos ni el fregadero
--   And hay obstrucción o lentitud en los desagües
--   And hay mal olor proveniente de los desagües
--   Then el sistema determina: Taponamiento en la red de desagüe
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'fuga_visible' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'agua_color', 0, 2
      UNION ALL SELECT 'humedad_lavamanos', 0, 3
      UNION ALL SELECT 'obstruccion', 1, 4
      UNION ALL SELECT 'mal_olor_desague', 1, 5) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'H04';

-- H10 - Obstrucción localizada en sifón o desagüe  (Baja, FC 75 %)
--   If  no hay fuga visible en tuberías ni conexiones
--   And el agua no presenta color, olor ni turbidez inusual
--   And no hay manchas de humedad bajo el lavamanos ni el fregadero
--   And hay obstrucción o lentitud en los desagües
--   And no hay mal olor proveniente de los desagües
--   Then el sistema determina: Obstrucción localizada en sifón o desagüe
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'fuga_visible' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'agua_color', 0, 2
      UNION ALL SELECT 'humedad_lavamanos', 0, 3
      UNION ALL SELECT 'obstruccion', 1, 4
      UNION ALL SELECT 'mal_olor_desague', 0, 5) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'H10';

-- H02 - Obstrucción parcial o sedimentación  (Media, FC 68 %)
--   If  no hay fuga visible en tuberías ni conexiones
--   And el agua no presenta color, olor ni turbidez inusual
--   And no hay manchas de humedad bajo el lavamanos ni el fregadero
--   And no hay obstrucción ni lentitud en los desagües
--   And hay baja presión de agua en uno o varios puntos
--   Then el sistema determina: Obstrucción parcial o sedimentación
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'fuga_visible' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'agua_color', 0, 2
      UNION ALL SELECT 'humedad_lavamanos', 0, 3
      UNION ALL SELECT 'obstruccion', 0, 4
      UNION ALL SELECT 'baja_presion', 1, 5) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'H02';

-- H03 - Golpe de ariete o aire atrapado  (Baja, FC 70 %)
--   If  no hay fuga visible en tuberías ni conexiones
--   And el agua no presenta color, olor ni turbidez inusual
--   And no hay manchas de humedad bajo el lavamanos ni el fregadero
--   And no hay obstrucción ni lentitud en los desagües
--   And no hay baja presión de agua
--   And hay ruidos (golpeteo) en las tuberías al abrir o cerrar llaves
--   Then el sistema determina: Golpe de ariete o aire atrapado
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'fuga_visible' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'agua_color', 0, 2
      UNION ALL SELECT 'humedad_lavamanos', 0, 3
      UNION ALL SELECT 'obstruccion', 0, 4
      UNION ALL SELECT 'baja_presion', 0, 5
      UNION ALL SELECT 'golpeteo', 1, 6) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'H03';

-- H05 - Empaque o válvula desgastada  (Baja, FC 74 %)
--   If  no hay fuga visible en tuberías ni conexiones
--   And el agua no presenta color, olor ni turbidez inusual
--   And no hay manchas de humedad bajo el lavamanos ni el fregadero
--   And no hay obstrucción ni lentitud en los desagües
--   And no hay baja presión de agua
--   And no hay ruidos ni golpeteo en las tuberías
--   And hay goteo constante en grifos o llaves de paso
--   Then el sistema determina: Empaque o válvula desgastada
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'fuga_visible' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'agua_color', 0, 2
      UNION ALL SELECT 'humedad_lavamanos', 0, 3
      UNION ALL SELECT 'obstruccion', 0, 4
      UNION ALL SELECT 'baja_presion', 0, 5
      UNION ALL SELECT 'golpeteo', 0, 6
      UNION ALL SELECT 'goteo', 1, 7) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'H05';

-- H11 - Sifón seco o ventilación deficiente del desagüe  (Baja, FC 72 %)
--   If  no hay fuga visible en tuberías ni conexiones
--   And el agua no presenta color, olor ni turbidez inusual
--   And no hay manchas de humedad bajo el lavamanos ni el fregadero
--   And no hay obstrucción ni lentitud en los desagües
--   And no hay baja presión de agua
--   And no hay ruidos ni golpeteo en las tuberías
--   And no hay goteo en grifos ni llaves de paso
--   And hay mal olor proveniente de los desagües
--   Then el sistema determina: Sifón seco o ventilación deficiente del desagüe
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'fuga_visible' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'agua_color', 0, 2
      UNION ALL SELECT 'humedad_lavamanos', 0, 3
      UNION ALL SELECT 'obstruccion', 0, 4
      UNION ALL SELECT 'baja_presion', 0, 5
      UNION ALL SELECT 'golpeteo', 0, 6
      UNION ALL SELECT 'goteo', 0, 7
      UNION ALL SELECT 'mal_olor_desague', 1, 8) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'H11';

-- ===== Rama Estructural =====

-- S03 - Riesgo de falla en la cimentación  (Crítica, FC 92 %)
--   If  hay hundimiento o desnivel perceptible en el piso
--   And hay inclinación visible en muros o columnas
--   Then el sistema determina: Riesgo de falla en la cimentación
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'hundimiento' AS cod_pregunta, 1 AS valor, 1 AS orden
      UNION ALL SELECT 'inclinacion', 1, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'S03';

-- S07 - Asentamiento del piso o falla del contrapiso  (Alta, FC 80 %)
--   If  hay hundimiento o desnivel perceptible en el piso
--   And no hay inclinación visible en muros ni columnas
--   Then el sistema determina: Asentamiento del piso o falla del contrapiso
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'hundimiento' AS cod_pregunta, 1 AS valor, 1 AS orden
      UNION ALL SELECT 'inclinacion', 0, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'S07';

-- S01 - Asentamiento diferencial de la estructura  (Alta, FC 85 %)
--   If  no hay hundimiento ni desnivel perceptible en el piso
--   And hay grietas diagonales en paredes
--   And hay puertas o ventanas que dejan de cerrar correctamente
--   Then el sistema determina: Asentamiento diferencial de la estructura
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'hundimiento' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'grietas_diagonales', 1, 2
      UNION ALL SELECT 'puertas', 1, 3) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'S01';

-- S08 - Grietas por movimiento estructural localizado  (Media, FC 74 %)
--   If  no hay hundimiento ni desnivel perceptible en el piso
--   And hay grietas diagonales en paredes
--   And las puertas y ventanas cierran correctamente
--   Then el sistema determina: Grietas por movimiento estructural localizado
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'hundimiento' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'grietas_diagonales', 1, 2
      UNION ALL SELECT 'puertas', 0, 3) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'S08';

-- S06 - Desplome estructural incipiente  (Alta, FC 80 %)
--   If  no hay hundimiento ni desnivel perceptible en el piso
--   And no hay grietas diagonales en paredes
--   And hay inclinación visible en muros o columnas
--   Then el sistema determina: Desplome estructural incipiente
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'hundimiento' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'grietas_diagonales', 0, 2
      UNION ALL SELECT 'inclinacion', 1, 3) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'S06';

-- S09 - Fisuración de muros por retracción o cargas  (Media, FC 70 %)
--   If  no hay hundimiento ni desnivel perceptible en el piso
--   And no hay grietas diagonales en paredes
--   And no hay inclinación visible en muros ni columnas
--   And hay grietas verticales u horizontales en paredes
--   Then el sistema determina: Fisuración de muros por retracción o cargas
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'hundimiento' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'grietas_diagonales', 0, 2
      UNION ALL SELECT 'inclinacion', 0, 3
      UNION ALL SELECT 'grietas_vh', 1, 4) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'S09';

-- S04 - Humedad capilar en cimientos  (Media, FC 73 %)
--   If  no hay hundimiento ni desnivel perceptible en el piso
--   And no hay grietas diagonales en paredes
--   And no hay inclinación visible en muros ni columnas
--   And no hay grietas verticales ni horizontales en paredes
--   And hay humedad ascendente en la base de los muros o cimientos
--   Then el sistema determina: Humedad capilar en cimientos
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'hundimiento' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'grietas_diagonales', 0, 2
      UNION ALL SELECT 'inclinacion', 0, 3
      UNION ALL SELECT 'grietas_vh', 0, 4
      UNION ALL SELECT 'humedad_ascendente', 1, 5) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'S04';

-- S02 - Fisuras superficiales por contracción  (Baja, FC 70 %)
--   If  no hay hundimiento ni desnivel perceptible en el piso
--   And no hay grietas diagonales en paredes
--   And no hay inclinación visible en muros ni columnas
--   And no hay grietas verticales ni horizontales en paredes
--   And no hay humedad ascendente en la base de los muros ni cimientos
--   And hay grietas o fisuras finas visibles en el techo o placa
--   Then el sistema determina: Fisuras superficiales por contracción
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'hundimiento' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'grietas_diagonales', 0, 2
      UNION ALL SELECT 'inclinacion', 0, 3
      UNION ALL SELECT 'grietas_vh', 0, 4
      UNION ALL SELECT 'humedad_ascendente', 0, 5
      UNION ALL SELECT 'fisuras_techo', 1, 6) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'S02';

-- S05 - Deterioro superficial del recubrimiento  (Baja, FC 72 %)
--   If  no hay hundimiento ni desnivel perceptible en el piso
--   And no hay grietas diagonales en paredes
--   And no hay inclinación visible en muros ni columnas
--   And no hay grietas verticales ni horizontales en paredes
--   And no hay humedad ascendente en la base de los muros ni cimientos
--   And no hay grietas ni fisuras visibles en el techo ni la placa
--   And hay desprendimiento de revoque, pañete o recubrimiento
--   Then el sistema determina: Deterioro superficial del recubrimiento
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'hundimiento' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'grietas_diagonales', 0, 2
      UNION ALL SELECT 'inclinacion', 0, 3
      UNION ALL SELECT 'grietas_vh', 0, 4
      UNION ALL SELECT 'humedad_ascendente', 0, 5
      UNION ALL SELECT 'fisuras_techo', 0, 6
      UNION ALL SELECT 'panete', 1, 7) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'S05';

-- S10 - Desajuste de la carpintería de puertas o ventanas  (Baja, FC 68 %)
--   If  no hay hundimiento ni desnivel perceptible en el piso
--   And no hay grietas diagonales en paredes
--   And no hay inclinación visible en muros ni columnas
--   And no hay grietas verticales ni horizontales en paredes
--   And no hay humedad ascendente en la base de los muros ni cimientos
--   And no hay grietas ni fisuras visibles en el techo ni la placa
--   And no hay desprendimiento de revoque, pañete ni recubrimiento
--   And hay puertas o ventanas que dejan de cerrar correctamente
--   Then el sistema determina: Desajuste de la carpintería de puertas o ventanas
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'hundimiento' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'grietas_diagonales', 0, 2
      UNION ALL SELECT 'inclinacion', 0, 3
      UNION ALL SELECT 'grietas_vh', 0, 4
      UNION ALL SELECT 'humedad_ascendente', 0, 5
      UNION ALL SELECT 'fisuras_techo', 0, 6
      UNION ALL SELECT 'panete', 0, 7
      UNION ALL SELECT 'puertas', 1, 8) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'S10';

-- ===== Rama Humedad =====

-- M01 - Filtración activa desde la cubierta  (Alta, FC 83 %)
--   If  hay manchas de humedad en techos o paredes
--   And hay presencia visible de moho u hongos
--   Then el sistema determina: Filtración activa desde la cubierta
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'manchas' AS cod_pregunta, 1 AS valor, 1 AS orden
      UNION ALL SELECT 'moho', 1, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'M01';

-- M05 - Filtración incipiente o fuga en tubería empotrada  (Media, FC 74 %)
--   If  hay manchas de humedad en techos o paredes
--   And no hay presencia visible de moho ni hongos
--   Then el sistema determina: Filtración incipiente o fuga en tubería empotrada
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'manchas' AS cod_pregunta, 1 AS valor, 1 AS orden
      UNION ALL SELECT 'moho', 0, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'M05';

-- M04 - Humedad ambiental elevada  (Media, FC 71 %)
--   If  no hay manchas de humedad en techos ni paredes
--   And hay presencia visible de moho u hongos
--   Then el sistema determina: Humedad ambiental elevada
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'manchas' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'moho', 1, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'M04';

-- M02 - Humedad acumulada bajo el recubrimiento  (Media, FC 75 %)
--   If  no hay manchas de humedad en techos ni paredes
--   And no hay presencia visible de moho ni hongos
--   And hay pintura descascarada, ampollada o desprendida
--   And hay olor persistente a humedad o encierro
--   Then el sistema determina: Humedad acumulada bajo el recubrimiento
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'manchas' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'moho', 0, 2
      UNION ALL SELECT 'pintura', 1, 3
      UNION ALL SELECT 'olor_humedad', 1, 4) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'M02';

-- M06 - Deterioro del acabado por humedad residual  (Baja, FC 65 %)
--   If  no hay manchas de humedad en techos ni paredes
--   And no hay presencia visible de moho ni hongos
--   And hay pintura descascarada, ampollada o desprendida
--   And no hay olor persistente a humedad ni encierro
--   Then el sistema determina: Deterioro del acabado por humedad residual
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'manchas' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'moho', 0, 2
      UNION ALL SELECT 'pintura', 1, 3
      UNION ALL SELECT 'olor_humedad', 0, 4) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'M06';

-- M03 - Ventilación insuficiente o puente térmico  (Baja, FC 68 %)
--   If  no hay manchas de humedad en techos ni paredes
--   And no hay presencia visible de moho ni hongos
--   And no hay pintura descascarada, ampollada ni desprendida
--   And hay condensación recurrente en ventanas o superficies frías
--   Then el sistema determina: Ventilación insuficiente o puente térmico
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'manchas' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'moho', 0, 2
      UNION ALL SELECT 'pintura', 0, 3
      UNION ALL SELECT 'condensacion', 1, 4) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'M03';

-- M07 - Humedad oculta o ventilación insuficiente  (Baja, FC 66 %)
--   If  no hay manchas de humedad en techos ni paredes
--   And no hay presencia visible de moho ni hongos
--   And no hay pintura descascarada, ampollada ni desprendida
--   And no hay condensación recurrente en ventanas ni superficies frías
--   And hay olor persistente a humedad o encierro
--   Then el sistema determina: Humedad oculta o ventilación insuficiente
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'manchas' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'moho', 0, 2
      UNION ALL SELECT 'pintura', 0, 3
      UNION ALL SELECT 'condensacion', 0, 4
      UNION ALL SELECT 'olor_humedad', 1, 5) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'M07';

-- ===== Rama Gas =====

-- G01 - Fuga activa de gas  (Crítica, FC 95 %)
--   If  hay olor característico a gas dentro de la vivienda
--   And hay silbido audible cerca de tuberías o conexiones de gas
--   Then el sistema determina: Fuga activa de gas
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_gas' AS cod_pregunta, 1 AS valor, 1 AS orden
      UNION ALL SELECT 'silbido', 1, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'G01';

-- G04 - Fuga leve de gas  (Crítica, FC 82 %)
--   If  hay olor característico a gas dentro de la vivienda
--   And no hay silbido audible cerca de tuberías ni conexiones de gas
--   Then el sistema determina: Fuga leve de gas
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_gas' AS cod_pregunta, 1 AS valor, 1 AS orden
      UNION ALL SELECT 'silbido', 0, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'G04';

-- G05 - Fuga en conexión no detectada por el olfato  (Crítica, FC 88 %)
--   If  no hay olor característico a gas dentro de la vivienda
--   And hay silbido audible cerca de tuberías o conexiones de gas
--   And hay un aumento inusual en el consumo de gas sin justificación aparente
--   Then el sistema determina: Fuga en conexión no detectada por el olfato
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_gas' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'silbido', 1, 2
      UNION ALL SELECT 'consumo_gas', 1, 3) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'G05';

-- G06 - Posible fuga en conexión de gas  (Crítica, FC 80 %)
--   If  no hay olor característico a gas dentro de la vivienda
--   And hay silbido audible cerca de tuberías o conexiones de gas
--   And no hay un aumento inusual en el consumo de gas
--   Then el sistema determina: Posible fuga en conexión de gas
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_gas' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'silbido', 1, 2
      UNION ALL SELECT 'consumo_gas', 0, 3) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'G06';

-- G03 - Posible fuga menor no perceptible  (Alta, FC 74 %)
--   If  no hay olor característico a gas dentro de la vivienda
--   And no hay silbido audible cerca de tuberías ni conexiones de gas
--   And hay un aumento inusual en el consumo de gas sin justificación aparente
--   Then el sistema determina: Posible fuga menor no perceptible
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_gas' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'silbido', 0, 2
      UNION ALL SELECT 'consumo_gas', 1, 3) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'G03';

-- G02 - Combustión incompleta o quemador desajustado  (Media, FC 78 %)
--   If  no hay olor característico a gas dentro de la vivienda
--   And no hay silbido audible cerca de tuberías ni conexiones de gas
--   And no hay un aumento inusual en el consumo de gas
--   And la llama de la estufa es de color amarillo o naranja en lugar de azul
--   Then el sistema determina: Combustión incompleta o quemador desajustado
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'olor_gas' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'silbido', 0, 2
      UNION ALL SELECT 'consumo_gas', 0, 3
      UNION ALL SELECT 'llama_amarilla', 1, 4) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'G02';

-- ===== Rama Confort térmico =====

-- C01 - Sellado deficiente de marcos  (Baja, FC 70 %)
--   If  hay corrientes de aire perceptibles alrededor de ventanas o puertas
--   Then el sistema determina: Sellado deficiente de marcos
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'corrientes_aire' AS cod_pregunta, 1 AS valor, 1 AS orden) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'C01';

-- C02 - Aislamiento térmico insuficiente  (Baja, FC 65 %)
--   If  no hay corrientes de aire perceptibles alrededor de ventanas ni puertas
--   And hay diferencias notorias de temperatura entre habitaciones
--   Then el sistema determina: Aislamiento térmico insuficiente
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'corrientes_aire' AS cod_pregunta, 0 AS valor, 1 AS orden
      UNION ALL SELECT 'diferencia_temp', 1, 2) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'C02';

-- ===== Rama Confort acústico =====

-- C03 - Aislamiento acústico insuficiente  (Baja, FC 65 %)
--   If  hay ingreso excesivo de ruido exterior
--   Then el sistema determina: Aislamiento acústico insuficiente
INSERT INTO respuesta (id_hipotesis, id_pregunta, valor_respuesta, orden)
SELECT h.id_hipotesis, p.id_pregunta, v.valor, v.orden
FROM (SELECT 'ruido_exterior' AS cod_pregunta, 1 AS valor, 1 AS orden) v
JOIN pregunta  p ON p.codigo = v.cod_pregunta
JOIN hipotesis h ON h.codigo = 'C03';


-- ---------------------------------------------------------------------
-- 5. Verificacion de la carga
--    Esperado: 7 categorias, 36 preguntas, 49 hipotesis, 190 respuestas,
--    y ninguna hipotesis sin respuestas.
-- ---------------------------------------------------------------------
SELECT 'categorias' AS elemento, COUNT(*) AS total FROM categoria
UNION ALL SELECT 'preguntas',  COUNT(*) FROM pregunta
UNION ALL SELECT 'hipotesis',  COUNT(*) FROM hipotesis
UNION ALL SELECT 'respuestas', COUNT(*) FROM respuesta
UNION ALL SELECT 'hipotesis sin respuestas', COUNT(*)
          FROM hipotesis h
          WHERE NOT EXISTS (SELECT 1 FROM respuesta r WHERE r.id_hipotesis = h.id_hipotesis);
