"""Raiz de composicion: crea las instancias de las tres capas y las conecta.

    presentacion (controladores)  ->  negocio (servicios, motores)  ->  datos (DAO)

Cada capa recibe la siguiente por constructor; ninguna crea sus
dependencias por su cuenta, lo que permite probarlas por separado. La
fabrica de DAO es el unico lugar que conoce las implementaciones MySQL.
"""
from .datos.mysql.fabrica import FabricaDAOMySQL
from .negocio.inferencia_bayesiana import MotorBayesiano
from .negocio.motor_prolog import MotorProlog
from .negocio.servicio_clientes import ServicioClientes
from .negocio.servicio_diagnostico import ServicioDiagnostico
from .negocio.servicio_usuarios import ServicioUsuarios


class Contenedor:
    def __init__(self):
        # Capa de datos: un DAO por agregado del modelo (el de conocimiento es de solo lectura)
        self.fabrica = FabricaDAOMySQL()
        self.bd = self.fabrica.bd
        self.dao_conocimiento = self.fabrica.conocimiento()
        self.dao_usuarios = self.fabrica.usuarios()
        self.dao_clientes = self.fabrica.clientes()
        self.dao_viviendas = self.fabrica.viviendas()
        self.dao_atenciones = self.fabrica.atenciones()
        # Capa de negocio: el paquete sistema experto (motores) y los servicios de cada gestion
        self.motor_bayesiano = MotorBayesiano(self.dao_conocimiento)
        self.motor_prolog = MotorProlog(self.dao_conocimiento)
        self.diagnostico = ServicioDiagnostico(self.dao_atenciones, self.dao_clientes, self.dao_viviendas,
                                               self.dao_conocimiento, self.motor_bayesiano, self.motor_prolog)
        self.clientes = ServicioClientes(self.dao_clientes, self.dao_viviendas, self.dao_atenciones)
        self.usuarios = ServicioUsuarios(self.dao_usuarios, self.dao_clientes, self.fabrica.transaccion)


contenedor = Contenedor()
