package pe.edu.micaelabastidas.backend.student;

import java.security.SecureRandom;
import java.util.Base64;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.WebApplicationContext;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {"spring.config.import=", "spring.datasource.url=jdbc:h2:mem:student-security",
        "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
        "spring.datasource.password=", "spring.jpa.hibernate.ddl-auto=none", "spring.sql.init.mode=never",
        "app.dev.seed-enabled=false", "logging.level.root=WARN"})
@Import(StudentSecurityTests.Probes.class)
class StudentSecurityTests {
    @DynamicPropertySource
    static void key(DynamicPropertyRegistry registry) {
        byte[] bytes = new byte[32]; new SecureRandom().nextBytes(bytes);
        registry.add("JWT_SECRET_BASE64", () -> Base64.getEncoder().encodeToString(bytes));
    }
    @Autowired JdbcTemplate jdbc;
    @Autowired WebApplicationContext context;
    MockMvc mvc;

    @BeforeEach void setup() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        jdbc.execute("CREATE TABLE IF NOT EXISTS usuario (id BIGINT PRIMARY KEY, activo BOOLEAN)");
        jdbc.execute("CREATE TABLE IF NOT EXISTS rol (id BIGINT PRIMARY KEY, nombre VARCHAR(30))");
        jdbc.execute("CREATE TABLE IF NOT EXISTS usuario_rol (usuario_id BIGINT, rol_id BIGINT)");
        jdbc.update("DELETE FROM usuario_rol"); jdbc.update("DELETE FROM rol"); jdbc.update("DELETE FROM usuario");
        jdbc.update("INSERT INTO usuario VALUES (1, TRUE), (2, FALSE), (3, TRUE)");
        jdbc.update("INSERT INTO rol VALUES (1, 'ESTUDIANTE'), (2, 'DOCENTE')");
        jdbc.update("INSERT INTO usuario_rol VALUES (1, 1), (2, 1), (3, 2)");
    }

    @Test void requiresTokenAndStudentRole() throws Exception {
        mvc.perform(get("/api/estudiante/probe")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/estudiante/probe").with(jwt().jwt(j -> j.subject("1"))
                .authorities(new SimpleGrantedAuthority("ROLE_DOCENTE")))).andExpect(status().isForbidden());
        mvc.perform(get("/api/estudiante/probe").with(jwt().jwt(j -> j.subject("1"))
                .authorities(new SimpleGrantedAuthority("ROLE_ESTUDIANTE")))).andExpect(status().isOk());
    }

    @Test void rechecksActiveAccountAndCurrentDatabaseRole() throws Exception {
        for (String id : new String[] {"2", "3", "999", "not-a-number", "-1"}) {
            mvc.perform(get("/api/estudiante/probe").with(jwt().jwt(j -> j.subject(id))
                    .authorities(new SimpleGrantedAuthority("ROLE_ESTUDIANTE")))).andExpect(status().isForbidden());
        }
        jdbc.update("UPDATE usuario SET activo = FALSE WHERE id = 1");
        mvc.perform(get("/api/estudiante/probe").with(jwt().jwt(j -> j.subject("1"))
                .authorities(new SimpleGrantedAuthority("ROLE_ESTUDIANTE")))).andExpect(status().isForbidden());
    }

    @TestConfiguration static class Probes {
        @Bean Probe probe() { return new Probe(); }
    }
    @RestController static class Probe {
        @GetMapping("/api/estudiante/probe") String probe() { return "ok"; }
    }
}
