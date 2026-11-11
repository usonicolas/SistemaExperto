"""Capa de datos: unica capa que habla con MySQL. Sigue el patron DAO.

dao.py declara una interfaz DAO por cada agregado del modelo; mysql/ las
implementa y FabricaDAOMySQL las crea con la conexion compartida
(conexion.BaseDatos). Los DAO devuelven entidades de negocio (DTO) o filas
de consulta para las pantallas; no contienen reglas de negocio ni conocen
la web.
"""
