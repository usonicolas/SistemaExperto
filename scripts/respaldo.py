"""Copia de seguridad de la base de conocimiento y de la base transaccional (RNF14).

Exporta los esquemas se_base_conocimiento y se_transaccional con mysqldump
a la carpeta aplicacion/respaldos/ (no se sube al repositorio), con la fecha
y la hora en el nombre, y borra las copias de mas de DIAS_RETENCION dias.
Usa el mysqldump del contenedor de MySQL y la conexion de la configuracion
de la aplicacion; la contrasena viaja como variable de entorno, nunca en
la linea de comandos.

Uso (desde la carpeta aplicacion; programable a diario con el Programador
de tareas de Windows):
    .venv\\Scripts\\python -m scripts.respaldo [--contenedor se-mysql]

Restauracion de prueba:
    docker exec -i se-mysql mysql -u root -p < respaldos/<archivo>.sql
"""
import argparse
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from se_app import config  # noqa: E402

DIAS_RETENCION = 30
CARPETA = config.RAIZ_APP / "respaldos"


def respaldar(contenedor: str) -> Path:
    CARPETA.mkdir(exist_ok=True)
    destino = CARPETA / f"respaldo_{datetime.now():%Y%m%d_%H%M%S}.sql"
    orden = ["docker", "exec", "-e", "MYSQL_PWD", contenedor, "mysqldump", "-u", config.MYSQL_USER,
             "--single-transaction", "--routines", "--default-character-set=utf8mb4",
             "--databases", config.ESQUEMA_CONOCIMIENTO, config.ESQUEMA_TRANSACCIONAL]
    entorno = {**os.environ, "MYSQL_PWD": config.MYSQL_PASSWORD}
    with destino.open("wb") as salida:
        r = subprocess.run(orden, stdout=salida, stderr=subprocess.PIPE, env=entorno)
    errores = [l for l in r.stderr.decode("utf-8", "replace").splitlines() if "Using a password" not in l]
    if r.returncode != 0 or destino.stat().st_size == 0:
        destino.unlink(missing_ok=True)
        raise SystemExit("No se pudo generar el respaldo: " + (" ".join(errores) or f"código {r.returncode}"))
    return destino


def depurar() -> list[Path]:
    """Borra los respaldos con mas de DIAS_RETENCION dias."""
    limite = time.time() - DIAS_RETENCION * 86400
    viejos = [f for f in CARPETA.glob("respaldo_*.sql") if f.stat().st_mtime < limite]
    for f in viejos:
        f.unlink()
    return viejos


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--contenedor", default="se-mysql")
    args = parser.parse_args()
    destino = respaldar(args.contenedor)
    print(f"Respaldo creado: {destino.name} ({destino.stat().st_size / 1024:.0f} KB)")
    viejos = depurar()
    if viejos:
        print(f"Se borraron {len(viejos)} respaldos de más de {DIAS_RETENCION} días.")


if __name__ == "__main__":
    main()
