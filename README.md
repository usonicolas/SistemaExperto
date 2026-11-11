# Sistema experto de diagnóstico de vivienda · Aplicación web

Aplicación del proyecto de Sistemas Expertos (Universidad Manuela Beltrán, 2026). Orienta al habitante
de una vivienda ante una falla eléctrica, hidráulica, estructural, de humedad, de gas o de confort:
le hace preguntas Sí/No, calcula con un motor de inferencia bayesiano las hipótesis más probables y
entrega el diagnóstico con su urgencia, la acción recomendada y el especialista sugerido.

La aplicación **no tiene un rol de administrador**. Cualquier persona se registra como consultante con
sus datos de cliente, asocia una o varias viviendas, diagnostica y lleva el historial de sus atenciones;
solo ve su propia información. La base de conocimiento (preguntas, hipótesis y gránulos) se carga y se
actualiza con los scripts SQL de la carpeta `bd/`: la aplicación solo la lee, no muestra el árbol de
decisión ni las reglas y no permite modificar el conocimiento. Las cuentas de ingeniero de conocimiento
existen en la tabla `usuario` (rol `INGENIERO_CONOCIMIENTO`), pero no ingresan a la aplicación.

```
Navegador ──HTMX──▶ presentacion/   Controladores FastAPI y vistas Jinja2
                        │
                        ▼
                    negocio/        MotorBayesiano · MotorProlog (SWI-Prolog vía Janus) · servicios
                        │  (interfaces DAO de datos/dao.py)
                        ▼
                    datos/          FabricaDAOMySQL ──▶ DAO MySQL ──▶ se_base_conocimiento + se_transaccional
```

- **El conocimiento no está en el código** (RNF19). Las reglas, sus antecedentes If/And y sus factores
  de certeza se leen de MySQL con consultas parametrizadas.
- **Inferencia bayesiana con consultas granulares.** Tras cada respuesta, `MotorBayesiano` consulta el
  gránulo de la pregunta respondida (qué hipótesis la usan y qué respuesta espera cada una), actualiza
  la probabilidad de cada hipótesis con el teorema de Bayes y elige la siguiente pregunta por ganancia
  de información. Al concluir guarda las 5 hipótesis más probables con su peso y la hipótesis H0,
  «sin falla identificable» (conclusión por defecto, RNF22).
- **Prolog confirma la conclusión.** `prolog/motor.pl` verifica de forma lógica que la regla ganadora se
  cumpla con las respuestas dadas y entrega su explicación If/And/Then.
- **Patrón DAO.** La capa de negocio depende de las interfaces de `datos/dao.py`; `FabricaDAOMySQL` crea
  las implementaciones MySQL y abre las transacciones (unidad de trabajo).

## Requisitos

| Herramienta | Versión probada |
|---|---|
| Python | 3.13 |
| SWI-Prolog | 10.0.2 (en `C:\Program Files\swipl`) |
| MySQL | 8.4 en Docker (contenedor `se-mysql`) |
| Node.js | solo para recompilar los estilos |

## Puesta en marcha

Todos los comandos se ejecutan desde la carpeta `aplicacion`.

1. **Encender MySQL** y crear las bases ejecutando en orden los scripts de `bd/`:
   `01_base_conocimiento.sql`, `02_transaccional.sql`, `03_carga_conocimiento.sql` y
   `04_consultas_granulos.sql`. El script `05_capturas_workbench.sql` es opcional.

2. **Crear el entorno de Python** (solo la primera vez):

   ```bash
   python -m venv .venv
   .venv\Scripts\python -m pip install -r requirements.txt
   ```

3. **Configurar la conexión.** Cree `.env` en esta carpeta con `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`,
   `MYSQL_PASSWORD`, `SECRET_KEY` y `SEED_PASSWORD` (ver la sección A.3 del manual técnico). El archivo
   no se sube al repositorio.

4. **Crear el usuario de prueba** `consulta`, con su cliente y una vivienda. Su contraseña es el valor
   `SEED_PASSWORD` de `.env`:

   ```bash
   .venv\Scripts\python -m scripts.semilla
   ```

