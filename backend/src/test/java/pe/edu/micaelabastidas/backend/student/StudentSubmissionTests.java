package pe.edu.micaelabastidas.backend.student;

import java.nio.file.Files;
import java.nio.file.Path;
import java.security.SecureRandom;
import java.util.Base64;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import tools.jackson.databind.ObjectMapper;
import pe.edu.micaelabastidas.backend.auth.LoginRequest;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {"spring.config.import=", "spring.datasource.url=jdbc:h2:mem:student-submissions;MODE=MySQL;DB_CLOSE_DELAY=-1",
        "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
        "spring.datasource.password=", "spring.jpa.hibernate.ddl-auto=none", "spring.sql.init.mode=never",
        "app.dev.seed-enabled=false", "debug=false", "logging.level.root=WARN"})
class StudentSubmissionTests {
    @org.junit.jupiter.api.io.TempDir static Path storage;
    @DynamicPropertySource static void key(DynamicPropertyRegistry registry) {
        byte[] bytes = new byte[32]; new SecureRandom().nextBytes(bytes);
        registry.add("JWT_SECRET_BASE64", () -> Base64.getEncoder().encodeToString(bytes));
        registry.add("app.submissions.storage", () -> storage.toString());
    }
    @Autowired JdbcTemplate jdbc;
    @Autowired WebApplicationContext context;
    @Autowired PasswordEncoder passwords;
    @Autowired ObjectMapper mapper;
    MockMvc mvc;
    RequestPostProcessor student(String id) {
        return jwt().jwt(j -> j.subject(id)).authorities(new SimpleGrantedAuthority("ROLE_ESTUDIANTE"));
    }
    String list(long enrollment) { return "/api/estudiante/matriculas/" + enrollment + "/tareas"; }

