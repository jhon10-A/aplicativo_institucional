# Backend institucional

## Variables locales con .env (PowerShell, sin dependencias nuevas)

Spring Boot lee las variables del entorno del proceso, pero no interpreta `.env` automáticamente. Se mantiene la importación opcional de `config/application-local.properties`, sin cambios al arranque habitual. El cargador siguiente es una alternativa explícita para desarrollo local y no inicia Java ni accede a MySQL.

Desde `backend/`, crear la copia solo si no existe y completarla personalmente en un editor:

```powershell
if (-not (Test-Path -LiteralPath .env)) { Copy-Item .env.example .env }
# Completar .env en privado; no compartir su contenido ni capturas.
& .\scripts\Load-LocalEnv.ps1
.\mvnw.cmd spring-boot:run
```

Ambos comandos deben ejecutarse en la misma terminal. Si se ejecuta el cargador en otro proceso PowerShell, sus variables no llegan a la terminal original. Después de cargarlo también se puede ejecutar `java -jar target/backend-0.0.1-SNAPSHOT.jar` desde `backend/`. La ejecución directa desde el IDE solo usa estas variables si el IDE las recibe en su propio entorno o configuración de ejecución; abrir `.env` no lo carga.

Si PowerShell bloquea los archivos `.ps1`, abrir una sesión autorizada con `powershell -NoProfile -ExecutionPolicy RemoteSigned`, entrar en `backend/` y ejecutar allí los dos comandos anteriores. Esa opción solo afecta al proceso abierto, no cambia permanentemente la política del equipo. No cambiar políticas administradas por la organización. Para probar únicamente el cargador desde una terminal que bloquea scripts: `powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Test-LocalEnv.ps1`.

La prioridad para estas opciones es: variables ya presentes en la terminal, valores no vacíos cargados de `.env`, `application-local.properties` y configuración compartida. Los argumentos de Java/Spring y otras fuentes de mayor prioridad siguen las reglas de Spring Boot. Las entradas vacías de `.env` se ignoran, permitiendo migrar una variable a la vez. Para recargar un valor modificado en `.env`, abrir una terminal nueva sin esa variable predefinida o retirarla explícitamente del entorno del proceso. Cerrar la terminal elimina las variables cargadas de esa sesión.

La plantilla no tiene credenciales. Usuario, contraseña y clave JWT se completan privadamente; una clave JWT debe seguir siendo Base64 de al menos 32 bytes aleatorios. No copiar valores privados a los README, comandos guardados o archivos versionados. `.env` y el archivo local están ignorados y fuera del JAR; `.env.example` sí se comparte. El ejemplo no activa la creación de cuentas.

Formato admitido: una variable permitida por línea, `NOMBRE=valor`, líneas vacías y comentarios de línea completa con `#`. Se admiten comillas simples o dobles exteriores; el contenido es literal, sin expansión de `$`, escapes ni ejecución de comandos. `#` y `=` dentro del valor son literales; no usar comentarios al final ni sintaxis `export`. Se rechazan claves desconocidas, duplicadas o comillas sin cerrar antes de cargar cualquier variable. Los errores solo indican el tipo de problema y número de línea, nunca el contenido.

