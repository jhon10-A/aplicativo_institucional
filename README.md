# Aplicativo institucional

Repositorio con frontend Flutter, backend Spring Boot y la estructura SQL de la base institucional.

- `frontend/`: portada institucional, accesos por rol y login real. Ver [instrucciones Flutter](frontend/README.md).
- `backend/`: Java 21, Maven Wrapper, Spring Security, JWT y MariaDB. Ver [configuración y arranque](backend/README.md).
- `database/`: script original de 25 tablas y roles. Ver [instalación nueva de la base](database/README.md). No repetirlo sobre una base que ya tiene tablas.

## Configuración local del backend

Desde `backend/`, copiar `config/application-local.properties.example` a `config/application-local.properties` **solo si no existe**, y completar allí las credenciales propias. El archivo local está ignorado por Git y fuera del JAR. Spring Boot lo importa automáticamente al ejecutar desde `backend/`; no requiere activar el perfil `local`.

El archivo compartido conserva `jdbc:mariadb://localhost:3306/db_institucional`, el driver `org.mariadb.jdbc.Driver` y `spring.jpa.hibernate.ddl-auto=none`. La clave `JWT_SECRET_BASE64` se suministra exclusivamente mediante el entorno, sin valor predeterminado ni claves guardadas en este repositorio. Ver el README del backend para generar una clave en memoria sin imprimirla.

Con JDK 21, credenciales locales y clave JWT configurados:

```powershell
Set-Location backend
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21.0.11'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
$env:APP_DEV_SEED_ENABLED = 'false'
$env:APP_CORS_ALLOWED_ORIGIN = 'http://localhost:5173'
.\mvnw.cmd spring-boot:run
```

El inicializador de cuentas no se habilita en el arranque habitual. No guardar ni compartir contraseñas, hashes, tokens o archivos locales. Los `.gitignore` excluyen secretos, compilados y temporales; se conservan Maven Wrapper, los fuentes, los ejemplos sin secretos y `frontend/pubspec.lock`.

## Comprobaciones

Desde `backend/`: ` .\mvnw.cmd -B clean test` (JDK 21, pruebas aisladas sin escrituras en MariaDB local).

Desde `frontend/`: `flutter analyze` y `flutter test`.

Antes de preparar un commit, revisar `git status --short` y los archivos que se van a incluir. El archivo local de credenciales no debe aparecer. Esta preparación no realiza commit ni push.
