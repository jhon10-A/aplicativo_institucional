# Frontend institucional: login Flutter

La app envía `POST /api/auth/login` con JSON `nombreUsuario` y `password`. Lee la respuesta real (`accessToken`, `tokenType`, `expiresAt`, `usuario`) y muestra nombres, apellidos y roles recibidos. No incluye cuentas simuladas, registro público ni información académica.

La contraseña se limpia al enviar la solicitud y no se persiste. La sesión y el JWT existen solo en memoria: cerrar sesión, vencer el token o reiniciar la app elimina la sesión. No se imprimen credenciales, cuerpos de login ni tokens. No hay renovación automática ni almacenamiento persistente.

## Preparar el backend para Chrome

En una terminal PowerShell, desde la raíz del repositorio:

```powershell
Set-Location backend
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21.0.11'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
$env:APP_DEV_SEED_ENABLED = 'false'
$env:APP_CORS_ALLOWED_ORIGIN = 'http://localhost:5173'
```

Configurar también `JWT_SECRET_BASE64` como se explica en `../backend/README.md`, sin imprimir la clave ni guardarla en Git. Después:

```powershell
.\mvnw.cmd spring-boot:run
```

Si este backend ya usa el puerto 8080, detenerlo con Ctrl+C en su terminal antes de reiniciarlo. Usar una cuenta existente, activa y con hash BCrypt; esta integración no crea cuentas ni cambia tablas. Conservar la conexión local ya configurada y `ddl-auto=none`.

CORS se configura exclusivamente mediante `APP_CORS_ALLOWED_ORIGIN` (`app.cors.allowed-origin`). Sin esa variable no se habilitan orígenes externos. El valor permite exactamente un origen HTTP local con puerto, por ejemplo `http://localhost:5173`, sin barra final. No admite comodines ni todos los orígenes. Abrir Chrome en ese origen exacto: `127.0.0.1` y `localhost` son orígenes diferentes. Cambiar la variable requiere reiniciar el backend.

## Ejecutar en Chrome

En otra terminal, desde la raíz del repositorio:

```powershell
Set-Location frontend
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 5173 --dart-define=API_BASE_URL=http://localhost:8080
```

`API_BASE_URL` es obligatoria, sin valor predeterminado ni IP personal. Debe ser la URL raíz del backend (sin `/api`, parámetros, credenciales o fragmentos). Si cambia, reiniciar Flutter con el nuevo `--dart-define`; hot reload no modifica esta configuración.

## Emulador Android

Con el backend ejecutándose y un emulador Android estándar iniciado:

```powershell
flutter devices
flutter run -d <ID_EMULADOR> --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Reemplazar `<ID_EMULADOR>` por el identificador que muestra `flutter devices`. `10.0.2.2` es el alias del equipo anfitrión en el emulador Android estándar; `localhost` dentro del emulador apunta al propio emulador. Las apps Android nativas no requieren CORS.

## Celular Android físico

Conectar el dispositivo para depuración, mantenerlo en la misma red que el equipo del backend y consultar en el equipo su dirección IPv4 LAN con `ipconfig`. En `frontend/`:

```powershell
$backendHost = Read-Host 'IPv4 LAN del equipo donde corre el backend'
flutter devices
flutter run -d <ID_CELULAR> --dart-define="API_BASE_URL=http://${backendHost}:8080"
```

Reemplazar `<ID_CELULAR>` por el identificador real. El backend debe escuchar en una interfaz accesible desde la LAN y el firewall permitir el puerto 8080 en la red privada. No usar `localhost` en el celular. No fijar la dirección personal en el código ni en Git.

Android tiene permiso INTERNET y permite HTTP sin cifrar únicamente en la variante debug usada por `flutter run`. Para release y despliegues usar HTTPS; no se habilitó HTTP global en release. Estas instrucciones cubren Chrome y Android; no se verificaron otras plataformas.

## Comprobar manualmente el login

1. Abrir la app e introducir personalmente el usuario y contraseña de una cuenta existente. El icono permite mostrar/ocultar la contraseña.
2. Pulsar Ingresar: se muestra carga y se bloquean envíos duplicados. La contraseña se vacía al enviarla, también ante errores.
3. Un 200 muestra exclusivamente los datos del usuario devueltos por el backend. Cerrar sesión vuelve al formulario vacío y elimina la sesión en memoria. Recargar Chrome también la elimina.
4. Un 401 muestra un mensaje genérico de credenciales incorrectas o usuario inactivo. Un 400 muestra datos inválidos. Los errores de conexión y tiempo de espera (15 segundos) permiten reintentar sin mostrar el cuerpo interno del servidor.
5. En Chrome un fallo de CORS puede verse como error de conexión: comprobar origen exacto, puerto, variable del backend y que se haya reiniciado. No compartir capturas de solicitudes con contraseñas o tokens.

## Verificación automatizada

Desde `frontend/`:

```powershell
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=http://localhost:8080
```

Las pruebas de Dart usan respuestas HTTP aisladas, no usuarios de la base local. Cubren el contrato JSON, errores HTTP, conexión, timeout, configuración, respuesta malformada/vencida, validación del formulario, visibilidad, carga y sesión/cierre. El backend tiene pruebas aisladas de CORS para `http://localhost:5173`, incluido el rechazo de otro origen.

