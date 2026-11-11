"""Registro e ingreso de los usuarios (CU01) con acceso seguro (RNF01, RNF02).

La aplicacion no tiene roles ni administrador: cualquier persona se
registra con sus datos de cliente para diagnosticar y llevar el historial
de sus viviendas, y solo ve su propia informacion.
"""
import base64
import hashlib
import hmac
import re
import secrets
from datetime import datetime, timedelta

from .. import config
from .errores import ErrorAcceso, ErrorValidacion
from .modelos import Cliente, Usuario
from .servicio_clientes import validar_cliente


class ServicioUsuarios:
    MIN_CONTRASENA = 8
    _N, _R, _P = 2 ** 14, 8, 1        # parametros de scrypt

    def __init__(self, usuarios, clientes, transaccion):
        # usuarios: UsuarioDAO; clientes: ClienteDAO; transaccion: unidad de trabajo de la capa de datos.
        self.usuarios = usuarios
        self.clientes = clientes
        self.transaccion = transaccion

    # ------------------------------------------------------------ contrasenas (RNF02)

    @classmethod
    def cifrar(cls, contrasena: str) -> str:
        """Resumen scrypt con sal aleatoria; nunca se guarda la contrasena en texto plano."""
        sal = secrets.token_bytes(16)
        resumen = hashlib.scrypt(contrasena.encode(), salt=sal, n=cls._N, r=cls._R, p=cls._P)
        return "scrypt${}${}${}${}${}".format(cls._N, cls._R, cls._P, base64.b64encode(sal).decode(),
                                              base64.b64encode(resumen).decode())

    @staticmethod
    def verificar(contrasena: str, almacenado: str) -> bool:
        try:
            esquema, n, r, p, sal, resumen = almacenado.split("$")
        except ValueError:
            return False          # resumenes de ejemplo del script 04 u otro formato
        if esquema != "scrypt":
            return False
        calculado = hashlib.scrypt(contrasena.encode(), salt=base64.b64decode(sal), n=int(n), r=int(r), p=int(p))
        return hmac.compare_digest(calculado, base64.b64decode(resumen))

    # ------------------------------------------------------------ autenticacion (RNF01)

    def autenticar(self, usuario: str, contrasena: str) -> dict:
        """Valida las credenciales y bloquea la cuenta tras MAX_INTENTOS intentos fallidos."""
        u = self.usuarios.por_usuario(usuario)
        if u is None:
            raise ErrorAcceso("Usuario o contraseña incorrectos.")
        ahora = datetime.now()
        if u.bloqueado_hasta and u.bloqueado_hasta > ahora:
            minutos = int((u.bloqueado_hasta - ahora).total_seconds() // 60) + 1
            raise ErrorAcceso(f"Cuenta bloqueada por intentos fallidos. Intente de nuevo en {minutos} min.")
        if not self.verificar(contrasena, u.contrasena_hash):
            intentos = u.intentos_fallidos + 1
            if intentos >= config.MAX_INTENTOS:
                self.usuarios.bloquear(u.id_usuario, ahora + timedelta(minutes=config.MINUTOS_BLOQUEO))
                raise ErrorAcceso(f"Demasiados intentos fallidos. La cuenta queda bloqueada {config.MINUTOS_BLOQUEO} min.")
            self.usuarios.registrar_intento_fallido(u.id_usuario, intentos)
            raise ErrorAcceso(f"Usuario o contraseña incorrectos. Le quedan {config.MAX_INTENTOS - intentos} intento(s).")
        self.usuarios.desbloquear(u.id_usuario)
        return {"id": u.id_usuario, "usuario": u.usuario, "nombre": u.nombre}

    # ------------------------------------------------------------ registro (CU01)

    def validar(self, d: dict) -> dict:
        """Devuelve {campo: mensaje} con los errores de los datos del usuario."""
        errores = {}
        for campo, nombre in (("nombres", "los nombres"), ("apellidos", "los apellidos"), ("correo", "el correo"),
                              ("usuario", "el usuario")):
            if not d.get(campo):
                errores[campo] = f"Escriba {nombre}."
        if d.get("correo") and not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", d["correo"]):
            errores["correo"] = "El correo no tiene un formato válido."
        if d.get("usuario") and not re.fullmatch(r"[a-zA-Z0-9._-]{3,40}", d["usuario"]):
            errores["usuario"] = "Use entre 3 y 40 letras, números, punto, guion o guion bajo."
        if len(d.get("contrasena", "")) < self.MIN_CONTRASENA:
            errores["contrasena"] = f"La contraseña debe tener al menos {self.MIN_CONTRASENA} caracteres."
        elif d.get("contrasena") != d.get("confirmacion"):
            errores["confirmacion"] = "Las contraseñas no coinciden."
        if not errores.get("usuario") and self.usuarios.existe("usuario", d["usuario"]):
            errores["usuario"] = "Ese nombre de usuario ya está en uso."
        if not errores.get("correo") and self.usuarios.existe("correo", d["correo"].lower()):
            errores["correo"] = "Ya existe una cuenta con ese correo."
        return errores

    def registrar(self, datos: dict) -> dict:
        """Registro publico: crea el usuario y su registro de cliente en una sola transaccion e inicia sesion."""
        errores = self.validar(datos)
        errores.update(validar_cliente(datos, self.clientes))
        if errores:
            raise ErrorValidacion("Revise los campos marcados.", errores)
        with self.transaccion():
            id_usuario = self.usuarios.crear(Usuario(datos["nombres"], datos["apellidos"], datos["correo"],
                                                     datos["usuario"], self.cifrar(datos["contrasena"])))
            self.clientes.crear(Cliente(id_usuario, datos["tipo_documento"], datos["numero_documento"],
                                        datos.get("telefono") or None))
        return self.autenticar(datos["usuario"], datos["contrasena"])
