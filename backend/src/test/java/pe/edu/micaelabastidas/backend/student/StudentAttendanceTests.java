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

@SpringBootTest(properties = {"spring.config.import=", "spring.datasource.url=jdbc:h2:mem:student-attendance;MODE=MySQL;DB_CLOSE_DELAY=-1",
        "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
        "spring.datasource.password=", "spring.jpa.hibernate.ddl-auto=none", "spring.sql.init.mode=never",
        "app.dev.seed-enabled=false", "debug=false", "logging.level.root=WARN"})
class StudentAttendanceTests {
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
    String list(long enrollment) { return "/api/estudiante/matriculas/" + enrollment + "/asistencias"; }

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
                INSERT INTO asistencia (id,matricula_id,asignacion_docente_id,periodo_academico_id,seccion_id,fecha,estado,observacion,registrado_en) VALUES
                (1001,102,501,2,1,'2026-04-01','PRESENTE',NULL,'2026-04-01 10:00:00'),
                (1002,102,501,2,1,'2026-04-02','FALTA',NULL,'2026-04-02 10:00:00'),
                (1003,102,501,2,1,'2026-04-03','TARDANZA','Diez minutos','2026-04-03 10:00:00'),
                (1004,102,502,2,1,'2026-04-03','JUSTIFICADA','Motivo registrado','2026-04-03 10:00:00'),
                (1005,101,503,1,1,'2025-04-01','PRESENTE',NULL,'2025-04-01 10:00:00'),
                (1006,202,504,2,2,'2026-04-01','FALTA','Privada','2026-04-01 10:00:00'),
                (1007,502,501,2,1,'2026-04-01','FALTA','Compañero','2026-04-01 10:00:00')
                """);
    }

    String filtered(long enrollment,long assignment) {
        return "/api/estudiante/matriculas/"+enrollment+"/cursos/"+assignment+"/asistencias";
    }

    @Test void returnsOwnRecordsAllFourStatesAndExactSummary() throws Exception {
        mvc.perform(get(list(102)+"?usuarioId=2").with(student("1"))).andExpect(status().isOk())
                .andExpect(header().string("Cache-Control","no-store"))
                .andExpect(jsonPath("$.registros.length()").value(4)).andExpect(jsonPath("$.registros[0].id").value(1004))
                .andExpect(jsonPath("$.registros[0].estado").value("JUSTIFICADA"))
                .andExpect(jsonPath("$.resumen.total").value(4)).andExpect(jsonPath("$.resumen.presente").value(1))
                .andExpect(jsonPath("$.resumen.falta").value(1)).andExpect(jsonPath("$.resumen.tardanza").value(1))
                .andExpect(jsonPath("$.resumen.justificada").value(1))
                .andExpect(jsonPath("$.resumen.porcentaje").doesNotExist());
        mvc.perform(get(list(101)).with(student("1"))).andExpect(status().isOk())
                .andExpect(jsonPath("$.registros[0].periodo").value("2025"));
    }

    @Test void appliesInclusiveDateBoundsAndCourseToBothRecordsAndSummary() throws Exception {
        mvc.perform(get(filtered(102,501)).param("desde","2026-04-02").param("hasta","2026-04-03").with(student("1")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.registros.length()").value(2))
                .andExpect(jsonPath("$.resumen.total").value(2)).andExpect(jsonPath("$.resumen.falta").value(1))
                .andExpect(jsonPath("$.resumen.tardanza").value(1)).andExpect(jsonPath("$.resumen.justificada").value(0));
        mvc.perform(get(list(102)).param("desde","2026-04-03").param("hasta","2026-04-03").with(student("1")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.registros.length()").value(2));
        mvc.perform(get(list(102)).param("hasta","2026-04-01").with(student("1")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.resumen.total").value(1));
        mvc.perform(get(list(102)).param("desde","2024-02-29").with(student("1"))).andExpect(status().isOk());
        mvc.perform(get(filtered(102,502)).with(student("1"))).andExpect(status().isOk())
                .andExpect(jsonPath("$.registros.length()").value(1)).andExpect(jsonPath("$.resumen.justificada").value(1));
    }

    @Test void rejectsInvalidDatesAndInvertedRangesWithoutEchoingInput() throws Exception {
        for(String value:new String[]{"2026-02-29","2026-04-31","2026-13-01","26-01-01","2026-1-01","","0999-01-01","2026-04-01T00:00:00","bad-input"}) {
            mvc.perform(get(list(102)).param("desde",value).with(student("1")))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("FILTROS_INVALIDOS"));
            mvc.perform(get(filtered(102,501)).param("hasta",value).with(student("1"))).andExpect(status().isBadRequest());
        }
        mvc.perform(get(list(102)).param("desde","2026-04-03").param("hasta","2026-04-02").with(student("1")))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("FILTROS_INVALIDOS"));
    }

    @Test void detailAndFiltersCannotExposeClassmatesOtherSectionsOrOtherPeriods() throws Exception {
        mvc.perform(get(list(102)+"/1003").with(student("1"))).andExpect(status().isOk())
                .andExpect(header().string("Cache-Control","no-store"))
                .andExpect(jsonPath("$.fecha").value("2026-04-03"))
                .andExpect(jsonPath("$.curso").value("Matemática")).andExpect(jsonPath("$.docente").value("Docente Prueba"))
                .andExpect(jsonPath("$.observacion").value("Diez minutos"))
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
        for(String path:new String[]{list(202),list(502),list(999),list(102)+"/1006",list(102)+"/1007",
                list(102)+"/1005",list(102)+"/999",filtered(102,504),filtered(102,503),filtered(102,999)}) {
            mvc.perform(get(path).with(student("1"))).andExpect(status().isNotFound())
                    .andExpect(jsonPath("$.codigo").value("NO_DISPONIBLE"));
        }
        mvc.perform(get(list(502)+"/1007").with(student("5"))).andExpect(status().isOk())
                .andExpect(jsonPath("$.observacion").value("Compañero"));
        mvc.perform(get(list(502)+"/1001").with(student("5"))).andExpect(status().isNotFound());
    }

    @Test void noDataMeansEmptyRecordsAndZeroCountsNotInventedAbsences() throws Exception {
        for(String path:new String[]{list(103),list(102)+"?desde=2026-04-10&hasta=2026-04-30"}) {
            mvc.perform(get(path).with(student("1"))).andExpect(status().isOk())
                    .andExpect(content().json("{\"registros\":[],\"resumen\":{\"total\":0,\"presente\":0,\"falta\":0,\"tardanza\":0,\"justificada\":0}}"));
        }
        mvc.perform(get(list(102)).with(student("3"))).andExpect(status().isNotFound())
                .andExpect(jsonPath("$.codigo").value("SIN_PERFIL"));
        assertEquals(7,jdbc.queryForObject("SELECT COUNT(*) FROM asistencia",Integer.class));
    }

    @Test void protectsEveryRouteAndRechecksRoleAndActiveAccount() throws Exception {
        for(String path:new String[]{list(102),filtered(102,501),list(102)+"/1001"}) {
            mvc.perform(get(path)).andExpect(status().isUnauthorized());
            mvc.perform(get(path).header("Authorization","Bearer invalid")).andExpect(status().isUnauthorized());
            for(String role:new String[]{"DOCENTE","APODERADO"}) {
                mvc.perform(get(path).with(jwt().jwt(j->j.subject("1"))
                        .authorities(new SimpleGrantedAuthority("ROLE_"+role)))).andExpect(status().isForbidden());
            }
            jdbc.update("UPDATE usuario SET activo=FALSE WHERE id=1");
            mvc.perform(get(path).with(student("1"))).andExpect(status().isForbidden());
            jdbc.update("UPDATE usuario SET activo=TRUE WHERE id=1");
        }
        jdbc.update("DELETE FROM usuario_rol WHERE usuario_id=1");
        mvc.perform(get(list(102)+"/1001").with(student("1"))).andExpect(status().isForbidden());
    }

    @Test void realLoginJwtWorksAndNoWritesAreAvailable() throws Exception {
        String password=java.util.UUID.randomUUID().toString();
        jdbc.update("UPDATE usuario SET password_hash=? WHERE id=1",passwords.encode(password));
        String login=mvc.perform(post("/api/auth/login").contentType("application/json")
                .content(mapper.writeValueAsString(new LoginRequest("fixture1",password))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String token=mapper.readTree(login).path("accessToken").asText();
        mvc.perform(get(list(102)).header("Authorization","Bearer "+token)).andExpect(status().isOk());
        mvc.perform(get(list(102)+"/1001").header("Authorization","Bearer "+token)).andExpect(status().isOk());
        mvc.perform(get(list(502)+"/1007").header("Authorization","Bearer "+token)).andExpect(status().isNotFound());
        mvc.perform(post(list(102)).with(student("1"))).andExpect(status().isMethodNotAllowed());
        mvc.perform(put(list(102)+"/1001").with(student("1"))).andExpect(status().isMethodNotAllowed());
    }
}