Estas comprobaciones no son un login real contra el servidor local. No se ejecutó un login con una cuenta real ni se probaron dispositivos Android físicos o emuladores durante la implementación.

## Diseño institucional (primera etapa)

La portada y los tres accesos se adaptaron a las primeras cuatro páginas de la referencia visual: azul institucional, vino, dorado, identidad del colegio, accesos de colores y un formulario reutilizable. Son widgets y textos de Flutter, no capturas del PDF usadas como pantalla.

- `lib/main.dart`: estado de navegación y sesión exclusivamente en memoria.
- `lib/access_profile.dart`: variantes visuales y correspondencia de acceso con roles reales.
- `lib/screens/`: portada, login, Tecnología y pantalla de datos reales tras ingresar.
- `lib/widgets/`: identidad institucional, tarjetas de acceso y formulario compartido.
- `lib/auth.dart`: cliente HTTP existente, sin cambios de URL ni contrato.

El acceso Estudiante requiere `ESTUDIANTE`, Docente requiere `DOCENTE` y Padre de familia requiere `APODERADO`. La selección no se envía como permiso ni modifica los roles del servidor. Si el backend autentica una cuenta cuyos roles no incluyen el del acceso elegido, la app muestra un mensaje y descarta el token sin conservar una sesión. Una cuenta con varios roles puede entrar por cualquiera de sus accesos correspondientes. Una cuenta exclusivamente ADMINISTRADOR no tiene un acceso en esta etapa. La autorización efectiva de los endpoints sigue siendo responsabilidad del backend.

Tecnología solo muestra “Aún no hay recursos publicados”. No se añadieron cursos, notas, tareas, recuperación de contraseña, registro público ni almacenamiento de usuario/contraseña. Se omitieron los controles de recordar usuario y recuperar contraseña del diseño, porque esas funciones no están implementadas.

### Material gráfico pendiente

El repositorio no contiene el escudo oficial ni fotografías institucionales originales; las páginas de referencia son composiciones completas. Se usó un emblema provisional MB con un icono escolar y símbolos de acceso hechos con widgets, sin presentar una ilustración como fotografía real del colegio.

Para completar la fidelidad gráfica se necesitan:

1. Escudo oficial en SVG o PNG transparente de buena resolución.
2. Fotografía original de la fachada del colegio y, si corresponde, el banner institucional.
3. Ilustraciones originales autorizadas de estudiante, docente y familia usadas en el diseño, preferentemente con fondo transparente.

Los comandos Chrome/Android y API_BASE_URL documentados arriba se conservan. El backend, CORS, las cuentas y el esquema de base de datos no se modificaron en esta adaptación. Las pruebas usan respuestas aisladas para comprobar los roles; no equivalen a ejecutar un login real contra el servidor local.