Variables permitidas: `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, `JWT_SECRET_BASE64`, `APP_CORS_ALLOWED_ORIGIN`, `APP_JWT_TTL_SECONDS` y `SERVER_PORT`. MySQL continúa usando el puerto 3307, `db_institucional` y `ddl-auto=validate`. No se modifica el esquema.

Prueba del cargador sin leer `.env` ni acceder a MySQL: `& .\scripts\Test-LocalEnv.ps1`. Las pruebas usan un archivo temporal con valores ficticios y restauran las variables del proceso.

Prueba completa PowerShell → Maven → Spring: `& .\scripts\Test-SpringLocalEnv.ps1`. Usa las siete variables permitidas con valores ficticios, un archivo de propiedades temporal y un contexto sin `DataSource` ni JPA; comprueba la prioridad del entorno y la conservación de propiedades locales. No lee los archivos privados ni conecta a MySQL. Ejecuta Maven sin red (`--offline`), por lo que requiere Java y las dependencias ya disponibles en la caché local. Restaura las variables del proceso al terminar. La prueba Java de este recorrido solo se activa con el indicador que establece este script.

Si el wrapper falla antes de iniciar Maven, el script admite `-MavenCommand 'ruta\a\bin\mvn.cmd'` para usar una instalación existente. Si Maven resuelve incorrectamente su repositorio local, configurar en esa sesión `MAVEN_OPTS` con `-Dmaven.repo.local=ruta/a/.m2/repository`. Usar Java 21 y una caché preparada; no hace falta modificar el wrapper ni las credenciales.

## Tareas del estudiante: consulta y detalle

- `GET /api/estudiante/matriculas/{matriculaId}/tareas`: tareas activas de todos los cursos de la matrícula, ordenadas por fecha límite e identificador.
- `GET /api/estudiante/matriculas/{matriculaId}/cursos/{asignacionId}/tareas`: mismo listado filtrado por la asignación del curso.
- `GET /api/estudiante/matriculas/{matriculaId}/tareas/{tareaId}`: detalle con la entrega propia, si existe.

Requieren JWT ESTUDIANTE, cuenta activa y rol vigente. La matrícula pertenece al usuario del `sub` y la asignación coincide en periodo y sección. Las tareas inactivas y los recursos inexistentes o ajenos responden 404 `NO_DISPONIBLE`; un usuario sin perfil recibe `SIN_PERFIL`. Una selección propia sin tareas devuelve `[]`. El historial se consulta seleccionando explícitamente la matrícula.

Los DTO incluyen título, descripción y archivo disponibles, curso, docente, fechas de publicación y límite, puntaje máximo y estado de entrega. El estado se deriva de los datos: `PENDIENTE` sin entrega, `ENTREGADA` con entrega sin fecha de revisión y `REVISADA` con fecha de revisión. No se deduce una falta ni una calificación del vencimiento. La entrega contiene únicamente los datos de esa tarea y matrícula: comentario, archivo, fecha de entrega, puntaje y retroalimentación/revisión cuando existen. Las fechas `DATETIME` se devuelven sin inventar una zona horaria.

Se consulta `tarea` mediante `asignacion_docente` y se une `entrega_tarea` por **tarea y matrícula**, también entre compañeros de la misma sección. Las rutas de consulta son de solo lectura con `Cache-Control: no-store`. `StudentTaskTests` usa el DDL existente solo en H2 en memoria y comprueba filtros, estados, aislamiento, JWT y rechazo de escrituras en las rutas de consulta.

## Entrega de tareas del estudiante

- `POST /api/estudiante/matriculas/{matriculaId}/tareas/{tareaId}/entrega`: `multipart/form-data`, con `comentario` opcional (hasta 10000 caracteres Unicode) y un único `archivo` opcional; al menos uno debe contener datos. Devuelve 201 con el recibo, fecha y estado de la entrega. No acepta valores de calificación o rutas del cliente.
- `GET /api/estudiante/matriculas/{matriculaId}/tareas/{tareaId}/entrega`: recibo y revisión propios, también si posteriormente se desactiva la tarea.
- `GET /api/estudiante/matriculas/{matriculaId}/tareas/{tareaId}/entrega/archivo`: descarga autenticada del adjunto propio, con `Content-Disposition: attachment`, `nosniff` y `no-store`.

JWT ESTUDIANTE, cuenta activa y rol vigente son obligatorios. El servicio vuelve a comprobar la matrícula y el periodo/sección de la asignación. Para enviar exige matrícula `ACTIVA`, tarea activa, publicación iniciada y plazo no vencido, usando `CURRENT_TIMESTAMP` de la base. La fecha `DATETIME` y el reloj de MySQL deben estar configurados coherentemente. Bloquea las filas durante el envío y conserva la restricción real `UNIQUE(tarea_id, matricula_id)` para solicitudes simultáneas.

El esquema admite una respuesta en `comentario` y **un solo archivo** en `archivo_url` por entrega. Esta implementación no permite editar, reemplazar, reenviar ni subir múltiples adjuntos; no crea columnas, tablas, calificaciones ni revisión. Un duplicado produce 409 `ENTREGA_DUPLICADA`; plazo o estado inválidos, 409 `FUERA_DE_PLAZO` / `ENTREGA_CERRADA`; contenido inválido, 400; tamaño excesivo, 413; recurso ajeno/inexistente, 404. No se guarda una entrega vacía.

Se admiten PDF, PNG, JPG/JPEG y TXT UTF-8 hasta 5 MiB. Se contrastan extensión, MIME y firma del contenido (o UTF-8 válido sin controles peligrosos para TXT); se rechazan nombres con rutas, archivos vacíos y más de un adjunto. No hay un motor antivirus ni se ejecutan los documentos. El original no se usa como ruta ni nombre de descarga: el servidor genera un UUID y conserva en `archivo_url` una referencia `urn:entrega:...`; los DTO exponen la ruta autenticada correspondiente. Las referencias antiguas/externas no se descargan ni se leen como rutas locales mediante estos endpoints.

Los bytes se guardan en `backend/storage/entregas` al ejecutar desde `backend/`, fuera de `src` y de los recursos estáticos. `storage/` está ignorado por Git. `app.submissions.storage` permite señalar un directorio privado persistente; desplegarlo con permisos exclusivos del proceso, y conservarlo junto a la base en las copias de seguridad. La aplicación no crea este directorio hasta el primer envío con archivo. Ante rollback elimina el archivo recién escrito. Los límites multipart compartidos son 5 MB por archivo y 6 MB por petición. `StudentSubmissionTests` utiliza únicamente H2 y un directorio temporal de JUnit para comprobar envío, plazo, concurrencia, autorización, archivos y limpieza de rollback.

## Cursos del estudiante

- `GET /api/estudiante/matriculas/{matriculaId}/cursos`: lista ordenada por nombre e identificador de asignación.
- `GET /api/estudiante/matriculas/{matriculaId}/cursos/{asignacionId}`: detalle de una asignación del curso en esa matrícula.

Ambos endpoints requieren JWT ESTUDIANTE, cuenta activa y rol vigente. La matrícula debe pertenecer al usuario del `sub`; la asignación debe coincidir en periodo y sección con esa matrícula. Una matrícula ajena o inexistente y una asignación ajena o inexistente producen el mismo 404 `NO_DISPONIBLE`; un usuario sin perfil recibe 404 `SIN_PERFIL`. Una matrícula propia sin asignaciones devuelve `[]`. No se elige un periodo automáticamente ni se filtran matrículas históricas o cursos inactivos.

La respuesta contiene `asignacionId`, `cursoId`, `nombre`, `descripcion` (puede ser nula), `activo`, `docente` (nombres y apellidos), `periodo`, `nivel`, `grado` y `seccion`. Se usan las tablas existentes `matricula`, `asignacion_docente`, `curso` y sus relaciones, en consultas de solo lectura con `Cache-Control: no-store`. No se crean datos ni se modifica el esquema. `StudentCourseTests` carga el DDL existente exclusivamente en H2 en memoria y comprueba autorización, aislamiento, periodos, lista, detalle y JWT de login real.

## Consulta del perfil Estudiante

- `GET /api/estudiante/perfil`: datos del usuario y perfil `estudiante` asociados al `sub` del JWT. No acepta un identificador para consultar otra cuenta ni devuelve hashes.
- `GET /api/estudiante/matriculas`: todas las matrículas propias con periodo, estado, nivel, grado y sección, ordenadas por inicio del periodo descendente e identificadores como desempate. No selecciona una matrícula automáticamente ni oculta el historial.

Ambos endpoints requieren JWT con autoridad ESTUDIANTE y vuelven a comprobar usuario activo y rol ESTUDIANTE en la base. Responden 401 sin credencial válida, 403 si falta el permiso o la cuenta está inactiva, y 404 con código `SIN_PERFIL` si no existe la fila en `estudiante`. Un perfil sin matrículas devuelve una lista vacía. Las respuestas usan `Cache-Control: no-store` y las consultas son de solo lectura.

`/api/auth/me` y el contrato del login se conservan. El inicializador de desarrollo no crea perfiles ni matrículas: disponer del rol no implica disponer de esos registros. Esta implementación no modifica el esquema ni crea datos locales.

Las pruebas de perfil cargan el DDL de `database/01_estructura.sql` únicamente en H2 en memoria (modo MySQL), usan dos estudiantes para comprobar aislamiento y prueban login con BCrypt y acceso mediante el JWT emitido. No sustituyen una prueba de integración contra una instancia MySQL 8.4 aislada.

Spring Boot 4.1.2, Maven Wrapper, Java 21 y MySQL 8.4 en el puerto 3307. La base `db_institucional` contiene 25 tablas. El esquema existente se comprueba con `spring.jpa.hibernate.ddl-auto=validate`; el backend no crea ni actualiza tablas. El script de instalación está en `../database/01_estructura.sql`.

## Configuración y arranque (PowerShell)

Desde `backend/`, usar el JDK indicado y configurar la clave de firma antes de arrancar:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21.0.11'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

# Crear una clave aleatoria en memoria SIN imprimirla ni guardarla en archivos.
$jwtBytes = New-Object byte[] 32
$jwtRng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$jwtRng.GetBytes($jwtBytes)
$env:JWT_SECRET_BASE64 = [Convert]::ToBase64String($jwtBytes)
$jwtRng.Dispose()
Remove-Variable jwtBytes, jwtRng

.\mvnw.cmd --version
.\mvnw.cmd spring-boot:run
```