    @BeforeEach void setup() throws Exception {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        try (var connection = jdbc.getDataSource().getConnection()) {
            assertEquals("H2", connection.getMetaData().getDatabaseProductName());
        }
        jdbc.execute("DROP ALL OBJECTS"); // This context uses only the H2 database above.
        String sql = Files.readString(Path.of("..", "database", "01_estructura.sql"))
                .replaceAll("(?m)^\\s*--.*$", "");
        for (String part : sql.split(";")) {
            String statement = part.trim();
            if (statement.startsWith("CREATE TABLE") || statement.startsWith("INSERT INTO rol")) jdbc.execute(statement);
        }
        jdbc.update("""
                INSERT INTO usuario (id,nombre_usuario,password_hash,nombres,apellidos) VALUES
                (1,'fixture1','NOT_A_PASSWORD_HASH','Estudiante','Uno'),
                (2,'fixture2','NOT_A_PASSWORD_HASH','Estudiante','Dos'),
                (3,'fixture3','NOT_A_PASSWORD_HASH','Sin','Perfil'),
                (4,'fixture4','NOT_A_PASSWORD_HASH','Docente','Prueba')
                """);
        jdbc.update("INSERT INTO usuario_rol SELECT u.id,r.id FROM usuario u CROSS JOIN rol r WHERE r.nombre='ESTUDIANTE' AND u.id<4");
        jdbc.update("INSERT INTO estudiante (id,usuario_id,codigo_estudiante) VALUES (11,1,'E1'),(22,2,'E2')");
        jdbc.update("INSERT INTO docente (id,usuario_id) VALUES (41,4)");
        jdbc.update("INSERT INTO periodo_academico VALUES (1,'2025','2025-03-01','2025-12-31',FALSE),(2,'2026','2026-03-01','2026-12-31',TRUE),(3,'2027','2027-03-01','2027-12-31',TRUE)");
        jdbc.update("INSERT INTO grado VALUES (1,'SECUNDARIA','Primero')");
        jdbc.update("INSERT INTO seccion VALUES (1,1,'A'),(2,1,'B')");
        jdbc.update("INSERT INTO matricula VALUES (101,11,1,1,'2025-03-01','FINALIZADA'),(102,11,2,1,'2026-03-01','ACTIVA'),(103,11,3,1,'2027-03-01','ACTIVA'),(202,22,2,2,'2026-03-01','ACTIVA')");
        jdbc.update("INSERT INTO curso VALUES (1,'Matemática','Descripción de prueba',TRUE),(2,'Arte',NULL,FALSE),(3,'Curso ajeno',NULL,TRUE)");
        jdbc.update("INSERT INTO asignacion_docente VALUES (501,41,1,2,1),(502,41,2,2,1),(503,41,1,1,1),(504,41,3,2,2)");
        jdbc.update("INSERT INTO usuario (id,nombre_usuario,password_hash,nombres,apellidos) VALUES (5,'fixture5','NOT_A_PASSWORD_HASH','Compañero','Prueba')");
        jdbc.update("INSERT INTO usuario_rol SELECT 5,id FROM rol WHERE nombre='ESTUDIANTE'");
        jdbc.update("INSERT INTO estudiante (id,usuario_id,codigo_estudiante) VALUES (55,5,'E5')");
        jdbc.update("INSERT INTO matricula VALUES (502,55,2,1,'2026-03-01','ACTIVA')");
        jdbc.update("""
                INSERT INTO tarea (id,asignacion_docente_id,titulo,descripcion,archivo_url,fecha_publicacion,fecha_limite,puntaje_maximo,activo) VALUES
                (701,501,'Álgebra','Resolver ejercicios','https://example.invalid/tarea.pdf','2026-04-01 08:00:00','2026-04-10 18:00:00',20,TRUE),
                (702,502,'Dibujo',NULL,NULL,'2026-04-01 08:00:00','2026-04-09 18:00:00',10,TRUE),
                (703,503,'Histórica',NULL,NULL,'2025-04-01 08:00:00','2025-04-10 18:00:00',20,TRUE),
                (704,504,'Otra sección',NULL,NULL,'2026-04-01 08:00:00','2026-04-10 18:00:00',20,TRUE),
                (705,501,'Inactiva',NULL,NULL,'2026-04-01 08:00:00','2026-04-10 18:00:00',20,FALSE),
                (706,501,'Sin entregar',NULL,NULL,'2026-04-01 08:00:00','2026-04-11 18:00:00',20,TRUE)
                """);
        jdbc.update("""
                INSERT INTO entrega_tarea (id,tarea_id,matricula_id,comentario,archivo_url,fecha_entrega,puntaje,retroalimentacion,fecha_revision) VALUES
                (801,701,102,'Mi comentario','https://example.invalid/propia.pdf','2026-04-05 10:00:00',18,'Buen trabajo','2026-04-06 10:00:00'),
                (802,701,502,'Comentario ajeno','https://example.invalid/ajena.pdf','2026-04-07 10:00:00',9,'Revisión ajena','2026-04-08 10:00:00'),
                (803,702,102,NULL,NULL,'2026-04-05 10:00:00',NULL,NULL,NULL)
                """);
        jdbc.update("UPDATE tarea SET fecha_publicacion=DATEADD('DAY',-1,CURRENT_TIMESTAMP),fecha_limite=DATEADD('DAY',1,CURRENT_TIMESTAMP)");
    }

    String endpoint(long enrollment,long task) { return list(enrollment)+"/"+task+"/entrega"; }
    org.springframework.mock.web.MockMultipartFile textFile(String name,String type,byte[] bytes) {
        return new org.springframework.mock.web.MockMultipartFile("archivo",name,type,bytes);
    }
    long storedFiles() throws Exception { try(var stream=Files.list(storage)) {return stream.count();} }

    @Test void createsTextSubmissionAndOnlyOneRowWithoutGradingFields() throws Exception {
        mvc.perform(multipart(endpoint(102,706)).param("comentario"," Mi respuesta ")
                .param("puntaje","20").param("archivo_url","../../.env").with(student("1")))
                .andExpect(status().isCreated()).andExpect(header().string("Cache-Control","no-store"))
                .andExpect(jsonPath("$.comentario").value("Mi respuesta"))
                .andExpect(jsonPath("$.estadoEntrega").value("ENTREGADA"))
                .andExpect(jsonPath("$.puntaje").isEmpty()).andExpect(jsonPath("$.archivoUrl").isEmpty());
        mvc.perform(get(endpoint(102,706)).with(student("1"))).andExpect(status().isOk())
                .andExpect(jsonPath("$.comentario").value("Mi respuesta"));
        mvc.perform(get(list(102)+"/706").with(student("1"))).andExpect(jsonPath("$.estadoEntrega").value("ENTREGADA"));
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM entrega_tarea WHERE tarea_id=706 AND matricula_id=102",Integer.class));
    }