5. **Iniciar la aplicación:**

   ```bash
   .venv\Scripts\python -m uvicorn se_app.main:app --reload --port 8000
   ```

   Abra http://127.0.0.1:8000, cree una cuenta en «Registrarse» o ingrese con el usuario de prueba.

## Pruebas

```bash
.venv\Scripts\python -m pytest -q tests
```

Son 41 pruebas. Las unitarias del motor bayesiano y del motor Prolog no necesitan MySQL: usan
`ConocimientoDAOMemoria`, una implementación en memoria de la interfaz `ConocimientoDAO`. Con MySQL
encendido recorren además la ruta de cada una de las 49 reglas, la conclusión por defecto en las 7
categorías, los 12 casos del plan de validación del manual, el registro y el ingreso, y una atención completa.

| Archivo | Pruebas |
|---|---|
| `test_inferencia_bayesiana.py` | 22 |
| `test_motor_reglas.py` | 6 |
| `test_clientes.py` | 7 |
| `test_usuarios.py` | 6 |

## Respaldos

```bash
.venv\Scripts\python -m scripts.respaldo
```

Exporta los dos esquemas con `mysqldump` a `respaldos/` y borra las copias de más de 30 días (RNF14).

## Estilos

```bash
npx tailwindcss@3.4.16 -i estilos/app.css -o se_app/presentacion/static/css/app.css --minify
```

Recompile después de agregar clases nuevas en las plantillas. HTMX 2.0.4 está en
`se_app/presentacion/static/js/htmx.min.js`.

## Estructura

```
aplicacion/
├── bd/                              Scripts SQL 01 a 05 (estructura, carga del conocimiento y consultas)
├── prolog/motor.pl                  Motor de reglas (SWI-Prolog): confirmación y explicación
├── se_app/
│   ├── main.py                      Punto de entrada (uvicorn se_app.main:app)
│   ├── config.py                    Configuración leída de los archivos .env
│   ├── contenedor.py                Raíz de composición: crea e inyecta las tres capas
│   ├── presentacion/                CAPA DE PRESENTACIÓN
│   │   ├── app.py                   Crea FastAPI, registra los controladores y los errores
│   │   ├── vistas.py                Render de plantillas y redirecciones HTMX
│   │   ├── seguridad_web.py         Sesión obligatoria en las rutas protegidas
│   │   ├── controladores/           Controlador base: sesión, clientes y viviendas, diagnóstico
│   │   ├── templates/               Pantallas Jinja2
│   │   └── static/                  CSS compilado, HTMX y animación del inicio de sesión
│   ├── negocio/                     CAPA DE NEGOCIO
│   │   ├── modelos.py               Entidades y DTO: Hipotesis, Pregunta, Antecedente, Evidencia, Distribucion…
│   │   ├── inferencia_bayesiana.py  MotorBayesiano
│   │   ├── motor_prolog.py          MotorProlog (puente Janus)
│   │   ├── servicio_*.py            Diagnóstico, clientes y viviendas, usuarios
│   │   └── errores.py               Excepciones de negocio
│   └── datos/                       CAPA DE DATOS (patrón DAO)
│       ├── dao.py                   Interfaces ConocimientoDAO, UsuarioDAO, ClienteDAO, ViviendaDAO, AtencionDAO
│       ├── conexion.py              BaseDatos: pool de conexiones y transacciones
│       └── mysql/                   Implementaciones MySQL y FabricaDAOMySQL
├── scripts/                         semilla.py, respaldo.py y capturas.py
├── tests/                           41 pruebas automatizadas (pytest)
└── estilos/app.css                  Fuente de Tailwind
```

## Casos de uso

| CU | Pantalla |
|---|---|
| CU01 Gestionar cliente y viviendas | `/registro` (público), `/viviendas` |
| CU02 Diagnosticar falla | `/diagnostico/nuevo` → preguntas Sí/No elegidas por ganancia de información |
| CU03 Emitir alerta de riesgo crítico | Banner rojo con las acciones inmediatas en el reporte |
| CU04 Generar reporte de hipótesis ponderadas | `/diagnostico/{id}/reporte` (Descargar PDF = imprimir) |
| CU05 Consultar historial | `/historial` con filtros por vivienda, categoría y zona |
