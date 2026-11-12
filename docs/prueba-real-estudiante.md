# Prueba integral autorizada del módulo Estudiante

Fecha: 8 de noviembre de 2026. Rama inicial `feature/estudiante`, árbol limpio. El usuario autorizó expresamente nuevos datos ficticios y entregas en **localhost:3307/db_institucional**, sustituyendo la propuesta anterior de una base aislada. No se creó otra base ni instancia.

## Respaldo y protección de datos anteriores

Antes de escribir se comprobó la existencia y SHA-256 del respaldo privado `secrets/mysql-backups/20261108-113407/db_institucional.sql`: `A056576434ACA563777D7F00750021AA6347548869A0A825FD73A613EC697105`. El volcado completo pasó comprobaciones estructurales, pero **no se ensayó una restauración**. Contiene información privada y permanece fuera de Git.

Una consulta confirmó `DATABASE() = db_institucional` y `@@port = 3307`. Se verificaron 25 tablas InnoDB. Había cuatro roles, un usuario y una relación usuario-rol; las otras 22 tablas estaban vacías. Al terminar, nuevos volcados filtrados confirmaron que los registros originales de esas tres tablas coinciden exactamente con el respaldo, sin publicar sus valores.

Las 25 definiciones `SHOW CREATE TABLE` se compararon con el respaldo excluyendo únicamente los contadores AUTO_INCREMENT, que avanzan normalmente al insertar. No se ejecutó DDL, DELETE, UPDATE, TRUNCATE ni cambios de módulos Docente/Apoderado. Se añadió un perfil docente ficticio porque el curso necesita su asignación; eso no modifica el módulo Docente.

## Datos nuevos y diario de identificadores

Marca de ejecución: **TEST_EST_a144bf99**. Los registros sin columna descriptiva se identifican por sus claves foráneas y el diario privado `secrets/student-live/run-20261108/ids.json`. Las credenciales generadas, manifestaciones completas, respuestas HTTP y adjuntos permanecen en esa carpeta ignorada; no se copiaron contraseñas ni datos personales existentes.

| Tabla | IDs nuevos |
|---|---|
| usuario | 2, 3 (estudiantes), 4 (docente ficticio) |
| usuario_rol | Usuario 2 y 3 → ESTUDIANTE; usuario 4 → DOCENTE; roles existentes reutilizados |
| estudiante | 1, 2 |
| docente | 1 |
| periodo_academico, grado, curso | 1 en cada tabla |
| seccion, matricula, asignacion_docente | 1, 2 en cada tabla |
| tarea | 1, 2 vigentes; 3 vencida |
| entrega_tarea | 1, 2, creadas mediante la API |
| calificacion | 1, 2 (incluido cero válido) |
| asistencia | 1–8, cuatro estados por estudiante |
| comunicado | 1, 2 específicos; 3 general; 4 futuro; 5 vencido |

Son **38 filas nuevas en 15 tablas**, incluidas tres relaciones usuario-rol. Los datos académicos se insertaron en una transacción con rollback ante error. Cada entrega utiliza la transacción existente de la API y un archivo TXT ficticio; se comprobó la identidad de los bytes descargados.

No hay retirada automática. Una futura limpieza necesita autorización adicional, revisar el diario y posibles relaciones agregadas posteriormente, y respetar el orden de claves foráneas. **No restaurar el respaldo sobre la base actual ni eliminar por prefijos amplios.**

## Resultados reales

El backend temporal se inició en loopback:8081, con importación privada habitual deshabilitada, destino JDBC explícito, clave JWT efímera, almacenamiento de adjuntos separado, CORS explícito `http://localhost:5174`, validación de esquema e inicializadores desactivados. No se cambió la configuración del backend habitual de 8080.

**65 comprobaciones HTTP reales aprobadas**: login de ambos estudiantes; Perfil y Matrículas; lista/detalle de Cursos y Tareas, filtro de tareas por curso; lista/detalle de Calificaciones; Asistencia con resumen y rango invertido rechazado; Comunicados por sección y vigencia; entrega propia, consulta y descarga; rechazo de duplicados, tarea vencida, extensión inválida y tamaño excesivo; rechazo de accesos y envío a recursos ajenos, incluso compartiendo curso/docente; 401 sin JWT o con token inválido y 403 para el docente. Los endpoints utilizados son los existentes bajo `/api/auth/login` y `/api/estudiante/**`; no se añadieron endpoints productivos.