    @Test void uploadsSinglePrivateFileAndDownloadsOnlyThroughOwnerEndpoint() throws Exception {
        byte[] content="Respuesta UTF-8".getBytes(java.nio.charset.StandardCharsets.UTF_8);
        mvc.perform(multipart(endpoint(102,706)).file(textFile("respuesta.txt","text/plain",content)).with(student("1")))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.archivoUrl").value(endpoint(102,706)+"/archivo"));
        mvc.perform(get(endpoint(102,706)+"/archivo").with(student("1"))).andExpect(status().isOk())
                .andExpect(header().string("Content-Type","text/plain"))
                .andExpect(header().string("X-Content-Type-Options","nosniff"))
                .andExpect(header().string("Content-Disposition","attachment; filename=\"entrega.txt\""))
                .andExpect(content().bytes(content));
        mvc.perform(get(list(102)+"/706").with(student("1")))
                .andExpect(jsonPath("$.entrega.archivoUrl").value(endpoint(102,706)+"/archivo"));
        String reference=jdbc.queryForObject("SELECT archivo_url FROM entrega_tarea WHERE matricula_id=102 AND tarea_id=706",String.class);
        assertEquals(true,SubmissionFiles.managed(reference));
        mvc.perform(get("/storage/entregas/"+reference.substring("urn:entrega:".length())))
                .andExpect(status().isUnauthorized());
        for(String user:new String[]{"2","5"}) {
            mvc.perform(get(endpoint(102,706)).with(student(user))).andExpect(status().isNotFound());
            mvc.perform(get(endpoint(102,706)+"/archivo").with(student(user))).andExpect(status().isNotFound());
        }
        mvc.perform(get(endpoint(502,706)+"/archivo").with(student("5"))).andExpect(status().isNotFound());
    }

    @Test void rejectsLateFutureInactiveAndNonActiveEnrollmentAndCleansRollbackFile() throws Exception {
        long before=storedFiles();
        jdbc.update("UPDATE tarea SET fecha_limite=DATEADD('HOUR',-1,CURRENT_TIMESTAMP) WHERE id=706");
        mvc.perform(multipart(endpoint(102,706)).file(textFile("respuesta.txt","text/plain",new byte[]{65})).with(student("1")))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.codigo").value("FUERA_DE_PLAZO"));
        assertEquals(before,storedFiles());
        jdbc.update("UPDATE tarea SET fecha_limite=DATEADD('DAY',2,CURRENT_TIMESTAMP),fecha_publicacion=DATEADD('DAY',1,CURRENT_TIMESTAMP) WHERE id=706");
        mvc.perform(multipart(endpoint(102,706)).param("comentario","Respuesta").with(student("1")))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.codigo").value("FUERA_DE_PLAZO"));
        jdbc.update("UPDATE tarea SET activo=FALSE WHERE id=706");
        mvc.perform(multipart(endpoint(102,706)).param("comentario","Respuesta").with(student("1")))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.codigo").value("ENTREGA_CERRADA"));
        jdbc.update("UPDATE tarea SET activo=TRUE WHERE id=706");
        jdbc.update("UPDATE matricula SET estado='RETIRADA' WHERE id=102");
        mvc.perform(multipart(endpoint(102,706)).param("comentario","Respuesta").with(student("1"))).andExpect(status().isConflict());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM entrega_tarea WHERE tarea_id=706",Integer.class));
    }