`JWT_SECRET_BASE64` es obligatoria: Base64 de al menos 32 bytes aleatorios para HS256. No existe una clave predeterminada. En despliegues se debe suministrar desde un gestor de secretos o el entorno del proceso, manteniendo la misma clave entre reinicios e instancias. Cambiarla invalida los tokens emitidos anteriormente. El ejemplo genera una clave nueva para esa sesión local. No imprimirla, guardarla en Git ni compartirla. Spring Boot no carga archivos `.env` automáticamente.

El JWT vence en una hora. `app.jwt.ttl-seconds` permite configurar entre 1 y 86400 segundos (también mediante `APP_JWT_TTL_SECONDS`). Se validan firma HS256, emisor, vencimiento obligatorio y fecha de validez. No hay renovación ni revocación de tokens; un cambio posterior de roles o desactivación se refleja al volver a iniciar sesión, y un token ya emitido conserva su validez hasta vencer.

La URL compartida es `jdbc:mysql://localhost:3307/db_institucional` y el driver es `com.mysql.cj.jdbc.Driver`. Para otras instalaciones pueden suministrarse `SPRING_DATASOURCE_URL` (protocolo `jdbc:mysql`), `SPRING_DATASOURCE_USERNAME` y `SPRING_DATASOURCE_PASSWORD` mediante el entorno. No versionar credenciales. Usar HTTPS fuera del desarrollo local.

