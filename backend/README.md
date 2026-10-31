# Backend institucional

Spring Boot 4.1.2, Maven Wrapper, Java 21 y MariaDB. El esquema existente se conserva con `spring.jpa.hibernate.ddl-auto=none`; el backend no crea ni actualiza tablas. El script de instalación está en `../database/01_estructura.sql`.

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

La conexión local existente se conserva. Para otras instalaciones pueden suministrarse `SPRING_DATASOURCE_URL` (protocolo `jdbc:mariadb`), `SPRING_DATASOURCE_USERNAME` y `SPRING_DATASOURCE_PASSWORD` mediante el entorno. No versionar credenciales. Usar HTTPS fuera del desarrollo local.

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
5. Para rutas protegidas, elegir Authorization → Bearer Token y colocar el token recibido. No imprimir tokens en la consola de Postman, exportarlos o guardarlos en Git. Actualmente no hay endpoints de negocio adicionales: una ruta inexistente devuelve 401 sin token y 404 con un token válido.
6. Una contraseña incorrecta, un usuario inexistente o inactivo devuelven el mismo 401: `{"mensaje":"Credenciales inválidas"}`. Datos vacíos, nombre mayor de 60 caracteres, contraseña mayor de 72 bytes UTF-8 o JSON malformado devuelven 400 con mensaje genérico. No se incluyen los valores rechazados.
7. Un JWT inválido, con firma alterada, emisor incorrecto o vencido devuelve 401 en rutas protegidas. Los errores no devuelven tokens ni detalles de validación criptográfica.

La seguridad es sin sesión y usa el encabezado `Authorization: Bearer`; no usa login por formulario, cookies de autenticación ni HTTP Basic. Por ello se desactiva CSRF. Los roles se convierten en autoridades `ROLE_...`; por ahora las demás rutas requieren autenticación sin restricciones adicionales por rol.

## Pruebas automatizadas aisladas

```powershell
.\mvnw.cmd -B test
```

Las pruebas cargan el contexto con H2 en memoria, `ddl-auto=none`, inicialización SQL desactivada y repositorios sustituidos por mocks. Generan una clave efímera en memoria; no dependen de la clave del entorno ni consultan o escriben en MariaDB local. El endpoint de prueba protegido solo existe en el código de tests.

Se comprueban login correcto y DTO seguro, acceso público/protegido, credenciales incorrectas, usuario inexistente/inactivo, datos inválidos, JWT malformado/vencido/firma alterada/emisor incorrecto y comportamiento del inicializador con mocks. Estas pruebas no verifican la contraseña o los registros existentes en el servidor local ni reemplazan una comprobación manual con Postman. No se ejecutó un login contra el servidor local durante esta implementación.

`target/`, `.env`, archivos locales y formatos de claves están excluidos por `.gitignore`. Nunca habilitar logging de contraseñas, hashes, cuerpos de login o encabezados Authorization.

## Flutter y CORS local

Para Chrome configurar APP_CORS_ALLOWED_ORIGIN=http://localhost:5173 en la terminal del backend antes del arranque. Solo se acepta ese origen explícito; sin configuración no se habilitan orígenes externos. No se admiten comodines. Ver ../frontend/README.md para comandos completos de Chrome, Android y comprobación manual. No activar el inicializador para probar esta integración con una cuenta ya existente.

## Configuración local y clonación desde GitHub

Las credenciales de la base están en `config/application-local.properties`, un archivo local ignorado por Git y externo al JAR. El archivo compartido `src/main/resources/application.properties` importa opcionalmente `file:./config/application-local.properties` mediante `spring.config.import`. No es necesario activar el perfil `local`: la importación es explícita.

**Ejecutar Maven y el JAR desde `backend/`**, porque la ruta es relativa al directorio de trabajo. Si falta el archivo local, suministrar las credenciales mediante `SPRING_DATASOURCE_USERNAME` y `SPRING_DATASOURCE_PASSWORD`; las variables del entorno tienen prioridad. La URL MariaDB, el driver `org.mariadb.jdbc.Driver` y `ddl-auto=none` se conservan en la configuración compartida.

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

La revisión de preparación para GitHub no ejecuta el inicializador ni operaciones sobre la base. La prueba `LocalConfigurationTests` comprueba la importación mediante el cargador de configuración de Spring, sin crear un DataSource. Las demás pruebas usan mocks y H2 aislado. Los compilados, temporales, archivos locales, claves y `.env` están excluidos; Maven Wrapper y el ejemplo sí se versionan.