La prueba optativa Flutter pasó contra **HTTP y MySQL reales** usando `AuthApi` y `StudentApi`: login, consulta/descarga de entrega y aislamiento; renderizado sin interfaz visible de Perfil/Matrículas, Cursos, Tareas, Calificaciones, Asistencia y Comunicados, con selección de matrícula y detalles disponibles. No utiliza respuestas MockClient. **No equivale a una revisión visual en Chrome ni en dispositivos.**

## Pruebas automatizadas y limitaciones

| Ejecución | Resultado |
|---|---|
| Java 21: compilación del ejecutor optativo | Correcta |
| Maven `test` con H2/mocks | 70 pruebas: 69 aprobadas, 1 opcional omitida, sin fallos/errores |
| `flutter analyze --no-pub` | Sin observaciones, incluida la prueba optativa |
| `flutter test --no-pub` | 123 aprobadas |
| `flutter test --no-pub test_live/student_live_test.dart` con directorio privado | 1 aprobada, cubre seis pantallas y cliente real |
| `flutter build web --no-pub --dart-define=API_BASE_URL=http://localhost:8081` | Correcta |

El primer `Maven package` pasó sus 70 pruebas pero falló al renombrar el JAR ocupado por el proceso habitual. `Maven test` se repitió y terminó correctamente; no se declara que aquel empaquetado pasara. No se detuvo el backend habitual para resolver un bloqueo ajeno a la funcionalidad.

El primer control posterior a la transacción se detuvo por una comparación demasiado estricta del contador AUTO_INCREMENT. Se corrigió el ejecutor, se comparó el esquema con el respaldo y se continuó con el mismo diario, **sin repetir la inserción de datos académicos**. No hubo fallos funcionales en las comprobaciones posteriores.

Pendientes manuales: apariencia y navegación en Chrome visible, selector/guardado nativo de adjuntos, envío desde el formulario con confirmación, adaptación en dispositivos y desconexión/reintento con red real. Las pruebas aisladas existentes cubren carga/vacío/error/reintento; esos escenarios no se provocaron modificando datos reales. No se calculan promedios, evaluaciones pendientes ni audiencias por periodo inexistentes en el esquema.

## Ejecución optativa y sesión manual

`Run-StudentLiveIntegration.ps1` **escribe datos reales**, requiere `-AuthorizeNewTestRecords`, respaldo y huella verificados, directorio privado nuevo y `JAVA_HOME` de Java 21. No forma parte de Maven test ni de flutter test por defecto. Solo acepta el destino fijo revisado y detiene la creación si encuentra datos académicos existentes; no debe volver a sembrarse esta base. `-ResumeCommittedFixture` no repite la transacción, verifica las definiciones contra el respaldo y rechaza continuar si ya existen entregas en el diario.

El classpath debe contener `backend/target/classes` y las dependencias Maven. Se puede generar la lista de dependencias mediante Maven `dependency:build-classpath`, conservarla en un temporal ignorado y anteponer la ruta absoluta de las clases compiladas; el parámetro `-ClasspathFile` recibe ese archivo. El ejecutor requiere lanzar primero Maven test para compilar. No pasar credenciales por argumentos ni copiar la configuración privada a Git.

El backend de prueba permanece disponible como máximo una hora después de `LIVE_SERVER_READY`; se cierra limpiamente al crear `stop.txt` en el directorio privado de esa ejecución. La clave JWT es efímera. Para la prueba Flutter optativa, definir `STUDENT_LIVE_DIR` con ese directorio privado. Sin esa variable, la prueba se omite. Esta prueba Flutter solo lee y hace login, no crea nuevas entregas.

Para abrir la interfaz manual mientras el backend temporal esté disponible:

```powershell
flutter run -d chrome --web-port 5174 --dart-define=API_BASE_URL=http://localhost:8081
```

Introducir personalmente las credenciales ficticias del archivo privado. No compartirlas en capturas o informes. El servidor de prueba no se publica ni se convierte en configuración de producción. Un reinicio requiere una nueva sesión local configurada explícitamente; no volver a ejecutar la siembra para reiniciar la aplicación.
