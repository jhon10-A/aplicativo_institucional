package pe.edu.micaelabastidas.backend.student;

import java.nio.file.Files;
import java.nio.file.Path;
import java.security.SecureRandom;
import java.util.Base64;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {
        "spring.config.import=",
        "spring.datasource.url=jdbc:h2:mem:student-schedule;MODE=MySQL;DB_CLOSE_DELAY=-1",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.jpa.hibernate.ddl-auto=none",
        "spring.sql.init.mode=never",
        "app.dev.seed-enabled=false",
        "debug=false",
        "logging.level.root=WARN"})
class StudentScheduleTests {
    @DynamicPropertySource
    static void key(DynamicPropertyRegistry registry) {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        registry.add("JWT_SECRET_BASE64", () -> Base64.getEncoder().encodeToString(bytes));
    }

    @Autowired JdbcTemplate jdbc;
    @Autowired WebApplicationContext context;
    MockMvc mvc;

    private RequestPostProcessor student(String id) {
        return jwt().jwt(jwt -> jwt.subject(id))
                .authorities(new SimpleGrantedAuthority("ROLE_ESTUDIANTE"));
    }

    private String schedule(long enrollment) {
        return "/api/estudiante/matriculas/" + enrollment + "/horario";
    }

    @BeforeEach
    void setup() throws Exception {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        try (var connection = jdbc.getDataSource().getConnection()) {
            org.junit.jupiter.api.Assertions.assertEquals(
                    "H2", connection.getMetaData().getDatabaseProductName());
        }
        jdbc.execute("DROP ALL OBJECTS");
        executeSchema(Path.of("..", "database", "01_estructura.sql"), true);
        executeSchema(Path.of("..", "database", "02_horario_clase.sql"), false);

        jdbc.update("""
                INSERT INTO usuario (id,nombre_usuario,password_hash,nombres,apellidos) VALUES
                (1,'student1','NOT_A_PASSWORD_HASH','Estudiante','Uno'),
                (2,'student2','NOT_A_PASSWORD_HASH','Estudiante','Dos'),
                (3,'no-profile','NOT_A_PASSWORD_HASH','Sin','Perfil'),
                (4,'teacher','NOT_A_PASSWORD_HASH','Docente','Prueba')
                """);
        jdbc.update("""
                INSERT INTO usuario_rol
                SELECT u.id,r.id FROM usuario u CROSS JOIN rol r
                WHERE r.nombre='ESTUDIANTE' AND u.id IN (1,2,3)
                """);
        jdbc.update("INSERT INTO estudiante (id,usuario_id,codigo_estudiante) VALUES (11,1,'E1'),(22,2,'E2')");
        jdbc.update("INSERT INTO docente (id,usuario_id) VALUES (41,4)");
        jdbc.update("""
                INSERT INTO periodo_academico
                VALUES (1,'2026','2026-03-01','2026-12-31',TRUE),
                       (2,'2027','2027-03-01','2027-12-31',TRUE)
                """);
        jdbc.update("INSERT INTO grado VALUES (1,'SECUNDARIA','Primero')");
        jdbc.update("INSERT INTO seccion VALUES (1,1,'A'),(2,1,'B')");
        jdbc.update("""
                INSERT INTO matricula
                VALUES (101,11,1,1,'2026-03-01','ACTIVA'),
                       (102,22,1,2,'2026-03-01','ACTIVA'),
                       (103,11,2,1,'2027-03-01','ACTIVA')
                """);
        jdbc.update("""
                INSERT INTO curso VALUES
                (1,'Matemática','Curso de Matemática',TRUE),
                (2,'Arte','Curso de Arte',TRUE),
                (3,'Ciencia','Curso de Ciencia',TRUE)
                """);
        jdbc.update("""
                INSERT INTO asignacion_docente VALUES
                (501,41,1,1,1),(502,41,2,1,1),(503,41,3,1,2)
                """);
        jdbc.update("""
                INSERT INTO horario_clase
                    (id,asignacion_docente_id,dia_semana,hora_inicio,hora_fin,aula)
                VALUES
                    (601,501,1,'08:00:00','08:45:00','Aula 1'),
                    (602,502,1,'09:00:00','09:45:00',NULL),
                    (603,501,5,'10:00:00','10:45:00','Aula 1'),
                    (604,503,1,'08:00:00','08:45:00','Aula 2')
                """);
    }