## Cuenta de prueba: activación manual y opcional

El inicializador está **desactivado por defecto** y requiere simultáneamente el perfil `dev` y `APP_DEV_SEED_ENABLED=true`. No se ha ejecutado contra la base local durante la implementación.

En una terminal dedicada, después de configurar `JWT_SECRET_BASE64` y el JDK:

```powershell
$env:SPRING_PROFILES_ACTIVE = 'dev'
$env:APP_DEV_SEED_ENABLED = 'true'
$env:DEV_ACCOUNT_USERNAME = Read-Host 'Usuario de prueba'
$env:DEV_ACCOUNT_PASSWORD = [System.Net.NetworkCredential]::new('', (Read-Host 'Contraseña de prueba' -AsSecureString)).Password
.\mvnw.cmd spring-boot:run
```

La contraseña debe tener al menos 12 caracteres y como máximo 72 bytes UTF-8 (límite de BCrypt). El usuario admite entre 1 y 60 caracteres, sin ser solo espacios. El rol `ESTUDIANTE` debe existir previamente por el script SQL; el inicializador no crea roles.

Solo si el nombre no existe se inserta un `usuario` activo con nombres `Cuenta`, apellidos `Desarrollo`, hash BCrypt y su relación `usuario_rol` exclusivamente con ESTUDIANTE. No crea un perfil académico en la tabla `estudiante`. Si la cuenta ya existe, no modifica contraseña, estado, roles ni ningún otro dato. Una cuenta existente con hash incompatible no se corrige automáticamente.

