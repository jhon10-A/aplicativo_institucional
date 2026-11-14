# Verificación integral del módulo Estudiante

Auditoría del 8 de noviembre de 2026, zona America/Lima. Rama inicial `feature/estudiante`, árbol limpio y sincronizado con su remoto. No se hizo push ni Pull Request.

## Resultado y alcance

El código actual inicia con Spring Boot y se conecta al MySQL real `db_institucional` en el puerto 3307. La compilación, las pruebas aisladas y las consultas de compatibilidad funcionan. **No se ha comprobado un recorrido autenticado completo con datos reales:** la base consultada no contiene perfiles de estudiante ni datos académicos, y el backend que ya estaba abierto en 8080 rechaza el origen web `http://localhost:5173` por CORS.

Se corrigió un error de seguridad de navegación: al expirar la sesión, una ruta privada abierta sobre el panel podía seguir mostrando su contenido. `MaterialApp` se identifica ahora por la identidad de la sesión para descartar todo el navegador al entrar/salir o vencer la sesión, sin usar el token como clave. Las pruebas reproducían el fallo antes de la corrección y ahora verifican el cierre del recibo de una entrega y de una respuesta sin enviar, también al intentar volver atrás.

## Evidencia sobre MySQL real: solo lectura

Se mantuvo intacto el proceso existente en 8080. El arranque del código actual se comprobó adicionalmente con una instancia temporal en loopback y puerto libre. Se forzaron `ddl-auto=validate`, `spring.sql.init.mode=never`, perfil de auditoría, `app.dev.seed-enabled=false` y conexiones Hikari de solo lectura. El inicializador de cuentas estuvo ausente. Las instancias temporales se cerraron al terminar.

| Comprobación | Resultado |
|---|---|
| Destino JDBC | `db_institucional`, puerto 3307, confirmado por el servidor |
| Inicio Spring Boot | Correcto, sin crear datos ni ejecutar scripts DDL |
| Conexión de auditoría | `readOnly=true` |
| Tablas reales y canónicas | 25 y 25 |
| Columnas canónicas contrastadas | 176: nombres y tipos, nulabilidad, longitudes VARCHAR y precisión/escala DECIMAL |
| Diferencia detectada | La base real añade `imagen_galeria.orden`, ausente del SQL compartido |
| Columnas usadas por Estudiante | Sin incompatibilidades detectadas |
| Claves compuestas | Confirmadas las de `calificacion` y `asistencia` hacia matrícula/asignación por periodo y sección |
| SQL de Cursos, Tareas, Calificaciones, Asistencia y Comunicados | Ejecutado en MySQL con condición sin filas para verificar tablas y columnas, sin leer registros personales |
| Consultas de Perfil y recibo de entrega | Ejecutadas con identificadores inexistentes; devuelven ausencia controlada |

Los conteos observados fueron: un usuario; cero perfiles de estudiante, matrículas, asignaciones docentes, tareas, entregas, calificaciones, asistencias y comunicados. No se inspeccionó ni publicó la identidad de ese usuario, su contraseña/hash ni su pertenencia a una cuenta de prueba.

La diferencia `imagen_galeria.orden` no afecta a las consultas Estudiante y no se corrigió alterando la base o el SQL. Antes de cualquier futura sincronización del esquema debe aclararse si esa columna forma parte del diseño deseado. No debe eliminarse ni copiarse a una migración automáticamente.

La auditoría real no insertó, actualizó ni eliminó datos. Las pruebas que crean tablas, usuarios, notas o entregas utilizaron únicamente H2 y almacenamiento temporal. No se crearon usuarios o entregas en MySQL ni se fabricaron JWT para suplantar al usuario existente.

## HTTP y conexión Flutter

- Backend existente: `GET /api/estado` devuelve 200; Perfil, Matrículas y Comunicados sin JWT devuelven 401.
- Instancia temporal con el código actual y MySQL real: `/api/estado` devuelve 200; las rutas de Perfil, Matrículas, Cursos, Tareas, recibo/archivo de entrega, Calificaciones, Asistencia y Comunicados sin JWT devuelven 401. Eso comprueba el rechazo sin credencial, no una respuesta autenticada positiva.
- Cliente Dart/`AuthApi` real: llega al servidor existente, obtiene 200 en estado y clasifica correctamente el 400 de un login vacío. No se usaron credenciales reales ni se comprobó un login exitoso.
- CORS del proceso existente: preflight para `http://localhost:5173` devuelve 403 y no autoriza el origen. Flutter Web no puede completar el login desde ese origen con ese proceso tal como está.
- CORS de la instancia temporal: el mismo preflight devuelve 200 con el origen correcto al configurar explícitamente `app.cors.allowed-origin`. El código admite esa configuración; no se habilitaron comodines ni otros orígenes.
- Flutter Web compiló con `--dart-define=API_BASE_URL=http://localhost:8080`. Esto comprueba la compilación y la URL elegida, no una sesión real en Chrome.