    private void executeSchema(Path path, boolean includeRoles) throws Exception {
        String sql = Files.readString(path).replaceAll("(?m)^\\s*--.*$", "");
        for (String part : sql.split(";")) {
            String statement = part.trim();
            if (statement.startsWith("CREATE TABLE") ||
                    (includeRoles && statement.startsWith("INSERT INTO rol"))) {
                jdbc.execute(statement);
            }
        }
    }

    @Test
    void returnsOnlyEnrollmentScheduleOrderedByDayAndStartTime() throws Exception {
        mvc.perform(get(schedule(101)).with(student("1")))
                .andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.length()").value(3))
                .andExpect(jsonPath("$[0].diaSemana").value(1))
                .andExpect(jsonPath("$[0].horaInicio").value("08:00:00"))
                .andExpect(jsonPath("$[0].horaFin").value("08:45:00"))
                .andExpect(jsonPath("$[0].aula").value("Aula 1"))
                .andExpect(jsonPath("$[0].curso").value("Matemática"))
                .andExpect(jsonPath("$[0].docente").value("Docente Prueba"))
                .andExpect(jsonPath("$[0].seccion").value("A"))
                .andExpect(jsonPath("$[0].periodo").value("2026"))
                .andExpect(jsonPath("$[1].diaSemana").value(1))
                .andExpect(jsonPath("$[1].horaInicio").value("09:00:00"))
                .andExpect(jsonPath("$[1].aula").doesNotExist())
                .andExpect(jsonPath("$[2].diaSemana").value(5));
    }

    @Test
    void returnsEmptyListForAnOwnedEnrollmentWithoutScheduledClasses() throws Exception {
        mvc.perform(get(schedule(103)).with(student("1")))
                .andExpect(status().isOk())
                .andExpect(content().json("[]"));
    }

    @Test
    void cannotReadAnotherStudentsEnrollmentOrItsSchedule() throws Exception {
        mvc.perform(get(schedule(102)).with(student("1")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.codigo").value("NO_DISPONIBLE"));
        mvc.perform(get(schedule(101)).with(student("2")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.codigo").value("NO_DISPONIBLE"));
        mvc.perform(get(schedule(102)).with(student("2")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].curso").value("Ciencia"))
                .andExpect(jsonPath("$[0].aula").value("Aula 2"));
    }

    @Test
    void requiresAnAuthenticatedActiveStudentProfile() throws Exception {
        mvc.perform(get(schedule(101)))
                .andExpect(status().isUnauthorized());
        mvc.perform(get(schedule(101)).with(jwt().jwt(jwt -> jwt.subject("1"))
                .authorities(new SimpleGrantedAuthority("ROLE_DOCENTE"))))
                .andExpect(status().isForbidden());
        mvc.perform(get(schedule(101)).with(student("3")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.codigo").value("SIN_PERFIL"));
    }

    @Test
    void schemaRejectsInvalidWeekdaysTimesAndAssignments() {
        assertThrows(DataIntegrityViolationException.class, () -> jdbc.update("""
                INSERT INTO horario_clase
                    (asignacion_docente_id,dia_semana,hora_inicio,hora_fin)
                VALUES (501,6,'08:00:00','08:45:00')
                """));
        assertThrows(DataIntegrityViolationException.class, () -> jdbc.update("""
                INSERT INTO horario_clase
                    (asignacion_docente_id,dia_semana,hora_inicio,hora_fin)
                VALUES (501,1,'09:00:00','08:45:00')
                """));
        assertThrows(DataIntegrityViolationException.class, () -> jdbc.update("""
                INSERT INTO horario_clase
                    (asignacion_docente_id,dia_semana,hora_inicio,hora_fin)
                VALUES (999,1,'08:00:00','08:45:00')
                """));
    }
}
