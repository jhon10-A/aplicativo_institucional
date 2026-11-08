# Frontend institucional: login Flutter

## Perfil del estudiante

El menú Estudiante incluye Perfil. Consulta `/api/estudiante/perfil` y `/api/estudiante/matriculas` con la misma `API_BASE_URL` del login y el JWT Bearer de la sesión. Muestra datos personales, código y todas las matrículas con periodo, estado, nivel, grado y sección; no selecciona una matrícula por defecto. Los campos opcionales ausentes se presentan como “No registrado”. El perfil es de consulta, sin edición ni creación de matrículas.

La pantalla distingue carga, ausencia de perfil, ausencia de matrículas, acceso denegado y error con reintento. Un 401 cierra la sesión. Al salir de Perfil, cerrar sesión o vencer el plazo de una solicitud, se descartan las respuestas pendientes. El cliente no persiste ni imprime el JWT. Cursos, Tareas, Calificaciones, Asistencia y Comunicados tienen sus pantallas de consulta descritas más abajo.

Las pruebas usan HTTP simulado para verificar los estados, la navegación, el envío de Bearer y el descarte de respuestas tardías. No crean usuarios ni registros en MySQL.

La app envía `POST /api/auth/login` con JSON `nombreUsuario` y `password`. Lee la respuesta real (`accessToken`, `tokenType`, `expiresAt`, `usuario`) y muestra nombres, apellidos y roles recibidos. No incluye cuentas simuladas ni registro público. El perfil y las matrículas se consultan en los endpoints del estudiante.

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

Si este backend ya usa el puerto 8080, detenerlo con Ctrl+C en su terminal antes de reiniciarlo. Usar una cuenta existente, activa y con hash BCrypt; esta integración no crea cuentas ni cambia tablas. El backend usa MySQL 8.4 en el puerto 3307, base `db_institucional` de 25 tablas, y `ddl-auto=validate` para comprobar el esquema sin alterarlo.

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

## Panel inicial del estudiante

El acceso Estudiante abre el panel solo después del login real y de comprobar el rol ESTUDIANTE devuelto por el backend. Docente y Padre de familia conservan su pantalla de sesión actual. No se modificó el cliente HTTP ni la configuración de conexión.

El módulo está separado en `lib/features/student/`: `student_section.dart` define la navegación, `screens/student_panel.dart` contiene la estructura adaptable y `widgets/` contiene menú, inicio y estado de desarrollo.

Inicio conserva nombres, apellidos, usuario y roles reales de la sesión. Sus accesos abren las pantallas funcionales de Perfil, Cursos, Tareas, Calificaciones, Asistencia y Comunicados. En celulares y tablets se usa un menú lateral desplegable; en pantallas de al menos 900 píxeles, la navegación queda visible. Atrás desde una sección vuelve a Inicio; desde Inicio cierra la sesión, igual que el botón Cerrar sesión. El cierre elimina la sesión de memoria y vuelve a la portada.

### Comunicados del estudiante

Comunicados reutiliza el `StudentApi` con Bearer y abre inicialmente **Generales (sin sección)**, sin seleccionar una matrícula por defecto. El selector **Audiencia y matrícula** permite añadir los específicos de la sección de una matrícula propia; muestra periodo, nivel, grado y sección para identificar ese contexto. Si no hay perfil o matrículas, siguen disponibles los generales autorizados. La pantalla diferencia la audiencia por sección y el destino de rol, sin presentar un comunicado dirigido solo a ESTUDIANTE como público para otros roles.

La lista muestra título, remitente, publicación y audiencia. El detalle vuelve a consultar la visibilidad al servidor, muestra el contenido completo como texto seleccionable y el vencimiento cuando existe. Volver conserva la selección. Incluye carga, vacío, error y reintento; un 401 cierra sesión y un 403 informa falta de acceso. Al salir se descartan las respuestas pendientes. No se renderiza HTML ni se abren enlaces o adjuntos, y no se inventan estados de leído/no leído.

