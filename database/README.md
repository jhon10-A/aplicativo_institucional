# Estructura de db_institucional

`01_estructura.sql` conserva el script proporcionado y añade la creación de la base con `utf8mb4` y `utf8mb4_unicode_ci`. Incluye tablas, relaciones, restricciones e inserciones de los roles ADMINISTRADOR, DOCENTE, ESTUDIANTE y APODERADO.

## Ejecutar una sola vez en una instalación nueva

1. Conectarse en DBeaver a una instalación nueva de MySQL 8.4 en el puerto 3307, con un usuario que tenga permisos para crear la base y sus tablas e insertar los roles.
2. Abrir `01_estructura.sql` como script SQL y seleccionar esa conexión. La base `db_institucional` debe estar ausente o vacía.
3. Ejecutar el script completo una sola vez. El propio script crea y selecciona la base; no requiere editar ni guardar contraseñas en el archivo.
4. Comprobar que la consulta final a `information_schema.tables` devuelve 25 tablas.

No ejecutar sobre la base actual que ya tiene tablas. El script no es idempotente: `CREATE DATABASE IF NOT EXISTS` solo protege la creación de la base; las tablas y las inserciones de roles no están preparadas para repetirse. No es una migración ni un respaldo de datos.

## Alcance del archivo recibido

El script contiene **25 sentencias CREATE TABLE**, todas con clave primaria y motor InnoDB. Todas las tablas referenciadas están definidas. En una base vacía, crea las 25 tablas y los cuatro roles; no incluye cuentas, contraseñas, hashes ni datos personales.

El backend utiliza `jdbc:mysql://localhost:3307/db_institucional`, el driver `com.mysql.cj.jdbc.Driver` y `spring.jpa.hibernate.ddl-auto=validate` para comprobar el esquema sin crear ni alterar tablas. Las credenciales se suministran en el archivo local ignorado o mediante el entorno.

El archivo se comprobó estáticamente; no se ejecutó contra ninguna base de datos.
