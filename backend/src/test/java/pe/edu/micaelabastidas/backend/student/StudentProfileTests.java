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
import tools.jackson.databind.ObjectMapper;
import pe.edu.micaelabastidas.backend.auth.LoginRequest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {"spring.config.import=", "spring.datasource.url=jdbc:h2:mem:student-profile;MODE=MySQL;DB_CLOSE_DELAY=-1",
        "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
        "spring.datasource.password=", "spring.jpa.hibernate.ddl-auto=none", "spring.sql.init.mode=never",
        "app.dev.seed-enabled=false", "debug=false", "logging.level.root=WARN"})
class StudentProfileTests {
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
    @BeforeEach void setup() throws Exception {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        jdbc.execute("DROP ALL OBJECTS"); // Only the isolated in-memory H2 database.
        String sql = Files.readString(Path.of("..", "database", "01_estructura.sql"))
                .replaceAll("(?m)^\\s*--.*$", "");
        for (String part : sql.split(";")) {
            String statement = part.trim();
            if (statement.startsWith("CREATE TABLE") || statement.startsWith("INSERT INTO rol")) jdbc.execute(statement);
        }
        // A deliberately unusable marker satisfies NOT NULL; no real credentials or hashes.
        jdbc.update("""
                INSERT INTO usuario (id, nombre_usuario, password_hash, nombres, apellidos, activo)
                VALUES (1, 'fixture1', 'NOT_A_PASSWORD_HASH', 'Primera', 'Persona', TRUE),
                       (2, 'fixture2', 'NOT_A_PASSWORD_HASH', 'Segunda', 'Persona', TRUE),
                       (3, 'fixture3', 'NOT_A_PASSWORD_HASH', 'Sin', 'Perfil', TRUE),
                       (4, 'fixture4', 'NOT_A_PASSWORD_HASH', 'Sin', 'Matricula', TRUE)
                """);
        jdbc.update("INSERT INTO usuario_rol SELECT u.id, r.id FROM usuario u CROSS JOIN rol r WHERE r.nombre = 'ESTUDIANTE'");
        jdbc.update("INSERT INTO estudiante (id, usuario_id, codigo_estudiante) VALUES (11,1,'E1'), (22,2,'E2'), (44,4,'E4')");
        jdbc.update("INSERT INTO periodo_academico VALUES (1,'2025','2025-03-01','2025-12-31',FALSE),(2,'2026','2026-03-01','2026-12-31',TRUE)");
        jdbc.update("INSERT INTO grado VALUES (1,'SECUNDARIA','Primero')");
        jdbc.update("INSERT INTO seccion VALUES (1,1,'A'),(2,1,'B')");
        jdbc.update("INSERT INTO matricula VALUES (101,11,1,1,'2025-03-01','FINALIZADA'),(102,11,2,1,'2026-03-01','ACTIVA'),(202,22,2,2,'2026-03-01','ACTIVA')");
    }

    @Test void protectsBothEndpoints() throws Exception {
        for (String path : new String[] {"perfil", "matriculas"}) {
            mvc.perform(get("/api/estudiante/" + path)).andExpect(status().isUnauthorized());
            mvc.perform(get("/api/estudiante/" + path).header("Authorization", "Bearer invalid"))
                    .andExpect(status().isUnauthorized());
            mvc.perform(get("/api/estudiante/" + path).with(jwt().jwt(j -> j.subject("1"))
                    .authorities(new SimpleGrantedAuthority("ROLE_DOCENTE")))).andExpect(status().isForbidden());
        }
    }

    @Test void loginTokenWorksThroughTheRealJwtFilter() throws Exception {
        String password = java.util.UUID.randomUUID().toString();
        jdbc.update("UPDATE usuario SET password_hash = ? WHERE id = 1", passwords.encode(password));
        String response = mvc.perform(post("/api/auth/login").contentType("application/json")
                        .content(mapper.writeValueAsString(new LoginRequest("fixture1", password))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String token = mapper.readTree(response).path("accessToken").asText();
        mvc.perform(get("/api/estudiante/perfil").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andExpect(jsonPath("$.usuarioId").value(1));
        mvc.perform(get("/api/estudiante/matriculas").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(2));
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andExpect(content().json("{\"id\":1,\"roles\":[\"ESTUDIANTE\"]}"));
    }

    @Test void onlyReturnsOwnProfileEvenIfAnotherIdIsSupplied() throws Exception {
        mvc.perform(get("/api/estudiante/perfil?usuarioId=2&estudianteId=22").with(student("1")))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.id").value(11)).andExpect(jsonPath("$.usuarioId").value(1))
                .andExpect(jsonPath("$.codigoEstudiante").value("E1"))
                .andExpect(jsonPath("$.fechaNacimiento").isEmpty())
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
        mvc.perform(get("/api/estudiante/perfil").with(student("2")))
                .andExpect(jsonPath("$.id").value(22)).andExpect(jsonPath("$.codigoEstudiante").value("E2"));
    }

    @Test void returnsAllOwnEnrollmentsInExplicitOrder() throws Exception {
        mvc.perform(get("/api/estudiante/matriculas?usuarioId=2").with(student("1")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].id").value(102)).andExpect(jsonPath("$[0].periodo.nombre").value("2026"))
                .andExpect(jsonPath("$[0].seccion.grado.nivel").value("SECUNDARIA"))
                .andExpect(jsonPath("$[1].id").value(101));
        mvc.perform(get("/api/estudiante/matriculas").with(student("2")))
                .andExpect(jsonPath("$.length()").value(1)).andExpect(jsonPath("$[0].id").value(202));
    }

    @Test void distinguishesMissingProfileFromNoEnrollments() throws Exception {
        for (String path : new String[] {"perfil", "matriculas"}) {
            mvc.perform(get("/api/estudiante/" + path).with(student("3")))
                    .andExpect(status().isNotFound()).andExpect(jsonPath("$.codigo").value("SIN_PERFIL"));
        }
        mvc.perform(get("/api/estudiante/perfil").with(student("4"))).andExpect(status().isOk());
        mvc.perform(get("/api/estudiante/matriculas").with(student("4")))
                .andExpect(status().isOk()).andExpect(content().json("[]"));
        assertEquals(4, jdbc.queryForObject("SELECT COUNT(*) FROM usuario", Integer.class));
        assertEquals(3, jdbc.queryForObject("SELECT COUNT(*) FROM matricula", Integer.class));
    }

    @Test void rejectsRoleRemovalAndAccountDeactivation() throws Exception {
        jdbc.update("DELETE FROM usuario_rol WHERE usuario_id = 1");
        mvc.perform(get("/api/estudiante/perfil").with(student("1"))).andExpect(status().isForbidden());
        jdbc.update("UPDATE usuario SET activo = FALSE WHERE id = 2");
        mvc.perform(get("/api/estudiante/matriculas").with(student("2"))).andExpect(status().isForbidden());
    }
}
