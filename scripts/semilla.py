"""Crea o actualiza el usuario de prueba con una contrasena cifrada real.

El script 04_consultas_granulos.sql inserta el usuario de prueba 'consulta'
con un resumen de ejemplo que no sirve para iniciar sesion. Este script le
asigna la contrasena de prueba SEED_PASSWORD (aplicacion/.env), cifrada con
scrypt (RNF02), y le crea su registro de cliente y una vivienda si no los
tiene. El usuario ingeniero que inserta el script 04 no ingresa a la
aplicacion (no hay rol de administrador); cualquier otra persona se registra
como consultante desde la pantalla de registro.

Uso (desde la carpeta aplicacion):
    .venv\\Scripts\\python -m scripts.semilla
"""
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from se_app import config  # noqa: E402
from se_app.datos.mysql.fabrica import FabricaDAOMySQL  # noqa: E402
from se_app.negocio.modelos import Cliente, Usuario, Vivienda  # noqa: E402
from se_app.negocio.servicio_usuarios import ServicioUsuarios  # noqa: E402

USUARIO = ("Usuario", "Consultante", "consulta@ejemplo.test", "consulta", "1000000003")


def contrasena_de_prueba() -> str:
    """SEED_PASSWORD del entorno o de aplicacion/.env, en ese orden."""
    if os.environ.get("SEED_PASSWORD"):
        return os.environ["SEED_PASSWORD"]
    archivo = config.RAIZ_APP / ".env"
    if archivo.exists():
        for linea in archivo.read_text(encoding="utf-8").splitlines():
            if linea.startswith("SEED_PASSWORD=") and linea.split("=", 1)[1].strip():
                return linea.split("=", 1)[1].strip()
    raise SystemExit("Defina SEED_PASSWORD en aplicacion/.env (contraseña del usuario de prueba).")


def main():
    clave = contrasena_de_prueba()
    fabrica = FabricaDAOMySQL()
    usuarios, clientes, viviendas = fabrica.usuarios(), fabrica.clientes(), fabrica.viviendas()
    nombres, apellidos, correo, usuario, documento = USUARIO
    resumen = ServicioUsuarios.cifrar(clave)
    existe = usuarios.por_usuario(usuario)
    if existe:
        usuarios.actualizar_contrasena(existe.id_usuario, resumen)
        id_usuario = existe.id_usuario
    else:
        id_usuario = usuarios.crear(Usuario(nombres, apellidos, correo, usuario, resumen))
    cliente = clientes.por_usuario(id_usuario)
    if cliente is None:
        cliente = Cliente(id_usuario, "CC", documento, "3000000000")
        cliente.id_cliente = clientes.crear(cliente)
    if not viviendas.de_cliente(cliente.id_cliente, incluir_inactivas=True):
        viviendas.crear(Vivienda(cliente.id_cliente, "Casa principal", "Calle 00 # 00-00", "Bogotá", "Casa", 25))
    print(f"Usuario de prueba '{usuario}' listo. La contraseña es SEED_PASSWORD de aplicacion/.env.")


if __name__ == "__main__":
    main()