Para corregir la configuración del proceso existente, su operador debe reiniciarlo desde su terminal cuando corresponda, sin habilitar el inicializador. No se modificó `.env`, no se persistieron credenciales y no se detuvo ese proceso durante la auditoría. En la sesión de arranque, desde `backend/`, configurar explícitamente:

```powershell
# Usar la configuración privada existente; no copiar sus valores a comandos.
if (Test-Path -LiteralPath .env) { & .\scripts\Load-LocalEnv.ps1 }
$env:APP_DEV_SEED_ENABLED = 'false'
$env:APP_CORS_ALLOWED_ORIGIN = 'http://localhost:5173'
# Iniciar con el método habitual y Java 21, tras liberar 8080 en la terminal que lo ejecuta.
```

Las variables ya presentes tienen prioridad en el cargador `.env`; por eso el origen se asigna explícitamente después de cargarlo. El valor no es un secreto. Las rutas privadas y los secretos no deben imprimirse para depurar CORS.

| Plataforma | URL del backend | Observación |
|---|---|---|
| Web en este equipo | `http://localhost:8080` | Servir Flutter en `http://localhost:5173` y autorizar ese origen exacto |
| Emulador Android estándar | `http://10.0.2.2:8080` | El alias apunta al equipo anfitrión; `localhost` apuntaría al emulador |
| Android físico | `http://<IPv4-LAN-del-equipo>:8080` | Requiere red, interfaz accesible y firewall; sin fijar una IP personal en Git |
| Despliegue/release | URL HTTPS del servicio | HTTP está habilitado únicamente en Android debug |

Los manifiestos Android declaran INTERNET y la variante debug permite HTTP. No se probaron emuladores, dispositivos físicos ni selector/guardado de archivos nativos en esta auditoría.

## Pruebas automatizadas

| Ejecución | Resultado |
|---|---|
| Maven `--offline package`, Java 21 | 69 pruebas: 68 aprobadas, 1 omitida, 0 fallos/errores; JAR generado |
| `flutter analyze --no-pub` | Sin observaciones |
| `flutter test --no-pub` | 123 aprobadas, incluidas dos regresiones nuevas de expiración con rutas privadas |
| `flutter build web --no-pub --dart-define=API_BASE_URL=http://localhost:8080` | Correcto, incluido dry run Wasm |

La prueba Maven omitida corresponde al recorrido especial PowerShell → Spring de `.env`, que se activa mediante su script específico; no es un fallo ni una prueba de datos reales. Maven usó la instalación/caché local existente para evitar el problema conocido del wrapper en este entorno.

Las pruebas aisladas cubren login/JWT, cuenta activa y rol vigente; perfiles/matrículas; propiedad de cursos, tareas y entregas; notas y asistencias de compañeros; audiencia/vigencia de comunicados; filtros inválidos; archivos, plazo, duplicados y concurrencia; navegación, carga, vacíos, errores y reintentos. Los datos y las credenciales de esas pruebas son ficticios. **No equivalen a probar las funciones con registros reales.**

## Pendiente de comprobación manual

Se necesita una cuenta existente con rol ESTUDIANTE cuya contraseña introduzca personalmente su titular, y un perfil/matrículas/datos académicos autorizados. Actualmente no hay esos perfiles ni registros en la base consultada. Crear o completar esos datos requiere autorización separada y queda fuera de esta auditoría.

1. Corregir el origen CORS del proceso de desarrollo y abrir Flutter desde el origen exacto.
2. Introducir personalmente la cuenta, sin compartir contraseñas ni tokens, y comprobar login/cierre de sesión.
3. Recorrer Perfil y Matrículas; elegir explícitamente matrícula/periodo en Cursos, Tareas, Calificaciones y Asistencia; comprobar fechas, filtros y detalle con registros autorizados.
4. Revisar una entrega existente y descargar su adjunto con Bearer. Un envío real nuevo es una escritura y requiere autorización antes de probarlo.
5. Verificar generales y sección en Comunicados, recordando que no tienen FK de periodo ni destinatario individual.
6. Comprobar el selector/guardado de archivos en los dispositivos de despliegue y la desconexión/reintento en Chrome/Android.

No se probará aislamiento intentando acceder a datos personales reales ajenos: esa comprobación está cubierta con dos estudiantes y secciones en las pruebas aisladas.
# Actualización de CORS posterior a esta auditoría

El 403 descrito en el informe histórico se diagnosticó como un proceso anterior sin origen CORS explícito. Se añadió un lanzador local reproducible y pruebas de preflight, sin cambiar la política de Spring Security. La [preparación de integración](preparacion-integracion-estudiante.md) documenta el arranque y los datos propuestos para un entorno aislado. Los resultados históricos de este informe se conservan; no equivalen a una prueba manual con una cuenta Estudiante real.