Después de crear la cuenta, detener el backend y deshabilitar el inicializador antes del siguiente arranque:

```powershell
Remove-Item Env:APP_DEV_SEED_ENABLED, Env:DEV_ACCOUNT_USERNAME, Env:DEV_ACCOUNT_PASSWORD, Env:SPRING_PROFILES_ACTIVE -ErrorAction SilentlyContinue
.\mvnw.cmd spring-boot:run
```

Mantener la clave JWT configurada; no activar este inicializador en producción. No existe registro público ni una API para elegir roles.

## Probar con Postman

1. Arrancar el backend con la clave configurada. Si se desea una cuenta de prueba, ejecutar previamente la activación manual anterior.
2. Enviar `GET http://localhost:8080/api/estado` sin autorización: debe devolver 200.
3. Crear `POST http://localhost:8080/api/auth/login`, seleccionar Body → raw → JSON y `Content-Type: application/json`. Usar las claves `nombreUsuario` y `password`, con los valores de la cuenta elegida. No guardar contraseñas en colecciones compartidas ni habilitar registros de cuerpos de solicitudes.
4. Un login válido devuelve 200, `accessToken`, `tokenType` (`Bearer`), `expiresAt` y `usuario` con `id`, `nombreUsuario`, `nombres`, `apellidos`, `roles`. La respuesta usa `Cache-Control: no-store`. El JWT se devuelve únicamente como credencial en el login exitoso; no contiene contraseña ni hash.
5. Elegir Authorization → Bearer Token y colocar el token recibido. Enviar `GET http://localhost:8080/api/auth/me`: debe devolver 200 con únicamente `id` y `roles`, y `Cache-Control: no-store`. Sin token o con uno inválido devuelve 401. No imprimir tokens en la consola de Postman, exportarlos o guardarlos en Git.
6. Una contraseña incorrecta, un usuario inexistente o inactivo devuelven el mismo 401: `{"mensaje":"Credenciales inválidas"}`. Datos vacíos, nombre mayor de 60 caracteres, contraseña mayor de 72 bytes UTF-8 o JSON malformado devuelven 400 con mensaje genérico. No se incluyen los valores rechazados.
7. Un JWT inválido, con firma alterada, emisor incorrecto o vencido devuelve 401 en rutas protegidas. Los errores no devuelven tokens ni detalles de validación criptográfica.

La seguridad es sin sesión y usa el encabezado `Authorization: Bearer`; no usa login por formulario, cookies de autenticación ni HTTP Basic. Por ello se desactiva CSRF. Los roles se convierten en autoridades `ROLE_...`; por ahora las demás rutas requieren autenticación sin restricciones adicionales por rol.

## Pruebas automatizadas aisladas

```powershell
.\mvnw.cmd -B test
```

Las pruebas cargan el contexto con H2 en memoria, `ddl-auto=none`, inicialización SQL desactivada y repositorios sustituidos por mocks. Generan una clave efímera en memoria; no dependen de la clave del entorno ni consultan o escriben en MySQL local. Se comprueba el endpoint protegido real `/api/auth/me`; la ruta auxiliar `/api/test/protected` solo existe en tests.