    @Test void rejectsDuplicatesAndConcurrentRequestsWithoutOverwriting() throws Exception {
        mvc.perform(multipart(endpoint(102,701)).param("comentario","Reemplazo").with(student("1")))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.codigo").value("ENTREGA_DUPLICADA"));
        assertEquals("Mi comentario",jdbc.queryForObject("SELECT comentario FROM entrega_tarea WHERE id=801",String.class));
        try(var executor=java.util.concurrent.Executors.newFixedThreadPool(2)) {
            var start=new java.util.concurrent.CountDownLatch(1);
            java.util.concurrent.Callable<Integer> send=()->{start.await();return mvc.perform(multipart(endpoint(102,706))
                    .param("comentario","Concurrente").with(student("1"))).andReturn().getResponse().getStatus();};
            var first=executor.submit(send); var second=executor.submit(send); start.countDown();
            var statuses=java.util.List.of(first.get(),second.get()).stream().sorted().toList();
            assertEquals(java.util.List.of(201,409),statuses);
        }
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM entrega_tarea WHERE tarea_id=706 AND matricula_id=102",Integer.class));
    }

    @Test void validatesResponseFilesTypesSignaturesSizeAndPaths() throws Exception {
        mvc.perform(multipart(endpoint(102,706)).param("comentario"," ").with(student("1")))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("ENTREGA_VACIA"));
        mvc.perform(multipart(endpoint(102,706)).param("comentario","a".repeat(10001)).with(student("1")))
                .andExpect(status().isBadRequest());
        for(var file:java.util.List.of(textFile("../.env","text/plain",new byte[]{65}),
                textFile("bad.exe","application/octet-stream",new byte[]{65}),
                textFile("bad.pdf","application/pdf",new byte[]{65}),textFile("bad.png","image/png",new byte[]{65}),
                textFile("bad.txt","text/plain",new byte[]{0}),textFile("bad.txt","image/png",new byte[]{65}),
                textFile("empty.txt","text/plain",new byte[0]))) {
            mvc.perform(multipart(endpoint(102,706)).file(file).with(student("1")))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("ARCHIVO_INVALIDO"));
        }
        mvc.perform(multipart(endpoint(102,706)).file(textFile("huge.txt","text/plain",new byte[SubmissionFiles.MAX_BYTES+1])).with(student("1")))
                .andExpect(status().isPayloadTooLarge());
        mvc.perform(multipart(endpoint(102,706)).file(textFile("one.txt","text/plain",new byte[]{65}))
                .file(textFile("two.txt","text/plain",new byte[]{66})).with(student("1"))).andExpect(status().isBadRequest());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM entrega_tarea WHERE tarea_id=706",Integer.class));
    }

    @Test void rechecksAuthAndRejectsForeignTasksEnrollmentsAndLegacyFilePaths() throws Exception {
        String path=endpoint(102,706);
        mvc.perform(multipart(path).param("comentario","Respuesta")).andExpect(status().isUnauthorized());
        mvc.perform(multipart(path).param("comentario","Respuesta").header("Authorization","Bearer invalid"))
                .andExpect(status().isUnauthorized());
        for(String role:new String[]{"DOCENTE","APODERADO"}) {
            mvc.perform(multipart(path).param("comentario","Respuesta").with(jwt().jwt(j->j.subject("1"))
                    .authorities(new SimpleGrantedAuthority("ROLE_"+role)))).andExpect(status().isForbidden());
        }
        for(String foreign:new String[]{endpoint(202,704),endpoint(102,704),endpoint(102,703),endpoint(999,706)}) {
            mvc.perform(multipart(foreign).param("comentario","Respuesta").with(student("1"))).andExpect(status().isNotFound());
        }
        jdbc.update("UPDATE entrega_tarea SET archivo_url='../../config/application-local.properties' WHERE id=801");
        mvc.perform(get(endpoint(102,701)+"/archivo").with(student("1"))).andExpect(status().isNotFound());
        mvc.perform(get(endpoint(102,701)).with(student("1"))).andExpect(jsonPath("$.archivoUrl").isEmpty());
        jdbc.update("UPDATE usuario SET activo=FALSE WHERE id=1");
        mvc.perform(multipart(path).param("comentario","Respuesta").with(student("1"))).andExpect(status().isForbidden());
        jdbc.update("UPDATE usuario SET activo=TRUE WHERE id=1");
        jdbc.update("DELETE FROM usuario_rol WHERE usuario_id=1");
        mvc.perform(get(endpoint(102,701)).with(student("1"))).andExpect(status().isForbidden());
    }
}
