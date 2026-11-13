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

@SpringBootTest(properties = {"spring.config.import=", "spring.datasource.url=jdbc:h2:mem:student-tasks;MODE=MySQL;DB_CLOSE_DELAY=-1",
        "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
        "spring.datasource.password=", "spring.jpa.hibernate.ddl-auto=none", "spring.sql.init.mode=never",
        "app.dev.seed-enabled=false", "debug=false", "logging.level.root=WARN"})
class StudentTaskTests {
    @DynamicPropertySource static void key(DynamicPropertyRegistry registry) {
        byte[] bytes = new byte[32]; new SecureRandom().nextBytes(bytes);
        registry.add("JWT_SECRET_BASE64", () -> Base64.getEncoder().encodeToString(bytes));
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
    }

    String filtered(long enrollment, long course) {
        return "/api/estudiante/matriculas/"+enrollment+"/cursos/"+course+"/tareas";
    }

    @Test void listsActiveTasksInDeadlineOrderAndFiltersByAssignment() throws Exception {
        mvc.perform(get(list(102)+"?usuarioId=2").with(student("1")))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control","no-store"))
                .andExpect(jsonPath("$.length()").value(3))
                .andExpect(jsonPath("$[0].titulo").value("Dibujo"))
                .andExpect(jsonPath("$[0].estadoEntrega").value("ENTREGADA"))
                .andExpect(jsonPath("$[1].curso").value("Matemática"))
                .andExpect(jsonPath("$[1].docente").value("Docente Prueba"))
                .andExpect(jsonPath("$[1].fechaPublicacion").value("2026-04-01T08:00:00"))
                .andExpect(jsonPath("$[1].fechaLimite").value("2026-04-10T18:00:00"))
                .andExpect(jsonPath("$[1].estadoEntrega").value("REVISADA"))
                .andExpect(jsonPath("$[2].estadoEntrega").value("PENDIENTE"))
                .andExpect(jsonPath("$[2].entrega").isEmpty());
        mvc.perform(get(filtered(102,501)).with(student("1"))).andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2)).andExpect(jsonPath("$[0].id").value(701));
        mvc.perform(get(list(101)).with(student("1"))).andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].titulo").value("Histórica"));
    }

    @Test void onlyReturnsOwnSubmissionEvenWhenClassmatesShareTask() throws Exception {
        mvc.perform(get(list(102)+"/701?matriculaId=502&entregaId=802").with(student("1")))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control","no-store"))
                .andExpect(jsonPath("$.descripcion").value("Resolver ejercicios"))
                .andExpect(jsonPath("$.puntajeMaximo").value(20))
                .andExpect(jsonPath("$.entrega.id").value(801))
                .andExpect(jsonPath("$.entrega.puntaje").value(18))
                .andExpect(jsonPath("$.entrega.comentario").value("Mi comentario"))
                .andExpect(jsonPath("$.entrega.archivoUrl").value("https://example.invalid/propia.pdf"))
                .andExpect(jsonPath("$.entrega.retroalimentacion").value("Buen trabajo"))
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
        mvc.perform(get(list(502)+"/701").with(student("5"))).andExpect(status().isOk())
                .andExpect(jsonPath("$.entrega.id").value(802)).andExpect(jsonPath("$.entrega.puntaje").value(9));
        mvc.perform(get(list(502)+"/702").with(student("5"))).andExpect(status().isOk())
                .andExpect(jsonPath("$.estadoEntrega").value("PENDIENTE")).andExpect(jsonPath("$.entrega").isEmpty());
    }

    @Test void rejectsForeignEnrollmentPeriodSectionAndInactiveTasks() throws Exception {
        for (String path : new String[] {list(202), list(502), list(502)+"/701", list(102)+"/703",
                list(102)+"/704",list(102)+"/705",list(102)+"/999",list(999),filtered(102,504),filtered(102,503),filtered(102,999)}) {
            mvc.perform(get(path).with(student("1"))).andExpect(status().isNotFound())
                    .andExpect(jsonPath("$.codigo").value("NO_DISPONIBLE"));
        }
        mvc.perform(get(list(102)+"/701").with(student("2"))).andExpect(status().isNotFound());
    }

    @Test void handlesEmptyTasksAndMissingProfileWithoutWriting() throws Exception {
        mvc.perform(get(list(103)).with(student("1"))).andExpect(status().isOk()).andExpect(content().json("[]"));
        jdbc.update("DELETE FROM tarea WHERE id=704"); // Fixture change only in H2.
        mvc.perform(get(filtered(202,504)).with(student("2"))).andExpect(status().isOk()).andExpect(content().json("[]"));
        mvc.perform(get(list(102)).with(student("3"))).andExpect(status().isNotFound())
                .andExpect(jsonPath("$.codigo").value("SIN_PERFIL"));
        assertEquals(5,jdbc.queryForObject("SELECT COUNT(*) FROM tarea",Integer.class));
        assertEquals(3,jdbc.queryForObject("SELECT COUNT(*) FROM entrega_tarea",Integer.class));
    }

    @Test void protectsAllRoutesWithJwtCurrentRoleAndActiveAccount() throws Exception {
        for (String path : new String[] {list(102),filtered(102,501),list(102)+"/701"}) {
            mvc.perform(get(path)).andExpect(status().isUnauthorized());
            mvc.perform(get(path).header("Authorization","Bearer invalid")).andExpect(status().isUnauthorized());
            for (String role : new String[] {"DOCENTE","APODERADO"}) {
                mvc.perform(get(path).with(jwt().jwt(j -> j.subject("1"))
                        .authorities(new SimpleGrantedAuthority("ROLE_"+role)))).andExpect(status().isForbidden());
            }
            jdbc.update("UPDATE usuario SET activo=FALSE WHERE id=1");
            mvc.perform(get(path).with(student("1"))).andExpect(status().isForbidden());
            jdbc.update("UPDATE usuario SET activo=TRUE WHERE id=1");
        }
        jdbc.update("DELETE FROM usuario_rol WHERE usuario_id=1");
        mvc.perform(get(list(102)+"/701").with(student("1"))).andExpect(status().isForbidden());
    }

    @Test void supportsRealLoginJwtAndRejectsWrites() throws Exception {
        String password = java.util.UUID.randomUUID().toString();
        jdbc.update("UPDATE usuario SET password_hash=? WHERE id=1",passwords.encode(password));
        String login = mvc.perform(post("/api/auth/login").contentType("application/json")
                .content(mapper.writeValueAsString(new LoginRequest("fixture1",password))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String token = mapper.readTree(login).path("accessToken").asText();
        mvc.perform(get(list(102)).header("Authorization","Bearer "+token)).andExpect(status().isOk());
        mvc.perform(get(list(102)+"/701").header("Authorization","Bearer "+token)).andExpect(status().isOk());
        mvc.perform(get(list(502)+"/701").header("Authorization","Bearer "+token)).andExpect(status().isNotFound());
        mvc.perform(post(list(102)+"/701").with(student("1"))).andExpect(status().isMethodNotAllowed());
    }
}
