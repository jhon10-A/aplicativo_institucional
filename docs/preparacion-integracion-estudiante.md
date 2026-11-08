# Preparación de integración del módulo Estudiante

## Diagnóstico y arranque local

Revisión del 8 de noviembre de 2026 en `feature/estudiante`, inicialmente limpia. El proceso de 8080 se inició a las 08:34 antes de compilar la versión actual; se verificó su directorio de trabajo y clase principal sin publicar argumentos privados. No tenía un origen CORS explícito. El preflight desde `http://localhost:5173` devolvía 403. Spring Security ya admite ese origen si se configura: no se cambió su política, JWT ni los roles.

`backend/scripts/Run-LocalBackend.ps1` inicia el JAR compilado con perfil local y origen explícito, carga `.env` sin imprimir valores y conserva la importación de `config/application-local.properties`. Si encuentra otro origen configurado, exige usar el mismo `-Origin`; no lo sobrescribe. No autoriza comodines ni destinos externos. La política actual permite un solo origen por ejecución, no una lista simultánea. No hay origen de desarrollo predeterminado en el servidor de producción.

El lanzador fija `ddl-auto=validate`, `spring.sql.init.mode=never` e inicializador desactivado. `-ReadOnly` agrega conexiones Hikari de solo lectura: sirve para esta revisión, **no para probar envíos**. Ejecutarlo desde una terminal propia y detenerlo con Ctrl+C antes de volver a lanzarlo. No detener procesos solo por nombre ni tocar MySQL.

Desde `backend/` con Java 21 y el JAR generado mediante Maven `package`:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Run-LocalBackend.ps1 -ReadOnly
```

Para un origen loopback alternativo, pasar por ejemplo `-Origin http://127.0.0.1:5174`; Flutter debe abrirse exactamente en ese origen. El parámetro solo rige esta ejecución. El lanzador no edita archivos privados. `Test-LocalBackendLauncher.ps1` usa un ejecutable simulado y archivos temporales para comprobar argumentos y conflictos de configuración, sin conectarse a MySQL.

## Resultado de la verificación

Se sustituyó exclusivamente el proceso antiguo de 8080 después de verificar PID, fecha, directorio y huella de argumentos; primero se probó el JAR nuevo en 18081 y luego se retiró esa instancia temporal. El backend queda ejecutándose en 8080 con conexiones de solo lectura y CORS explícito. No se ejecutaron escrituras, inicializadores ni DDL sobre la base real.

En ambos puertos se comprobaron preflight GET/POST con respuesta 200, `Access-Control-Allow-Origin: http://localhost:5173`, métodos GET/POST/OPTIONS y encabezados Authorization/Content-Type, sin credenciales CORS. Perfil y Matrículas sin JWT devolvieron 401 conservando el encabezado CORS. Un origen no configurado (5174) y un preflight DELETE devolvieron 403.

Maven `package` con Java 21: 70 pruebas, 69 aprobadas, 1 omitida y ningún fallo/error. La omitida es la prueba opcional de proceso de configuración local. Se corrigió una prueba H2 de comunicados que dependía del redondeo de DATETIME: usa un segundo anterior al reloj actual para comprobar publicación y vencimiento, sin cambiar código productivo. Flutter: analyze sin observaciones, 123 pruebas aprobadas y compilación Web correcta con `API_BASE_URL=http://localhost:8080`. El test PowerShell del lanzador también pasó sin MySQL.

La conexión/arranque MySQL y las solicitudes sin JWT se comprobaron contra la ejecución local; los recorridos autenticados con datos académicos siguen pendientes del entorno aislado. No se mostraron secretos ni se modificaron archivos privados, módulos Docente/Apoderado o las 25 tablas.

## Propuesta de entorno aislado (sin ejecutar ni cargar datos)

Usar otra instancia MySQL en `127.0.0.1:3308` y esquema `db_institucional_pruebas`, backend en 8081 y Flutter Web en 5174. Crear un usuario con permisos exclusivamente sobre ese esquema; no reutilizar credenciales de la base real. Mantener almacenamiento de entregas separado del real, fuera de recursos públicos. Configurar URL JDBC, almacenamiento, clave JWT y origen CORS explícitos en archivos privados de ese entorno. No apuntar este ensayo a `3307/db_institucional`.

El DDL canónico contiene instrucciones de creación/selección de `db_institucional`: antes de usarlo en la instancia aislada, revisar una copia y cambiar exclusivamente el nombre de base en esas instrucciones. Conservar las 25 tablas y sus restricciones. No ejecutar el archivo original sobre la base real. Esta propuesta no crea instancias, cuentas, esquemas ni registros; su preparación efectiva será un trabajo separado autorizado.

