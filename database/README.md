# Estructura de db_institucional

`01_estructura.sql` conserva el script proporcionado y añade la creación de la base con `utf8mb4` y `utf8mb4_unicode_ci`. Incluye tablas, relaciones, restricciones e inserciones de los roles ADMINISTRADOR, DOCENTE, ESTUDIANTE y APODERADO.

## Ejecutar una sola vez en una instalación nueva

1. Conectarse en DBeaver a una instalación nueva de MariaDB (el script original se ejecutó en MariaDB 12.3.2), con un usuario que tenga permisos para crear la base y sus tablas e insertar los roles.
2. Abrir `01_estructura.sql` como script SQL y seleccionar esa conexión. La base `db_institucional` debe estar ausente o vacía.
3. Ejecutar el script completo una sola vez. El propio script crea y selecciona la base; no requiere editar ni guardar contraseñas en el archivo.
4. Revisar los resultados finales de `SHOW TABLES`, el conteo de tablas y `SELECT * FROM rol`.

No ejecutar sobre la base actual que ya tiene tablas. El script no es idempotente: `CREATE DATABASE IF NOT EXISTS` solo protege la creación de la base; las tablas y las inserciones de roles no están preparadas para repetirse. No es una migración ni un respaldo de datos.

## Alcance del archivo recibido

El adjunto contiene **25 sentencias CREATE TABLE**, aunque se informó que la base actual tiene 26 tablas. Se conservó exactamente la estructura recibida, sin inventar una tabla adicional. En una base vacía, este archivo define 25 tablas y los cuatro roles. Si se necesita reproducir una tabla número 26, falta incorporar su definición original.

El archivo se comprobó estáticamente; no se ejecutó contra ninguna base de datos.