El comunicado no tiene vínculo con un periodo: seleccionar una matrícula filtra por su sección, sin restringir por el año de publicación. Se indica al usuario que verá los generales y los de la sección seleccionada. La vigencia se decide en el backend con su reloj. Las notificaciones individuales no forman parte de esta pantalla ni conceden acceso a otros comunicados. `student_notices_test.dart` prueba generales sin perfil, selección, audiencia, lista, detalle, fechas disponibles, vacíos, errores, Bearer y diseño adaptable con HTTP simulado. Las pruebas del panel recorren las seis secciones funcionales, sin usar MySQL.

### Asistencia del estudiante

Asistencia reutiliza el `StudentApi` autenticado. Primero pide seleccionar explícitamente matrícula/periodo; permite ver todos sus cursos o filtrar por una asignación. `Desde` y `Hasta` aceptan fechas opcionales `AAAA-MM-DD` con límites inclusivos. **Aplicar fechas** consulta el rango y **Limpiar fechas** lo retira; se muestra el rango efectivamente consultado. Las fechas imposibles o invertidas se rechazan antes de enviar la solicitud y los filtros también se validan en backend. El cliente solo admite parámetros `desde` y `hasta` en las rutas de listado de asistencia, nunca identificadores de otros usuarios.

La lista muestra fecha, curso, periodo y estado (`Presente`, `Falta`, `Tardanza`, `Justificada`). Si hay registros, muestra el resumen del servidor con los mismos filtros: total y conteos de cada estado. El detalle consulta nuevamente el registro y añade docente, nivel, grado, sección, observación disponible y fecha de registro. Volver conserva curso y fechas; cambiar matrícula reinicia el curso y conserva el rango consultado. No se inventan faltas para días sin registros ni se muestran porcentajes; se cuentan registros por curso y fecha, no días únicos. La justificación se consulta, sin adjuntos ni solicitud de cambios de estado.

Incluye carga, ausencia de matrículas, lista vacía, error y reintento; sin datos no se muestra un resumen de faltas inexistentes. Un 401 cierra sesión y un 403 informa falta de acceso. Se descartan respuestas al salir. `student_attendance_test.dart` usa HTTP simulado para probar filtros, fechas, resumen, estados, detalle, errores, navegación y diseño adaptable con texto ampliado, sin MySQL real.

### Calificaciones del estudiante

Calificaciones usa el `StudentApi` autenticado existente. Solicita seleccionar explícitamente matrícula/periodo, carga sus cursos y permite ver todos o filtrar por una asignación. Muestra concepto de la evaluación registrada, etapa, curso, periodo y nota con dos decimales sobre 20. El detalle vuelve a consultar al backend y añade docente, nivel, grado, sección, fecha de registro y observación disponible. Volver al listado conserva el filtro; cambiar la matrícula reinicia el curso.

Solo se muestran notas registradas. Un cero se identifica como `Nota registrada: 0.00 / 20`; una selección vacía muestra `No hay calificaciones registradas para esta selección.`. La base no contiene evaluaciones independientes sin nota ni estado de publicación, y el proyecto no define promedios: la pantalla no inventa pendientes, ceros, evaluaciones, ponderaciones o promedios. El puntaje de las entregas se mantiene en Tareas y no se convierte en una calificación académica.

Incluye carga, ausencia de matrículas, sin datos, errores y reintento; 401 cierra sesión y 403 informa falta de acceso. No imprime cuerpos internos ni conserva respuestas al salir. `student_grades_test.dart` comprueba selección de periodo y curso, lista, detalle, cero, vacíos, errores, Bearer, navegación y adaptación a móvil, tablet y escritorio con texto ampliado. Las pruebas usan HTTP simulado, sin MySQL real.

### Tareas del estudiante

Tareas reutiliza `StudentApi` y el Bearer de la sesión. Primero se selecciona explícitamente la matrícula y periodo; luego se pueden consultar todos sus cursos o filtrar por curso. La lista muestra título, curso, docente, fecha límite y estado de entrega. El detalle consulta nuevamente al backend y muestra descripción, publicación, puntaje máximo y la entrega propia con fecha, comentario, archivo y revisión disponibles. Los archivos no se ejecutan ni abren automáticamente.