## Datos mínimos y relaciones reales

| Recorrido | Datos necesarios en el entorno aislado |
|---|---|
| Login | `usuario` activo, `password_hash` BCrypt válido, `usuario_rol` relacionado con `rol.nombre='ESTUDIANTE'`. Generar contraseña y clave JWT privadamente; no versionar ni publicar credenciales, hashes o tokens. |
| Perfil | `estudiante.usuario_id` único y `codigo_estudiante` único. Una cuenta sin perfil sirve para comprobar la respuesta de ausencia de perfil. |
| Matrículas | `periodo_academico`, `grado`, `seccion` y `matricula.estudiante_id`. Solo una matrícula por estudiante y periodo. |
| Cursos | `curso`, `docente` relacionado con su `usuario` y `asignacion_docente` con el mismo periodo y sección de la matrícula. No existe una inscripción independiente del estudiante a cada curso. |
| Tareas | `tarea.asignacion_docente_id`, publicación, límite, actividad y puntaje máximo positivos; el límite no puede preceder a la publicación. Preparar una tarea vigente, una vencida y una ajena, respetando ese CHECK. |
| Entregas | `entrega_tarea` relaciona tarea y matrícula; el par es único. Comentario y un `archivo_url` opcionales, no una colección de adjuntos. Crear la entrega mediante la API solo en el entorno aislado, con texto y/o un archivo PDF, PNG, JPG o TXT de hasta 5 MiB. No escribir rutas arbitrarias en SQL. |
| Calificaciones | `calificacion` con matrícula, asignación, periodo y sección coherentes mediante claves compuestas; `etapa`, `concepto` y `nota` obligatorios, nota entre 0 y 20. No hay evaluación independiente pendiente, estado de publicación, ponderación ni regla de promedio. |
| Asistencia | Mismas relaciones compuestas; un registro por matrícula, asignación y fecha. Estados reales: PRESENTE, FALTA, TARDANZA y JUSTIFICADA. No inventar faltas para fechas sin registro. |
| Comunicados | `autor_id`, contenido, título, publicación y actividad; vencimiento opcional. Rol y sección nulos dan alcance general; si están definidos se intersectan. No hay FK de periodo ni destinatario individual. `notificacion` no concede acceso al comunicado. |

Para aislamiento usar dos estudiantes A/B, cada uno con su usuario activo y matrícula del mismo periodo, pero en secciones distintas. Un docente con su usuario y asignaciones en ambas secciones permite comprobar que compartir curso/docente no concede acceso. Añadir un periodo histórico y otra matrícula de A para comprobar selección explícita; no crear dos matrículas de A en el mismo periodo. Añadir datos de B para cada recurso protegido.

Preparar comunicados generales, solo ESTUDIANTE, sección A, sección B y solo DOCENTE; además uno futuro, uno vencido y uno inactivo. Los periodos seleccionan la sección a través de la matrícula, no una fecha de publicación inventada. Las cuentas sin matrícula, desactivada o sin rol permiten probar errores y vacíos sin usar personas reales. Son casos propuestos, no datos insertados.

## Comprobaciones pendientes con datos aislados

1. Introducir las credenciales personalmente en Flutter, verificar login y cerrar sesión; no guardar tokens en el informe.
2. Recorrer Perfil, Matrículas y Cursos; alternar periodos y comprobar sus secciones, cursos y docentes.
3. Consultar Tareas y detalle; enviar una entrega aislada, descargar el archivo con Bearer, comprobar duplicados y plazo. Probar tamaño/tipo inválido y pulsaciones repetidas. No habilitar escrituras en la sesión de auditoría de la base real.
4. Consultar notas (incluido cero), asistencia con fechas y resumen, comunicados por audiencia; probar vacíos, errores, reintento y expiración de sesión.
5. Con A intentar los identificadores de B: deben permanecer inaccesibles aun compartiendo curso. Probar sin JWT (401), token inválido y rol/cuenta no autorizados. No usar datos personales reales para estas pruebas.
6. Comprobar selector/descarga de archivos en navegador y dispositivos; Web usa `http://localhost:8081`, emulador Android `http://10.0.2.2:8081` y dispositivo físico la IP LAN del servidor. Cada plataforma necesita configuración explícita de `API_BASE_URL`; CORS corresponde al origen Web, no a la URL de la API.

Las pruebas Maven usan H2/mocks y Flutter usa HTTP simulado. Cubren autorización, aislamiento y estados de interfaz; no sustituyen esta comprobación manual con datos aislados. No se ha realizado un login real de estudiante ni un envío real contra `db_institucional`.