Se comprueban login correcto y DTO seguro, acceso público/protegido, credenciales incorrectas, usuario inexistente/inactivo, datos inválidos, JWT malformado/vencido/firma alterada/emisor incorrecto y comportamiento del inicializador con mocks. Estas pruebas no verifican la contraseña o los registros existentes en el servidor local ni reemplazan una comprobación manual con Postman. No se ejecutó un login contra el servidor local durante esta implementación.

`target/`, `.env`, archivos locales y formatos de claves están excluidos por `.gitignore`. Nunca habilitar logging de contraseñas, hashes, cuerpos de login o encabezados Authorization.

## Flutter y CORS local

Para Chrome configurar APP_CORS_ALLOWED_ORIGIN=http://localhost:5173 en la terminal del backend antes del arranque. Solo se acepta ese origen explícito; sin configuración no se habilitan orígenes externos. No se admiten comodines. Ver ../frontend/README.md para comandos completos de Chrome, Android y comprobación manual. No activar el inicializador para probar esta integración con una cuenta ya existente.

## Configuración local y clonación desde GitHub

Las credenciales de la base están en `config/application-local.properties`, un archivo local ignorado por Git y externo al JAR. El archivo compartido `src/main/resources/application.properties` importa opcionalmente `file:./config/application-local.properties` mediante `spring.config.import`. No es necesario activar el perfil `local`: la importación es explícita.

**Ejecutar Maven y el JAR desde `backend/`**, porque la ruta es relativa al directorio de trabajo. Si falta el archivo local, suministrar las credenciales mediante `SPRING_DATASOURCE_USERNAME` y `SPRING_DATASOURCE_PASSWORD`; las variables del entorno tienen prioridad. La configuración compartida usa MySQL 8.4 en el puerto 3307, el driver `com.mysql.cj.jdbc.Driver` y `ddl-auto=validate` para comprobar las 25 tablas sin alterarlas.

Para una clonación nueva, desde `backend/`:

```powershell
# Solo si todavía no existe tu archivo local; no sobrescribir uno ya configurado.
if (-not (Test-Path config/application-local.properties)) {
    Copy-Item config/application-local.properties.example config/application-local.properties
}
notepad config/application-local.properties
```

Completar personalmente usuario y contraseña en ese archivo local. El ejemplo compartido deja ambos valores vacíos y no contiene secretos. No copiar credenciales a `src/main/resources`, al README, a comandos guardados ni a capturas. El archivo local no se incluye en el JAR porque está fuera de `src/`.

Arranque habitual desde `backend/`, con la base ya instalada:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21.0.11'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
$env:APP_DEV_SEED_ENABLED = 'false'
$env:APP_CORS_ALLOWED_ORIGIN = 'http://localhost:5173'

# Omitir este bloque si JWT_SECRET_BASE64 ya está configurada en esta terminal.
if (-not $env:JWT_SECRET_BASE64) {
    $jwtBytes = New-Object byte[] 32
    $jwtRng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $jwtRng.GetBytes($jwtBytes)
    $env:JWT_SECRET_BASE64 = [Convert]::ToBase64String($jwtBytes)
    $jwtRng.Dispose()
    Remove-Variable jwtBytes, jwtRng
}

.\mvnw.cmd spring-boot:run
```

El bloque no muestra ni guarda la clave JWT. Conservar la misma clave entre reinicios si se desea mantener la validez de tokens anteriores. Para ejecutar el JAR, generarlo con ` .\mvnw.cmd -B package` y lanzar `java -jar target/backend-0.0.1-SNAPSHOT.jar` desde este mismo directorio y con las mismas variables.

La revisión de preparación para GitHub no ejecuta el inicializador ni operaciones sobre la base. La prueba `LocalConfigurationTests` comprueba la importación de un archivo temporal sin credenciales mediante el cargador de Spring, sin leer la configuración privada ni crear un DataSource. Las demás pruebas usan mocks y H2 aislado. Los compilados, cachés Gradle, temporales, archivos locales, claves y `.env` están excluidos; Maven Wrapper y el ejemplo sí se versionan.