Incluye carga, ausencia de matrículas, lista vacía, error y reintento, retorno al listado conservando el filtro y vuelta al inicio. Al cambiar de matrícula se reinicia el curso seleccionado. Las fechas se muestran tal como vienen del `DATETIME` del backend, sin conversión de zona. Un 401 cierra la sesión; 403 y 404 se muestran sin cuerpos internos. Las respuestas pendientes se descartan al salir. Las pruebas de `student_tasks_test.dart` usan HTTP simulado, verifican filtros, lista, detalle, errores, navegación y diseño adaptable con texto ampliado.

### Entrega de tareas

Desde el detalle, **Entregar tarea** abre un formulario con respuesta escrita y/o un archivo PDF, PNG, JPG o TXT de hasta 5 MiB. `file_picker` permite seleccionar un archivo y guardar la descarga; `http_parser` aporta el MIME al multipart enviado por el `StudentApi` existente. No se envían rutas locales, calificaciones o identificadores de otros usuarios. El servidor valida el plazo con su propio reloj, además de tipo, tamaño y autorización.

Antes del POST hay una confirmación explícita. Durante la selección, confirmación y envío se deshabilitan las acciones para impedir pulsaciones repetidas. Un envío exitoso muestra el recibo y su estado; al volver se actualiza el detalle. **Consultar mi entrega** permite revisar el recibo y **Guardar mi archivo** descarga con Bearer mediante la ruta propia y abre el diálogo de guardado. No se navega a enlaces externos o referencias antiguas del servidor. El cierre por 401 retira también la pantalla de entrega.

Una tarea admite una sola entrega y un solo adjunto: no hay edición ni reemplazo. Ante error se conserva la respuesta para corregirla; si no se sabe si el servidor registró el envío (por ejemplo, por pérdida de conexión), consultar el recibo antes de intentarlo otra vez. El botón de consulta está disponible en el formulario. No hay reenvío automático ni credenciales persistidas.

Las pruebas de `student_submission_test.dart` usan HTTP, selector y guardado simulados para validar confirmación, carga, éxito, errores, adjuntos y prevención de duplicados. Los registros de plugins y permisos de archivos seleccionados en macOS se versionan junto a `pubspec.lock`. Para compilar aplicaciones nativas de Windows, el SDK puede requerir soporte de enlaces simbólicos (Developer Mode según la configuración del equipo); no es necesario modificarlo para las pruebas de widgets. Debe verificarse el selector/guardado nativo en cada plataforma de despliegue con archivos de prueba, sin utilizar credenciales ni documentos reales en las pruebas automatizadas.

### Cursos del estudiante

Cursos usa el `StudentApi` autenticado existente con el token de la sesión en memoria. Primero consulta las matrículas propias y pide seleccionar explícitamente una matrícula con su periodo, grado y sección. Luego carga la lista desde `/api/estudiante/matriculas/{id}/cursos`; al pulsar un curso consulta su detalle con el identificador de asignación. Muestra nombre, docente, periodo, nivel, grado, sección, descripción disponible y estado activo, conservando el historial académico.

La pantalla incluye carga, ausencia de matrículas, lista vacía, errores con reintento y retorno a la lista o al inicio. Un 401 invoca el cierre de sesión; un 403 informa falta de acceso. Las respuestas pendientes se descartan al salir. No usa datos ficticios en producción ni guarda credenciales. `student_courses_test.dart` comprueba selección de periodos, autenticación HTTP, lista, detalle, errores, navegación y cancelación con respuestas aisladas.

Ejecutar desde `frontend/` con los comandos de Chrome o Android ya documentados arriba. Verificación del módulo: `flutter analyze --no-pub` y `flutter test --no-pub`. Las pruebas de navegación y login usan respuestas aisladas; no equivalen a una prueba con una cuenta real en el servidor local.
